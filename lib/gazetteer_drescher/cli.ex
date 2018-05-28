defmodule GazetteerDrescher.CLI do
  @moduledoc """
  This module implements the application's command line interface (CLI).
  """
  require Logger

  @output_formats Application.get_env(:gazetteer_drescher, :output_formats)
  @default_batch_size Application.get_env(:gazetteer_drescher, :default_batch_size)
  @harvesting_log Application.get_env(:gazetteer_drescher, :harvesting_log)

  alias GazetteerDrescher.Writing

  @doc """
  Function that handles the command line arguments and starts the harvesting
  process accordingly.

  Example: `main(["marc", "-t", "/custom/output/folder"])`

  Returns: `:ok`
  """
  def main(argv) do
    {requested_format, file_pid, days_offset} = argv
    |> parse_args
    |> validate_request

    setup({requested_format, file_pid, days_offset})
    success? =
      start_harvesting(days_offset)
      |> Enum.all?(fn(x) -> x == :ok  end)

    if success? do
      log_time()
    end

    Writing.write_footer()
    Logger.info "Done."
  end

  defp parse_args(argv) do
    case argv
         |> parsed_args do
      { %{ help: true }, _, _} ->
        :help

      { %{ target: target_path, days: days }, [ format ], _ } ->
        { String.to_atom(format), target_path, days}
      { %{ target: target_path }, [ format ], _ } ->
        { String.to_atom(format), target_path, nil}
      { %{ days: days }, [ format ], _ } ->
        { String.to_atom(format), nil, days}
      { %{} , [ format ] , _ } ->
        { String.to_atom(format), nil, nil }
      _ ->
        :help
    end
  end

  defp parsed_args(argv) do
    {switches, argv, errors} =
      OptionParser.parse(argv,
        switches: [ help: :boolean,
          target: :string,
          days: :integer],
        aliases:  [ h: :help,
          t: :target,
          d: :days]
      )
    { Enum.into(switches, %{}), argv, errors }
  end

  defp validate_request({format, nil, days_offset}) do
    { format, @output_formats[format][:default_target_file], days_offset}
    |> validate_request
  end

  defp validate_request({format, output_path, days_offset}) do
    file_pid =
      output_path
      |> Writing.open_output_file

    { format, file_pid, days_offset }
  end

  defp validate_request(_) do
    print_help()
  end

  defp setup({requested_format, file_pid, days_offset}) do
    Agent.start(fn ->
      { requested_format, file_pid, days_offset }
    end, name: RequestInfo)

    Agent.start(fn -> { 0 }
    end, name: ProcessingInfo)

    Writing.write_header()

    :ets.new(:cached_places, [:named_table, :public, read_concurrency: true])
  end

  defp start_harvesting(nil) do
    "q=*"
    |> GazetteerDrescher.Harvesting.start(@default_batch_size)
  end

  defp start_harvesting(days_offset) do
    to =
      :calendar.local_time()
      |> (fn({date, time}) -> date end).()
      |> Date.from_erl!
      |> Date.to_string

    from = check_date(days_offset)

    "q=lastChangeDate:[#{from}%20TO%20#{to}]"
    |> GazetteerDrescher.Harvesting.start(@default_batch_size)
  end

  defp check_date(days_offset) do
    case File.read(@harvesting_log) do
      {:ok, content} ->
        content
        |> Date.from_iso8601
        |> extend_timeframe?(days_offset)
      _ ->
        IO.inspect days_offset

        :calendar.local_time()
        |> IO.inspect
        |> (fn({date, time}) -> date end).()
        |> IO.inspect
        |> Date.from_erl!
        |> IO.inspect
        |> Date.add(-days_offset)
    end
  end

  defp extend_timeframe?({:ok, last_update}, requested_offset) do
    requested =
      :calendar.local_time()
      |> (fn({date, _time}) -> date end).()
      |> Date.from_erl!
      |> Date.add(-requested_offset)


    case Date.diff(requested, last_update) do
      true ->
        Logger.info "Extending offset up to last successful update: " <>
          "Harvesting every change since #{last_update}."
        last_update
      false ->
        Logger.info "Applying requested offset of #{requested_offset} days: " <>
          "Harvesting every change since #{requested}."
        requested
      default ->
        IO.inspect default
    end
  end

  defp extend_timeframe?({:error, message}, requested_offset) do
    IO.puts "Failed to parse #{@harvesting_log}:"
    IO.puts message
    IO.puts "Using requested offset."
    :calendar.local_time()
    |> (fn({date, _time}) -> date end).()
    |> Date.from_erl!
    |> Date.add(-requested_offset)
  end

  defp log_time() do
    file_pid = Writing.open_output_file(@harvesting_log)

    {:ok, out_str} =
      :calendar.local_time()
      |> (fn({date, _time}) -> date end).()
      |> Date.from_erl!
      |> Date.to_string

    IO.binwrite file_pid, out_str
  end

  defp print_help() do
    IO.puts "Usage: ./gazetter_drescher <output_format> [options]"
    IO.puts ""
    IO.puts "Available output formats: "
    Enum.each @output_formats, fn ({key, val}) ->
      IO.puts "  '#{key}': #{val[:description]}"
    end
    IO.puts "Options: -t | --target <output path>"
    IO.puts "         -h | --help"
    System.halt(0)
  end
end
