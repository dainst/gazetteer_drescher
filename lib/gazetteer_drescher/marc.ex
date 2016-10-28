defmodule GazetteerDrescher.MARC do
  @moduledoc """
  This module transforms the parsed JSON data of a place into the marc21 format.
  """
  require Logger

  alias GazetteerDrescher.MARC.Record
  alias GazetteerDrescher.MARC.Field
  alias GazetteerDrescher.Harvesting

  @doc """
  Transforms a parsed place's JSON data (as Map) into a marc21 record string.
  If the input Map is deemed invalid, an empty string is returned.

  Returns: Empty String or String with place's data in marc21.
  """
  def create_output(place) do
    if invalid?(place) do
      ""
    else
      process(place)
    end
  end

  defp process(place) do
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

    record =
      record
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

  defp add_parent_tracing(record, nil) do
    record
  end

  defp add_parent_tracing(record, parent_url) do
    # cached_places = Agent.get(CachedPlaces, &(&1))
    parent =
      case :ets.lookup(:cached_places, parent_url) do
        [{^parent_url, cached_place }] ->
          # Logger.debug ~s(Using cached place: #{cached_place["prefName"]["title"]})
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

  defp invalid?(place) do
    cond do
      Map.has_key?(place, "prefName") == false      -> true
      place["gazId"] == nil                         -> true
      String.trim(place["gazId"]) == ""             -> true
      place["prefName"]["title"] == nil             -> true
      String.trim(place["prefName"]["title"]) == "" -> true

      true                                          -> false
    end
  end
end
