defmodule GazetteerDrescher.CLI do
  require Logger

  @output_types Application.get_env(:gazetteer_drescher, :output_types)
  @default_batch_size Application.get_env(:gazetteer_drescher, :default_batch_size)

  alias GazetteerDrescher.Writing

  def main(argv) do
    argv
    |> parse_args
    |> validate_request
    |> setup

    Logger.info "Done."
  end

  def parse_args(argv) do
    case argv |> parsed_args do
      { %{ help: true }, _, _} ->
        :help

      { %{ target: target_path, days: days }, [ format ], _ } ->
        { String.to_atom(format), target_path, days}
      { %{ target: target_path }, [ format ], _ } ->
        { String.to_atom(format), target_path, nil}
      { %{ days: days }, [ format ], _ } ->
        { String.to_atom(format), nil, days}
      { [] , [ format ] , _ } ->
        { String.to_atom(format), nil, nil }
      _ ->
        :help
    end
  end

  defp parsed_args(argv) do
    {switches, argv, errors} =
      OptionParser.parse(argv,
        switches: [ help: :boolean,
          format: :string,
          target: :string,
          days: :integer],
        aliases:  [ h: :help,
          f: :format,
          t: :target,
          d: :days]
      )
    { Enum.into(switches, %{}), argv, errors }
  end

  defp validate_request({:marc, nil, days_offset}) do
    {:marc, @output_types[:marc][:default_target_file], days_offset}
    |> validate_request
  end

  defp validate_request({:marc, output_path, days_offset}) do
    file_pid =
      output_path
      |> Writing.open_output_file

    { :marc, file_pid, days_offset }
  end

  defp validate_request(_) do
    print_help
  end

  defp setup({requested_type, file_pid, days_offset}) do

    Agent.start(fn ->
      { requested_type, file_pid, days_offset }
    end, name: RequestInfo)

    :ets.new(:cached_places, [:named_table, :public, read_concurrency: true])

    start_harvesting(days_offset)
  end

  defp start_harvesting(nil) do
    "q=*"
    |> GazetteerDrescher.Harvesting.start(@default_batch_size)
  end

  defp start_harvesting(days_offset) do
    to    = Timex.today
    from  = Timex.shift(to, days: -days_offset)

    "q=lastChangeDate:[#{from}%20TO%20#{to}]"
    |> GazetteerDrescher.Harvesting.start(@default_batch_size)
  end

  defp print_help() do
    IO.puts "Usage: ./gazetter_drescher <output_format> [options]"
    IO.puts ""
    IO.puts "Available output formats: "
    Enum.each @output_types, fn ({key, val}) ->
      IO.puts "  '#{key}': #{val[:description]}"
    end
    IO.puts "Options: -t | --target <output path>"
    IO.puts "         -h | --help"
    System.halt(0)
  end
end
