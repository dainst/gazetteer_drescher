# gazetteer_drescher
Script for harvesting the [iDAI.gazetteer](https://gazetteer.dainst.org/).

## Requirements
* [pymark](https://github.com/edsu/pymarc) for generating MARC output.

## Usage
Simply run `python <format type> <output file>`. For information about the supported types run `python -h`.

The script `config.py` can be used for basic configuration and to include additional scripts for new output formats. These have to be added under `output/`.

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
