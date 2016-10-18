import sys
import config
import json
import urllib2
import importlib
import math

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


  out = open(requestInfo["output_path"], "w")
  
  logger.info("Processing first batch...")
  output.writeBatchToFile(getBatchDetails(firstBatch), requestInfo, out)

  infoCounter = 2
  infoBatchCount = int(math.ceil(float(total) / float(config.batchSize)))
  counter = config.batchSize
  while counter < total:
    logger.info("Processing batch " + str(infoCounter)
      + " of " + str(infoBatchCount) + "...")
    batch = getBatchDetails(getNextBatch(counter))
    output.writeBatchToFile(batch, requestInfo, out)
    counter += config.batchSize
    infoCounter += 1


  out.close()

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
  try:
    req = urllib2.Request(q, headers = {"Accept" : "application/json"})
    return json.loads(urllib2.urlopen(req).read())
  except urllib2.HTTPError, e:
    logger.error("HTTPError for query, response was:")
    logger.error(e.fp.read())
    return None


def getOutputModule(reqFormat):
  return importlib.import_module(config.formats[reqFormat]["module"])
