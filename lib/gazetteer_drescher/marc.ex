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
        a: place["gazId"],
        "2": "iDAI.gazetteer"
      ]})

    record = Record.add_field(record, %Field{
      tag: 40,
      subfields: [
        a: "iDAI.gazetteer"
      ]})

    record = Record.add_field(record, %Field{
      tag: 151,
      subfields: get_X51_subfield(place["prefName"])
    })

    record =
      record
      |> add_geo_tracing(place["names"])
      |> add_parent_tracing(place["parent"])

    Record.to_marc(record)
  end

  defp add_geo_tracing(record, nil) do
    record
  end

  defp add_geo_tracing(record, []) do
    record
  end

  defp add_geo_tracing(record, [alternative_name | tail]) do
    Record.add_field(record, %Field{
      tag: 451,
      subfields: get_X51_subfield(alternative_name)
    })
    |> add_geo_tracing(tail)
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
          subfields: get_X51_subfield(parent["prefName"]) ++ [ i: "part of" ]
          })
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

  defp get_X51_subfield(item) do
    if item["language"] == nil or item["language"] == "" do
      [ a: item["title"] ]
    else
      [ a: item["title"], l: item["language"] ]
    end
  end
end
