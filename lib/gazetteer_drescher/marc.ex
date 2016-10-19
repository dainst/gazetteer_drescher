defmodule GazetteerDrescher.MARC do

  alias GazetteerDrescher.MARC.Record
  alias GazetteerDrescher.MARC.Field
  alias GazetteerDrescher.Harvesting

  def create_output(place) do
    if Map.has_key?(place, "prefName") == false, do: ""

    record = %Record{}

    record = Record.add_field(record, %Field{
      tag: 24,
      i1: "7",
      subfields: [
        "a": place["gazId"],
        "2": "iDAI.gazetteer"
      ]})

    record = Record.add_field(record, %Field{
      tag: 40,
      subfields: [
        "a": "iDAI.gazetteer"
      ]})

    record = Record.add_field(record, %Field{
      tag: 151,
      subfields: [
        "a": place["prefName"]["title"]
      ]})

    record = record
    |> add_geo_tracing(place["names"], [place["prefName"]["title"]])
    |> add_parent_tracing(place["parent"])

    Record.to_marc(record)
  end

  defp add_geo_tracing(record, nil, _known_alternatives) do
    record
  end

  defp add_geo_tracing(record, [], _known_alternatives) do
    record
  end

  defp add_geo_tracing(record, [alternative_name | tail], known_alternatives) do
    cond do
      Enum.member?(known_alternatives, alternative_name["title"]) ->
        add_geo_tracing(record, tail, known_alternatives)
      true ->
        Record.add_field(record, %Field{
          tag: 451,
          subfields: [
            "a": alternative_name["title"]
          ]})
        |> add_geo_tracing(tail, known_alternatives ++ [alternative_name["title"]])
    end
  end

  def add_parent_tracing(record, nil) do
    record
  end

  def add_parent_tracing(record, parent_url) do
    # cached_places = Agent.get(CachedPlaces, &(&1))
    parent =
      case :ets.lookup(:cached_places, parent_url) do
        [{^parent_url, cached_place }] ->
          cached_place
        [] ->
          response = String.replace(parent_url, "place", "doc") <> ".json"
          |> Harvesting.fetch_place

          case response do
            {:ok, data} ->
              data
            _ ->
              nil
          end
      end

    case parent do
      nil ->
        record
      _ ->
        record = record
        |> Record.add_field(%Field{
          tag: 551,
          subfields: [
            "a": parent["prefName"]["title"],
            "i": "part of"
          ]})
        add_parent_tracing(record, parent["parent"])
    end
  end
end
