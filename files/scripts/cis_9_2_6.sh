#!/bin/bash

# References
# http://stackoverflow.com/questions/14103806/bash-test-if-a-directory-is-writable-by-a-given-uid

set -e -u

check_path() {
   # Function parameters
   local DIR=$1
   local USER=$2

   # Default return code to success
   local check_path_rc=0

   # Get path's attributes
   local INFO=( $(stat -L -c "%a %G %U" $DIR) )
   if [[ ${#INFO[@]} -eq 0 ]]; then
      echo "$0 cannot stat $DIR"
      return 1
   fi
   local PERM=$(printf "%04d" ${INFO[0]})
   local GROUP=${INFO[1]}
   local OWNER=${INFO[2]}

   # Compare user
   if [[ $USER != $OWNER ]]; then
      echo "$DIR is owned by $OWNER rather than $USER"
      check_path_rc=1
   fi

   # Check for group/other write
   if [[ $((0$PERM & 00002)) != 0 ]]; then
      echo "$DIR permissions are $PERM (world writable)"
      check_path_rc=1
   elif [[ $((0$PERM & 00020)) != 0 ]]; then
      echo "$DIR permissions are $PERM (group writable)"
      check_path_rc=1
   fi

   return $check_path_rc
}

check_files() {
   # Function parameters
   local DIR=$1
   local USER=$2

   local INFO=""
   local PERM=""
   local GROUP=""
   local OWNER=""

   # Default return code to success
   local check_files_rc=0

   for file in ${DIR}/*
   do
      if [[ -d $file ]]; then
        continue
      fi

      # Get file's attributes
      INFO=( $(stat -L -c "%a %G %U" $file) )
      if [[ ${#INFO[@]} -eq 0 ]]; then
         echo "$0 cannot stat $file"
         return 1
      fi
      PERM=$(printf "%04d" ${INFO[0]})
      GROUP=${INFO[1]}
      OWNER=${INFO[2]}

      # lppasswd is expected to be lp
      if [[ $file = /usr/bin/lppasswd ]] && [[ $OWNER = lp ]]; then
         OWNER=root
      fi


      # Compare user
      if [[ $USER != $OWNER ]]; then
         echo "$file is owned by $OWNER rather than $USER"
         check_files_rc=$(( $check_files_rc + $? ))
      fi

      # Check for group/other write
      if [[ $((0$PERM & 00002)) != 0 ]]; then
         echo "$file permissions are $PERM (world writable) \$(($PERM & 0002)) is $(($PERM & 0002))"
         check_files_rc=$(( $check_files_rc + $? ))
      elif [[ $((0$PERM & 00020)) != 0 ]]; then
         echo "$file permissions are $PERM (group writable) \$(($PERM & 0020)) is $(($PERM & 0020))"
         check_files_rc=$(( $check_files_rc + $? ))
      fi
   done
   return $check_files_rc
}

rc=0
echo $PATH | tr ':' '\n' | while read path
  do
    check_files $path root
    rc=$(( $rc + $? ))

    while [[ $path != "/" ]]; do
      check_path $path root
      rc=$(( $rc + $? ))
      path=$(dirname $path)
    done
  done

check_path / root
rc=$(( $rc + $? ))

check_path /export/nfshome/s5sar/test root
rc=$(( $rc + $? ))
exit $rc
