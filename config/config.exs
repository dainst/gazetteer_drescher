# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
use Mix.Config

config :gazetteer_drescher,
  default_batch_size: 100,
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
