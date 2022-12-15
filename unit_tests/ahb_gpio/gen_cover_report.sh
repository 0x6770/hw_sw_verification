#!/usr/bin/env bash

set -e

# source config for QUESTA
source /usr/local/mentor/QUESTA-CORE-PRIME_10.7c/settings.sh

vcover merge merged.ucdb write_only/testdb.ucdb read_only/testdb.ucdb

# vsim -c -cvgperinstance -viewcov "${UCDB_FILE}" -do "coverage report -file final_report.txt -byfile -detail -noannotate -option -cvg"
vcover report -details -html merged.ucdb
