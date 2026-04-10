#!/usr/bin/ksh
#
# SCRIPT: fs_mon_AIX_MBFREE.ksh
# AUTHOR: Zainer Araujo
# DATE: 18-12-2025
# REV: 1.5.P
#

##### DEFINE FILES AND VARIABLES HERE #####
MIN_MB_FREE="50MB"          # Min. MB of free space
WORKFILE="/tmp/df.work"
OUTFILE="/tmp/df.outfile"
THISHOST=$(hostname)

> "$WORKFILE"
> "$OUTFILE"

######## START OF MAIN ########

# Get filesystem data (device, free KB, mount point)
df -k | tail +2 | egrep -v '/dev/cd[0-9]|/proc' \
| awk '{print $1, $3, $7}' > "$WORKFILE"

# Convert MIN_MB_FREE to KB
MIN_MB_FREE=${MIN_MB_FREE%MB}
typeset -i MIN_MB_FREE
(( MIN_MB_FREE = MIN_MB_FREE * 1024 ))

# Loop through each filesystem
while read FSDEVICE FS_KB_FREE FSMOUNT
do
    typeset -i FS_KB_FREE

    if (( FS_KB_FREE < MIN_MB_FREE ))
    then
        (( FS_FREE_OUT = FS_KB_FREE / 1024 ))
        echo "$FSDEVICE mounted on $FSMOUNT only has ${FS_FREE_OUT}MB free" \
        >> "$OUTFILE"
    fi
done < "$WORKFILE"

# Display output
if [ -s "$OUTFILE" ]
then
    print "\nFull Filesystem(s) on $THISHOST\n"
    cat "$OUTFILE"
fi

exit 0
