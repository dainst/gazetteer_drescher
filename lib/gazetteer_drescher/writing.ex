defmodule GazetteerDrescher.Writing do
  require Logger
  
  alias GazetteerDrescher.MARC

  def open_output_file(file) do
    file
      |> Path.dirname
      |> File.mkdir_p!

    file
      |> File.open!([:write, :utf8])
  end

  def write_place({:ok, place}) do
    { output_format, file_pid, _days_offset } = Agent.get(RequestInfo, &(&1))

    case output_format do
      :marc ->
        marc =
          place
          |> MARC.create_output

        IO.write( file_pid, marc )
      _ -> Logger.error "Unknown output format: #{output_format}"
    end
  end
end
