import sys
import logging
import config
import json

from pymarc import Record, Field

logging.basicConfig(format='%(asctime)s-%(levelname)s-%(name)s - %(message)s')
logger = logging.getLogger(__name__)
logger.setLevel(logging.INFO)

def writeBatchToFile(batch, requestInfo):
  out = open(requestInfo["output_path"], 'wb')
  for item in batch:
    
  out.close()
