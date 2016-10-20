# gazetteer_drescher
Harvesting application for the [iDAI.gazetteer](https://gazetteer.dainst.org/),
written in [Elixir](http://elixir-lang.org/)/[Erlang](http://www.erlang.org/).

## Prerequisites
Elixir runs in the Erlang Virtual Machine (VM), so you will need to install both Erlang and Elixir

The development setup was done so far by simply running  `brew install erlang` and `brew install elixir` on Mac OS X and the `apt-get`-variants for Ubuntu/Debian.

For further installation information and variants see:

* http://www.erlang.org/downloads
* http://elixir-lang.org/install.html
* https://www.erlang-solutions.com/resources/download.html


After having installed both Erlang and Elixir, check out the repository, switch to its root directory and run `mix deps.get`.    

[Mix](http://elixir-lang.org/getting-started/mix-otp/introduction-to-mix.html) is Elixir's package manager/build tool and should download everything automatically by reading the dependencies from  `mix.exs`.


## Usage

### Running the program

#### (1) Using Mix:
* In the root directory, run `mix run lib/gazetteer_drescher.exs <format> [options]`.
* This is the easiest way to run the application during development.

#### (2) Compilation using [escript](http://elixir-lang.org/docs/master/mix/Mix.Tasks.Escript.Build.html):
* In the root directory, run `mix escript.build`.
* This compiles the application into a single executable called `gazetteer_drescher`.
* The executable can be started like any command line application: `./gazetteer_drescher <format> [options]`.
* Any machine that has the Erlang Virtual Machine installed can run the executable.

#### Options
* `-h | --help` for usage information, including a list of all available `<formats>`.
* `-t | --target <target path>` for specifying the desired output directory and file. This is _optional_: Each format defines a default directory and filename in `config/config.exs`.
* `-d | --days <n days offset>`. This is _optional_: Only retrieve places that were added or changed in between now and the last n days specified by the offset.

## Format mapping information

### marc

Each record produced is flagged as an MARC authority record in its header. All fields and subfields listed represent MARC authority record fields/subfields.

Assigned values are taken either from individual JSON records (`place`) provided by the Gazetteer or static strings.

__040 ## a__: "iDAI.gazetteer"

__024 ## a__: `place["gazId"]`  
__024 ## 2__: "iDAI.gazetteer"

__151 ## a__: `place["prefName"]["title"]`  

__451 ## a__: for each additional entry `name` in `place["names"]`: `name["prefName"]["title"]`

__551 ## a__: recursively for each of `place`'s ancestors up to the hierarchy root: `ancestor["prefName"]["title"]`   
__551 ## i__: "part of"
