# gazetteer_drescher
Harvesting application for the [iDAI.gazetteer](https://gazetteer.dainst.org/),
written in [Elixir](http://elixir-lang.org/)/[Erlang](http://www.erlang.org/).

## Prerequisites
Elixir runs in the Erlang Virtual Machine, so you will need to install both Erlang and Elixir

1. For Erlang see either http://www.erlang.org/downloads or https://www.erlang-solutions.com/resources/download.html
2. For Elixir see either http://elixir-lang.org/install.html or also https://www.erlang-solutions.com/resources/download.html

Development so far was done by running `brew install erlang` and `brew install elixir` on Mac OS X or the `apt-get`-variants for Ubuntu/Debian.

After having installed both Erlang and Elixir, check out the repository, switch to its root directory and run `mix deps.get`. [Mix](http://elixir-lang.org/getting-started/mix-otp/introduction-to-mix.html) is Elixir's package manager/build tool and should download everything automatically, by reading the dependencies from  `mix.exs`.


## Usage

### Running the program
There are two recommended alternatives for running the application:

#### (1) Using Mix:
In the root directory, run `mix run lib/gazetteer_drescher.exs <format> [options]`. This is recommended for development.
#### (2) Compilation using [escript](http://elixir-lang.org/docs/master/mix/Mix.Tasks.Escript.Build.html):
In the root directory, run `mix escript.build`, which compiles the application into a single executable called `gazetteer_drescher`, which in turn can then run as `./gazetteer_drescher <format> [options]`.

### Options
* `-h | --help` for usage information, including a list of all available `<formats>`.
* `-t | --target <target path>` for the desired output directory and file. Each format defines a default directory and file name in `config/config.exs`.

## Format mapping information

### marc

Each output record is a flagged as an authority record. All fields and subfields listed represent authority record fields/subfields.

Assigned values are taken either from individual JSON records (`place`) provided by the Gazetteer or static strings.

_040 ## a_: "iDAI.gazetteer"

_024 ## a_: `place["gazId"]`

_024 ## 2_: "iDAI.gazetteer"

_151 ## a_: `place["prefName"]["title"]`

_451 ## a_: for each additional entry in `place["names"]`: `name["prefName"]["title"]`

_551 ## a_: for each of `place`'s ancestors: `ancestor["prefName"]["title"]`

_551 ## i_: "part of"
