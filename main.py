import sys
import os
import logging
import config.config as config
import harvesting

logging.basicConfig(format="%(asctime)s-%(levelname)s-%(name)s - %(message)s")
logger = logging.getLogger(__name__)
logger.setLevel(logging.INFO)

if __name__ == "__main__":

  if(len(sys.argv) != 3):
    logger.info("Usage: python <format type> <output file>")
    logger.info("Possible format types:")
    counter = 0

    for k, v in config.existingFormats.items():
      logger.info(" {0} ({1})".format(k, v["description"]))

    sys.exit()

  requestInfo = {
    "format": sys.argv[1],
    "output_path": sys.argv[2]
    }

  harvesting.start(requestInfo)
