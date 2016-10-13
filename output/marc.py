import sys
import logging
import config
import json

from pymarc import Record, Field
from pymarc.constants import LEADER_LEN

import logging
logger = logging.getLogger(__name__)
logger.setLevel(logging.INFO)

def writeBatchToFile(batch, requestInfo):
  out = open(requestInfo["output_path"], "w")
  for item in batch:
    print "\n"
    #for key, value in item.items():
    #  if key not in ["prefLocation"]:
    #      logger.info(str(key) + ": " + str(value))

    record = Record(to_unicode=True, force_utf8=True)
    record.add_field(
      Field(
        tag = "151",
        indicators = [" ", " "],
        subfields = [
          "a", item["prefName"]["title"],
        ]),
      Field(
        tag = "40",
        indicators = [" ", " "],
        subfields = [
          "a", "iDAI.gazetteer"
        ]),
      Field(
        tag = "24",
        indicators = [" ", " "],
        subfields = [
          "a", item["gazId"],
          "2", "iDAI.gazetteer"
        ])
      )

    if "names" in item:
      for altName in item["names"]:
        record = addGeoTracing(record, altName["title"])

    recordLength = str(len(record.as_marc()))
    counter = len(recordLength)
    while counter < 4:
      recordLength = "0" + recordLength
      counter += 1

    record.leader = (recordLength + "c" + "z"
      + record.leader[7:LEADER_LEN])

    out.write(record.as_marc())

  out.close()

def addGeoTracing(record, data):
  record.add_field(
    Field(
      tag = "451",
      indicators = [" ", " "],
      subfields = [
        "a", data
      ]
    )
  )
  return record
