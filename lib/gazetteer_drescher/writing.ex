defmodule GazetteerDrescher.Writing do
  @moduledoc """
  This module handles all writing to the output file.
  """

  require Logger

  alias GazetteerDrescher.MARC

  @doc """
  Creates and opens the file at the specified location.

  Returns: `{:ok, io_device}`, see http://elixir-lang.org/docs/stable/elixir/File.html#open!/2
  """
  def open_output_file(file) do
    file
      |> Path.dirname
      |> File.mkdir_p!

    file
      |> File.open!([:write, :utf8])
  end

  def write_header() do
    { output_format, file_pid, _days_offset } = Agent.get(RequestInfo, &(&1))

    case output_format do
      :json ->
        IO.write(file_pid, "{'result':[")
    end
  end

  def write_footer() do
    { output_format, file_pid, _days_offset } = Agent.get(RequestInfo, &(&1))

    case output_format do
      :json ->
        IO.write(file_pid, "{']}")
    end
  end


  @doc """
  Chooses transformation module based on requested output format and hands over
  the given place data (JSON parsed as Map). Then writes the transformed data
  to file.

  Returns: `:ok`
  """
  def write_place(place) do
    { output_format, file_pid, _days_offset } = Agent.get(RequestInfo, &(&1))
    { processed_places } = Agent.get(ProcessingInfo, &(&1))

    case output_format do
      :json ->
        case processed_places do
          0 ->
            IO.write( file_pid, Poison.encode!(place))
          _ ->
            IO.write( file_pid, "," <> Poison.encode!(place))
        end
        Agent.update(ProcessingInfo, fn { state } -> {state + 1} end)

      :marc ->
        marc =
          place
          |> MARC.create_output

        IO.write( file_pid, marc )
      _ -> Logger.error "Unknown output format: #{output_format}"
    end
  end
end
