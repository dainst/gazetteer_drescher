defmodule GazetteerDrescher.MARC.Record do
  @moduledoc """
  This module defines a basic Struct for marc21 records.
  """
  defstruct [fields: []]

  alias GazetteerDrescher.MARC.{ Field, Record }

  @doc """
  Add another GazetteerDrescher.MARC.Field to a given record.

  Returns: The updated Record struct.
  """
  def add_field(record = %Record{}, field = %Field{}) do
    Map.put(record, :fields, record.fields ++ [field])
  end

  @doc """
  Transform a given record into a single marc21 string, including its
  fields and its fields' subfields.

  Returns: The Record data as a string formatted as marc21.
  """
  def to_marc(record = %Record{}) do

    processed_fields = Enum.map(record.fields, &Field.to_marc(&1))

    { directory, _ } = processed_fields
    |> Enum.map(fn({tag, content}) -> { tag, byte_size(content)} end )
    |> Enum.reduce({"", 0}, &create_dictionary/2)

    final_fields = processed_fields
    |> Enum.reduce("", &finalize_fields/2)

    directory = directory <> << 30 >>

    base_address = 24 + String.length(directory)

    record_length = base_address + byte_size(final_fields) + 1 # +1 for << 29 >>
    |> to_string
    |> String.pad_leading(5, "0")

    base_address = base_address
    |> to_string
    |> String.pad_leading(5, "0")

    leader = "#{record_length}nz##a22#{base_address}n##4500"
    leader <> directory <> final_fields <> << 29 >>
  end

  defp create_dictionary({tag, length}, {result, offset}) do
    adjusted_tag = String.pad_leading(to_string(tag), 3, "0")
    adjusted_offset = String.pad_leading(to_string(offset), 5, "0")
    adjusted_length = String.pad_leading(to_string(length), 4, "0")

    { result <> adjusted_tag <> adjusted_length <> adjusted_offset, offset + length }
  end

  defp finalize_fields({_tag, content}, result) do
    result <> content
  end
end
