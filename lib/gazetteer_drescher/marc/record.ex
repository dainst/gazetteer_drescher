defmodule GazetteerDrescher.MARC.Record do
  defstruct [:leader, :directory, fields: []]

  alias GazetteerDrescher.MARC.{Field, Record}

  def new_record() do
    %Record{}
  end


  def add_field(record = %Record{}, field = %Field{}) do
    Map.put(record, :fields, record.fields ++ [field])
  end

  def to_marc(record = %Record{}) do
    # update leader
    # update directory
    # condense into string
  end
end
