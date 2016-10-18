defmodule GazetteerDrescher.MARC.Record do
  defstruct [:leader, :directory, fields: [], status: :new,
    force_unicode: false, indicator_count: 2, subfield_code_length: 2,
    encoding_level: :complete]

  alias GazetteerDrescher.MARC.{ Field, Record }

  def add_field(record = %Record{}, field = %Field{}) do
    Map.put(record, :fields, record.fields ++ [field])
  end

  def to_marc(record = %Record{}) do
    IO.inspect record

    "./test/test.marc"
    |> Path.dirname
    |> File.mkdir_p!

    pid = "./test/test.marc"
    |> File.open!([:write, :utf8])

    processed_fields = Enum.map(record.fields, &Field.to_marc(&1))
    |> IO.inspect

    directory = processed_fields
    |> Enum.map(fn({tag, content}) -> {tag, String.length(content)} end )
    |> Enum.reduce("", &create_dictionary/2)

    fields_final = processed_fields
    |> Enum.reduce("", &finalize_fields/2)

    directory = directory <> << 30 >>

    marc = directory <> fields_final <> << 29 >>



    #marc = fields_marc
    #|>  <> << 29 >>

    IO.write( pid, marc)

  end

  def create_dictionary({tag, length}, result) do

    adjusted_tag = String.pad_leading(to_string(tag), 3, "0")
    adjusted_length = String.pad_leading(to_string(length), 4, "0")

    result <> adjusted_tag <> adjusted_length
  end

  def finalize_fields({tag, content}, result) do
    result <> content
  end
end
