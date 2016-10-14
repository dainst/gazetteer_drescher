import sys
import logging
import config
import json

from pymarc import Record, Field
import logging

logger = logging.getLogger(__name__)
logger.setLevel(logging.DEBUG)

import harvesting

def writeBatchToFile(batch, requestInfo):
  out = open(requestInfo["output_path"], "w")
  for item in batch:

    # logger.debug("New location")
    # for key, value in item.items():
    #  if key not in ["prefLocation"]:
    #      logger.debug(str(key) + ": " + str(value))

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

    if "parent" in item:
      record = addParentTracing(record, item["parent"], [item["prefName"]["title"]])

    if "names" in item:
      record = addGeoTracing(record, item["names"], [item["prefName"]["title"]])

    record = customizeLeader(record)
    # logger.debug("Final marc21 record: ")
    # logger.debug(record.as_marc())

    out.write(record.as_marc())

  out.close()

def addParentTracing(record, parentURL, knownParents):
  parent = harvesting.runQuery(parentURL)

  if(parent == None or parent["prefName"]["title"] in knownParents):
    return record

  record.add_field(
    Field(
      tag = "551",
      indicators = [" ", " "],
      subfields = [
        "a", parent["prefName"]["title"],
        "i", "teil von"
      ])
    )

  knownParents.append(parent["prefName"]["title"])

  if("parent" not in parent):
    return record # reached root https://gazetteer.dainst.org/place/2042600
  else:
    return addParentTracing(record, parent["parent"], knownParents)

def addGeoTracing(record, alternativeNames, knownNames):
  for altName in alternativeNames:
    if(altName["title"] not in knownNames):
      record.add_field(
        Field(
          tag = "451",
          indicators = [" ", " "],
          subfields = [
            "a", altName["title"]
          ])
      )
      knownNames.append(altName["title"])

  return record


# The leader encodes meta information about the marc record
# This functions sets some flags that can not be inferred automatically
# by the pymarc library:
# 'Record status', 'Type of record' and the 'Encoding level', see also
# https://www.loc.gov/marc/authority/adleader.html
def customizeLeader(record):
  record.leader = (record.leader[0:5]
    + config.existingFormats["marc"]["options"]["record status"]
    + "z" + record.leader[7:17] + "n" + record.leader[18:])

  # logger.debug("Final leader: " + record.leader + ", length: "
  #   + str(len(record.leader)))
  return record
