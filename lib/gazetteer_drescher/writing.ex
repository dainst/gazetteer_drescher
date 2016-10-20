defmodule GazetteerDrescher.Writing do

  alias GazetteerDrescher.MARC

  def open_output_file(file) do
    file
      |> Path.dirname
      |> File.mkdir_p!

    file
      |> File.open!([:write, :utf8])
  end

  def write_place({:ok, place}, :marc, file_pid) do
    marc =
      place
      |> MARC.create_output

    IO.write( file_pid, marc )
  end
end
