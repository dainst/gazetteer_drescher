defmodule GazetteerDrescher.MARC.Record do
  defstruct [fields: []]

  alias GazetteerDrescher.MARC.{ Field, Record }

  def add_field(record = %Record{}, field = %Field{}) do
    Map.put(record, :fields, record.fields ++ [field])
  end

  def to_marc(record = %Record{}) do

    processed_fields = Enum.map(record.fields, &Field.to_marc(&1))

    { directory, _ } = processed_fields
    |> Enum.map(fn({tag, content}) -> { tag, String.length(content)} end )
    |> Enum.reduce({"", 0}, &create_dictionary/2)

    final_fields = processed_fields
    |> Enum.reduce("", &finalize_fields/2)

    directory = directory <> << 30 >>

    base_address = 24 + String.length(directory)

    record_length = base_address + String.length(final_fields) + 1
    |> to_string
    |> String.pad_leading(5, "0")

    base_address = base_address
    |> to_string
    |> String.pad_leading(5, "0")

    leader = "#{record_length}nz  a22#{base_address}n  4550"
    leader <> directory <> final_fields <> << 29 >>
  end

  def create_dictionary({tag, length}, {result, offset}) do
    adjusted_tag = String.pad_leading(to_string(tag), 3, "0")
    adjusted_offset = String.pad_leading(to_string(offset), 4, "0")
    adjusted_length = String.pad_leading(to_string(length), 5, "0")

    { result <> adjusted_tag <> adjusted_offset <> adjusted_length, offset + length }
  end

  def finalize_fields({_tag, content}, result) do
    result <> content
  end
end
