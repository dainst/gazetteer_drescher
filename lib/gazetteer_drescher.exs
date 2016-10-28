defmodule GazetteerDrescher do
  @moduledoc """
  This module is used to run the application via Mix.
  """

  System.argv
  |> GazetteerDrescher.CLI.main
  |> IO.inspect
end
