defmodule GazetteerDrescher.CLI do
  require Logger

  @output_types Application.get_env(:gazetteer_drescher, :output_types)
  @default_batch_size Application.get_env(:gazetteer_drescher, :default_batch_size)

  alias GazetteerDrescher.Writing

  def main(argv) do
    argv
    |> parse_args
    |> validate_request
    |> start_harvesting

  end

  def parse_args(argv) do
    case argv |> parsed_args do
      { %{ help: true }, _, _} ->
        :help
      { %{ type: type, target_path: target_path }, _, _ } ->
        { String.to_atom(type), target_path}
      { %{ type: type}, _, _ } ->
        { String.to_atom(type)}
      _ ->
        :help
    end
  end

  defp parsed_args(argv) do
    {switches, argv, errors} = OptionParser.parse(argv,
      switches: [ help: :boolean, type: :string, target_path: :string],
      aliases:  [ h:    :help,    t: :target_path ]
    )

    { Enum.into(switches, %{}), argv, errors }
  end

  defp validate_request({:marc}) do
    validate_request({:marc, @output_types[:marc][:default_target_file]})
  end

  defp validate_request({:marc, output_path}) do
    {:marc, Writing.open_output_file(output_path)}
  end

  defp validate_request(_) do
    print_help
  end

  defp start_harvesting({requested_type, file_pid}) do
    Agent.start(fn ->
      {requested_type, file_pid}
    end, name: RequestInfo)

    :ets.new(:cached_places, [:named_table, :public])
    # To much data for Agent module, fallback to ETS table
    # Agent.start(fn ->
    #   HashDict.new
    # end, name: CachedPlaces)

    GazetteerDrescher.Harvesting.start(@default_batch_size)

    Logger.info "Done."
  end

  defp print_help() do
    IO.puts "usage: mix run lib/gazetteer_drescher.ex --type <output_type>"
    IO.puts "Possible output types: "
    Enum.each @output_types, fn ({key, val}) ->
      IO.puts "'#{key}': #{val[:description]}"
    end
    IO.puts ""
    IO.puts "options: -t | --target_path <output path>"
    System.halt(0)
  end
end
