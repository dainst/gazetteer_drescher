import sys
import logging
import config
import json

from pymarc import Record, Field

import logging
logger = logging.getLogger(__name__)
logger.setLevel(logging.INFO)

def writeBatchToFile(batch, requestInfo):
  out = open(requestInfo["output_path"], 'wb')
  for item in batch:
    print "\n"
    for key, value in item.items():
      if key not in ["prefLocation"]:
          logger.info(str(key) + ": " + str(value))
  out.close()
