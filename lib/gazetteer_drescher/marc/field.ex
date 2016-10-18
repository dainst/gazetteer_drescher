defmodule GazetteerDrescher.MARC.Field do
  defstruct [:tag, :i1, :i2, subfields: []]

  alias GazetteerDrescher.MARC.Field

  def to_marc(field = %Field{}) do
    i1 =
      case field.i1 do
        nil -> "#"
        value -> value
      end
    i2 =
      case field.i2 do
        nil -> "#"
        value -> value
      end

    subfields_as_marc = field.subfields
    |> subfields_to_marc("")

    field_as_marc = i1 <> i2 <> subfields_as_marc

    {field.tag, to_string(field_as_marc)}
  end

  def subfields_to_marc([], result), do: result

  def subfields_to_marc([{key, value} | tail], result) do
    result = result <> Atom.to_string(key) <> value <> << 31 >>
    subfields_to_marc(tail, result)
  end
end
