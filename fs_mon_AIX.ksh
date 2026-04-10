#!/usr/bin/ksh
#
# SCRIPT: fs_mon_AIX.ksh
# AUTHOR: Zainer Araujo
# DATE: 18-12-2025
# REV: 1.1.P
# PURPOSE: Monitor full filesystems exceeding FSMAX
#

##### DEFINE FILES AND VARIABLES HERE #####
FSMAX=85                      # Max FS percentage
WORKFILE="/tmp/df.work"       # Holds filesystem data
OUTFILE="/tmp/df.outfile"     # Output display file
THISHOST=$(hostname)          # Hostname

> "$WORKFILE"
> "$OUTFILE"

######## START OF MAIN ########

# Get filesystem data
df -k | tail +2 | egrep -v '/dev/cd[0-9]|/proc' \
| awk '{print $1, $4, $7}' > "$WORKFILE"

# Loop through each filesystem
while read FSDEVICE FSVALUE FSMOUNT
do
    FSVALUE=${FSVALUE%\%}     # Remove % sign
    typeset -i FSVALUE

    if [ "$FSVALUE" -gt "$FSMAX" ]
    then
        echo "$FSDEVICE mounted on $FSMOUNT is ${FSVALUE}%" \
        >> "$OUTFILE"
    fi
done < "$WORKFILE"

# Check if output file has content
if [ -s "$OUTFILE" ]
then
    print "\nFull Filesystem(s) on $THISHOST\n"
    cat "$OUTFILE"
fi

exit 0
