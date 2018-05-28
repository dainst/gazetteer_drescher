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
    url =
      argv
      |> parse_args
      |> setup

    success? =
      start_harvesting(url)
      |> Enum.all?(fn(x) -> x == :ok  end)

    if success? do
      write_time_log()
    end

    Writing.write_footer()
    Logger.info "Done."
  end

  defp extract_known_args(argv) do
    {switches, argv, errors} =
      OptionParser.parse(argv,
        switches: [
          help: :boolean,
          target: :string,
          days: :integer,
          continue: :boolean
        ],
        aliases:  [
          h: :help,
          t: :target,
          d: :days,
          c: :continue
        ]
      )
    { Enum.into(switches, %{}), argv, errors }
  end

  defp parse_args(argv) do
    case argv |> extract_known_args do
      { %{ help: true }, _, _} ->
        :help
      { %{ continue: true, days: _days}, _, _} ->
        :help
      { options, [ format_param ], _ } ->
        { String.to_atom(format_param), options}
      _ ->
        :help
    end
  end

  defp get_target_file(_format, %{target: target_path}) do
    target_path
  end

  defp get_target_file(format, _options) do
    @output_formats[format][:default_target_file]
  end

  defp get_query_string(%{days: days}) do
    to =
      :calendar.local_time()
      |> (fn({date, _time}) -> date end).()
      |> Date.from_erl!

    from =
      to
      |> Date.add(-days)
      |> Date.to_string()

    "q=lastChangeDate:[#{from}%20TO%20#{Date.to_string(to)}]"
  end

  defp get_query_string(%{continue: true}) do
    to =
      :calendar.local_time()
      |> (fn({date, _time}) -> date end).()
      |> Date.from_erl!
      |> Date.to_string

    case read_time_log() do
      {:ok, from} ->
        "q=lastChangeDate:[#{from}%20TO%20#{to}]"
      _ ->
        IO.puts("No previous log found, starting complete dump of all Gazetteer data.")
        "q=*"
    end

  end

  defp get_query_string(_options) do
    "q=*"
  end

  defp setup(:help) do
    print_help()
  end

  defp setup({format, options}) do
    file_pid =
      get_target_file(format, options)
      |> Writing.open_output_file

    Agent.start(fn -> { format, file_pid }  end, name: RequestInfo)
    Agent.start(fn -> { 0 }  end, name: ProcessingInfo)

    Writing.write_header()

    :ets.new(:cached_places, [:named_table, :public, read_concurrency: true])

    get_query_string(options)
  end

  defp start_harvesting(query) do
    query
    |> GazetteerDrescher.Harvesting.start(@default_batch_size)
  end

  defp read_time_log() do
    case File.read(@harvesting_log) do
      {:ok, content} ->
        content
        |> Date.from_iso8601()
        |> (fn({:ok, date}) -> {:ok, Date.to_string(date)} end).()
      _ ->
        :not_found
    end
  end

  defp write_time_log() do
    file_pid = Writing.open_output_file(@harvesting_log)

    out_str =
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
    IO.puts "         -d | --days <Integer> (Harvests changes within last n days)"
    IO.puts "         -c | --continue (Harvest everything since last harvest, reads log file in log/ directory)"
    IO.puts "Options -c and -d are mutually exclusive."
    System.halt(0)
  end
end
