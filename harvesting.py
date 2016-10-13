import sys
import config
import json
import urllib2
import importlib

import logging
logger = logging.getLogger(__name__)
logger.setLevel(logging.INFO)

def start(requestInfo):
  output = getOutputModule(requestInfo["format"])
  query = (config.gazetteerBaseURL + "search?limit="
    + str(config.batchSize) + "&offset=0&q=*")

  firstBatch = getNextBatch(0)

  total = firstBatch["total"]
  logger.info(str(total) + " places found in Gazetteer.")
  if(config.limitResults != 0):
    total = config.limitResults

  output.writeBatchToFile(getBatchDetails(firstBatch), requestInfo)

  counter = config.batchSize
  while counter < total:
    batch = getBatchDetails(getNextBatch(counter))
    output.writeBatchToFile(batch, requestInfo)
    counter += config.batchSize

def getNextBatch(counter):
  query = (config.gazetteerBaseURL + "search?limit="
    + str(config.batchSize) + "&offset=" + str(counter) + "&q=*")
  return runQuery(query)

def getBatchDetails(batch):
  detailedResults = []

  for place in batch["result"]:
    query = config.gazetteerBaseURL + "place/" + str(place["gazId"])
    detailedResults.append(runQuery(query))

  return detailedResults

def runQuery(q):
  req = urllib2.Request(q, headers = {"Accept" : "application/json"})
  return json.loads(urllib2.urlopen(req).read())

def getOutputModule(reqFormat):
  return importlib.import_module(config.existingFormats[reqFormat]["module"])
