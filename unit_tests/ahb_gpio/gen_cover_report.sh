#!/usr/bin/env bash

UCDB_FILE=testdb.ucdb

# vsim -c -cvgperinstance -viewcov "${UCDB_FILE}" -do "coverage report -file final_report.txt -byfile -detail -noannotate -option -cvg"
vcover report -details -html "${UCDB_FILE}"
