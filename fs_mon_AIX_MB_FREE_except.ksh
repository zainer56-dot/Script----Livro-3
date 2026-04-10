#!/usr/bin/ksh
#
# SCRIPT: fs_mon_AIX_MB_FREE_except.ksh
# AUTHOR: Zainer Araujo
# DATE: 18-12-2025
# REV: 2.1.P
#

##### VARIABLES #####
MIN_MB_FREE="50MB"
WORKFILE="/tmp/df.work"
OUTFILE="/tmp/df.outfile"
EXCEPTIONS="/usr/local/bin/exceptions"
DATA_EXCEPTIONS="/tmp/dfdata.out"
THISHOST=$(hostname)

> "$WORKFILE"
> "$OUTFILE"

##### FUNCTIONS #####

check_exceptions() {
    while read FSNAME FSLIMIT
    do
        # NFS sanity check (host:/mount -> /mount)
        [[ "$FSNAME" == *:* ]] && FSNAME=${FSNAME#*:}

        # Ignore empty limits
        [ -z "$FSLIMIT" ] && continue

        # Convert MB -> KB
        FSLIMIT=${FSLIMIT%MB}
        typeset -i FSLIMIT
        (( FSLIMIT = FSLIMIT * 1024 ))

        if [[ "$FSNAME" = "$FSMOUNT" ]]
        then
            if (( FSMB_FREE < FSLIMIT ))
            then
                return 1   # Found, out of limit
            else
                return 2   # Found, OK
            fi
        fi
    done < "$DATA_EXCEPTIONS"

    return 3   # Not found
}

######## MAIN ########

# Load exceptions file
if [ -s "$EXCEPTIONS" ]
then
    grep -Ev '^\s*#|^\s*$' "$EXCEPTIONS" > "$DATA_EXCEPTIONS"
fi

# Collect filesystem data (device, free KB, mount)
df -k | tail +2 | egrep -v '/dev/cd[0-9]|/proc' \
| awk '{print $1, $3, $7}' > "$WORKFILE"

# Convert MIN_MB_FREE to KB
MIN_MB_FREE=${MIN_MB_FREE%MB}
typeset -i MIN_MB_FREE
(( MIN_MB_FREE = MIN_MB_FREE * 1024 ))

# Process filesystems
while read FSDEVICE FSMB_FREE FSMOUNT
do
    typeset -i FSMB_FREE

    if [ -s "$EXCEPTIONS" ]
    then
        check_exceptions
        RC=$?

        case $RC in
            1)  # Exception found, out of limit
                (( FS_FREE_OUT = FSMB_FREE / 1024 ))
                echo "$FSDEVICE mounted on $FSMOUNT only has ${FS_FREE_OUT}MB Free" \
                >> "$OUTFILE"
                continue
                ;;
            2)  # Exception found, OK
                continue
                ;;
        esac
    fi

    # Default script threshold
    if (( FSMB_FREE < MIN_MB_FREE ))
    then
        (( FS_FREE_OUT = FSMB_FREE / 1024 ))
        echo "$FSDEVICE mounted on $FSMOUNT only has ${FS_FREE_OUT}MB Free" \
        >> "$OUTFILE"
    fi

done < "$WORKFILE"

# Output
if [ -s "$OUTFILE" ]
then
    print "\nFull Filesystem(s) on $THISHOST\n"
    cat "$OUTFILE"
fi

exit 0
