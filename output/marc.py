import sys
import logging
import config
import json

from pymarc import Record, Field


def writeBatchToFile(batch, requestInfo):
  out = open(requestInfo["output_path"], 'wb')
  for item in batch:

  out.close()
