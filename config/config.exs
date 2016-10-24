# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
use Mix.Config

config :gazetteer_drescher,
  default_batch_size: 10000,
  output_formats: [
    marc:
    %{
      description: "MARC21 authority record. See http://www.loc.gov/marc/authority/",
      default_target_file: "./output/gazetteer.marc"
    }
  ],
  gazetteer_base_url: "https://gazetteer.dainst.org",
  cached_place_types: ["continent", "administrative-unit"],
  harvesting_log: "./log/last_run.log"
# This configuration is loaded before any dependency and is restricted
# to this project. If another project depends on this project, this
# file won't be loaded nor affect the parent project. For this reason,
# if you want to provide default values for your application for
# 3rd-party users, it should be done in your "mix.exs" file.

# You can configure for your application as:
#
#     config :gazetteer_drescher, key: :value
#
# And access this configuration in your application as:
#
#     Application.get_env(:gazetteer_drescher, :key)
#
# Or configure a 3rd-party app:
#
#     config :logger, level: :info
#

# It is also possible to import configuration files, relative to this
# directory. For example, you can emulate configuration per environment
# by uncommenting the line below and defining dev.exs, test.exs and such.
# Configuration from the imported file will override the ones defined
# here (which is why it is important to import them last).
#
#     import_config "#{Mix.env}.exs"
