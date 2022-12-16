#!/usr/bin/env bash

set -e

# source config for QUESTA
source /usr/local/mentor/QUESTA-CORE-PRIME_10.7c/settings.sh

vcover merge merged.ucdb write_only/write_only.ucdb read_only/read_only.ucdb

# vsim -cvgperinstance -viewcov merged.ucdb -do "coverage report -detail"
vcover report -details -html merged.ucdb
