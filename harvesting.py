import sys
import logging
import config.config as config
import json
import urllib2

logging.basicConfig(format='%(asctime)s-%(levelname)s-%(name)s - %(message)s')
logger = logging.getLogger(__name__)
logger.setLevel(logging.INFO)

def start(requestInfo):
  print requestInfo

  query = (config.gazetteerBaseURL + "search?limit="
    + str(config.batchSize) + "&offset=0&q=*")

  firstBatch = runQuery(query)

  total = firstBatch["total"]
  logger.info(str(total) + " places found in Gazetteer.")

  # TODO: Write write output (first batch)

  counter = config.batchSize
  while counter < total:
    [counter, result] = nextBatch(counter)
    # TODO: Write output

def nextBatch(counter):
  print str(counter)

  query = (config.gazetteerBaseURL + "search?limit="
    + str(config.batchSize) + "&offset=" + str(counter) + "&q=*")

  return [counter + config.batchSize, runQuery(query)]

def runQuery(q):
  req = urllib2.Request(q, headers = {"Accept" : "application/json"})
  return json.loads(urllib2.urlopen(req).read())
