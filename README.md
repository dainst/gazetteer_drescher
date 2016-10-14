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

MARC21 Field | MARC21 Subfield | Values: Either single JSON record harvested from Gazetteer as `place` or static strings.
--- | --- | ---
40 | ## a | "iDAI.gazetteer"
24 | ## a | `place["gazId"]`
24 | ## 2 | "iDAI.gazetteer"
151 | ## a | `place["prefName"]["title"]`
451 | ## a | for each additional entry in `place["names"]`: `name["prefName"]["title"]`
551 | ## a | for each of `place`'s ancestors: `ancestor["prefName"]["title"]`
551 | ## i | "part of"
