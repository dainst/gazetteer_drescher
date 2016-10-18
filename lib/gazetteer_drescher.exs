defmodule GazetteerDrescher do
  System.argv
  |> GazetteerDrescher.CLI.main
end
