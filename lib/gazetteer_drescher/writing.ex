defmodule GazetteerDrescher.Writing do

  def open_output_file(file) do
    file
    |> Path.dirname
    |> File.mkdir_p!

    file
    |> File.open!([:write, :utf8])
  end

  def write_place({:ok, place}, :marc, file_pid) do
    IO.write( file_pid, place["@id"])
  end
end
