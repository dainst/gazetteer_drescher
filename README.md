# gazetteer_drescher
Harvesting application [(Documentation)](https://dainst.github.io/gazetteer_drescher/api-reference.html) for the 
[iDAI.gazetteer](https://gazetteer.dainst.org/),
written in [Elixir](http://elixir-lang.org/)/[Erlang](http://www.erlang.org/).

## Prerequisites 

### Variant: Docker

If you want to run the harvester with docker, there are no further prerequisites.

### Variant: Elixir/Erlang installation


Elixir runs in the Erlang Virtual Machine (VM), so you will need to install both Erlang and Elixir

The development setup was done so far by simply running  `brew install erlang` and `brew install elixir` on Mac OS X 
and the `apt-get`-variants for Ubuntu/Debian.

For further installation information and variants see:

* http://www.erlang.org/downloads
* http://elixir-lang.org/install.html
* https://www.erlang-solutions.com/resources/download.html


After having installed both Erlang and Elixir, check out the repository, switch to its root directory and run `mix 
deps.get`.    

[Mix](http://elixir-lang.org/getting-started/mix-otp/introduction-to-mix.html) is Elixir's package manager/build tool 
and should download everything automatically by reading the dependencies from  `mix.exs`.


## Usage

### Running the program

#### (1) Using Docker

* Build the image: `docker build -t dainst/gazetteer_drescher .`.
* Run the script: `docker run -v <Repository Path>/output:/gazetteer_drescher/output dainst/gazetteer_drescher <mix 
command, see (2)>`.

#### (2) Using Mix:
* In the root directory, run `mix run lib/gazetteer_drescher.exs <format> [options]`.
* This is the easiest way to work on the application during development.


#### Options
* `-h | --help` for usage information, including a list of all available `<formats>`.
* `-t | --target <target path>` for specifying the desired output directory and file. This is _optional_: Each format 
defines a default directory and filename in `config/config.exs`.
* `-d | --days <n days offset>`. This is _optional_: Only retrieve places that were added or changed in between now and 
the last n days specified by the offset.
* `-c | --continue`. This is _optional_: Only since the last time the script was run (as logged in log/time.log). If 
the script is run twice at the same day, only that day changes that day are downloaded.
Options -d and -c are mutually exclusive.
 
## Format mapping information

### marc

Each record produced is flagged as an MARC authority record in its header. All fields and subfields listed represent 
MARC authority record fields/subfields.

Assigned values are taken either from individual JSON records (`place`) provided by the Gazetteer or static strings.

__024 ## a__: `place["gazId"]`  
__024 ## 2__: "iDAI.gazetteer"

__040 ## a__: "iDAI.gazetteer"

__151 ## a__: `place["prefName"]["title"]`

__451 ## a__: for each additional entry `name` in `place["names"]`: `name["prefName"]["title"]`

__551 ## a__: recursively for each of `place`'s ancestors up to the hierarchy root: `ancestor["prefName"]["title"]`   
__551 ## i__: "part of"
