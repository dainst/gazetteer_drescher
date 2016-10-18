formats = {
  "marc": {
    "description": "Standard MARC21 Format for Bibliographic Data, ISO2709.",
    "module": "output.marc",
    "options": {
      "record status": "n", # see https://www.loc.gov/marc/authority/adleader.html
      "cached types": ["continent", "administrative-unit"]
    }
  },
  "marcxml": {
    "description": "MARC21 data provided as XML.",
    "module": "output.marcxml"
  }
}

gazetteerBaseURL = "https://gazetteer.dainst.org/"
batchSize = 2500
limitResults = 0
