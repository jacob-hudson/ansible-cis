#!/bin/bash

# Exit on errors and undefined variables
set -e -u

# Setup temp files
tmpfile1=$(mktemp /tmp/cis-9.2.11-XXXXX)
tmpfile2=$(mktemp /tmp/cis-9.2.11-XXXXX)
tmpfile3=$(mktemp /tmp/cis-9.2.11-XXXXX)

# Trap signals
# https://www.turnkeylinux.org/blog/shell-error-handling
for sig in INT TERM EXIT; do
   trap "
      if [[ $sig != EXIT ]]; then
         rm $tmpfile1
         rm $tmpfile2
         rm $tmpfile3
         trap - $sig EXIT
         kill -s $sig $$
      fi
   " $sig
done

# Get GIDs from passwd
cut -d: -f4 /etc/passwd | sort -u -o $tmpfile1

# Get GIDs from group
cut -d: -f3 /etc/group | sort -u -o $tmpfile2

# Get any that are only in file 1 (suppress the group file and common to both)
comm -23 $tmpfile1 $tmpfile2 > $tmpfile3
cat $tmpfile3

# Set return code based on tmpfil3 having non zero size
rc=0
if [[ -s $tmpfile3 ]]; then
  rc=1
fi

# Cleanup
rm $tmpfile1 $tmpfile2 $tmpfile3

# Exit with return code
exit $rc
