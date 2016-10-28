defmodule GazetteerDrescher.MARC.Field do
  @moduledoc """
  This module defines a basic Struct for marc21 fields.
  """
  defstruct [:tag, :i1, :i2, subfields: []]

  alias GazetteerDrescher.MARC.Field

  @doc """
  Transform a given field into a single marc21 string, including its subfields.

  Returns: The field data as a string formatted as marc21.
  """
  def to_marc(field = %Field{}) do
    i1 =
      case field.i1 do
        nil -> "#"
        value -> to_string(value)
      end
    i2 =
      case field.i2 do
        nil -> "#"
        value -> to_string(value)
      end

    subfields_as_marc =
      field.subfields
      |> subfields_to_marc("")

    field_as_marc = i1 <> i2 <> subfields_as_marc <> << 30 >>

    { field.tag, to_string(field_as_marc) }
  end

  defp subfields_to_marc([], result), do: result

  defp subfields_to_marc([{key, value} | tail], result) do
    result = result <> << 31 >> <> Atom.to_string(key) <> value
    subfields_to_marc(tail, result)
  end
end
