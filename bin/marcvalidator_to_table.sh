#!/usr/bin/env bash

# Transform MarcEdit's MarcValidator report into tsv
# containing rows like:
#   001 value, error_1, error_2, error_n...

if [[ $# -lt 1 ]]; then
  echo "USAGE: marcvalidator_to_table.sh INPUTFILE > OUTFILE"
  exit 1
fi

for FILE in "$@"
do
  grep "^\(Record\|001\|\s\)" "$FILE" \
    | tr -d '\r' \
    | tr '\n' '\t' \
    | sed 's/Record[^\t]*\t/\n/g' \
    | sed -e 's/\t\{2\}/\t/g' -e 's/001 (if defined):\s*//' -e 's/\t$//'
done



