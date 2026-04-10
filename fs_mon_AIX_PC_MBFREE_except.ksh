#!/usr/bin/ksh
#
# SCRIPT: fs_mon_AIX_PC_MBFREE_except.ksh
# AUTHOR: Zainer Araujo
# DATE: 18-12-2025
# REV: 4.3.P
# PURPOSE:
#   Monitor filesystems using %Used or MB Free automatically,
#   with override capability via exceptions file.
#
# PLATFORM: AIX
#
# set -n   # Syntax check only
# set -x   # Debug mode
#

##### DEFINE VARIABLES #####

MIN_MB_FREE="100MB"        # Minimum MB Free
MAX_PERCENT="85%"          # Max % Used
FSTRIGGER="1000MB"         # Size trigger to switch method

WORKFILE="/tmp/df.work"
OUTFILE="/tmp/df.outfile"

> $WORKFILE
> $OUTFILE

EXCEPTIONS="/usr/local/bin/exceptions"
DATA_EXCEPTIONS="/tmp/dfdata.out"
EXCEPT_FILE="N"

THISHOST=$(hostname)

##### FORMAT VALUES (KB) #####
(( MIN_MB_FREE = ${MIN_MB_FREE%MB} * 1024 ))
(( FSTRIGGER   = ${FSTRIGGER%MB}   * 1024 ))

####################################
function load_FS_data
{
    df -k | tail +2 | egrep -v '/dev/cd[0-9]|/proc' \
    | awk '{print $1, $2, $3, $4, $7}' > $WORKFILE
}
####################################
function load_EXCEPTIONS_data
{
    grep -v "^#" $EXCEPTIONS | sed '/^$/d' > $DATA_EXCEPTIONS
}
####################################
function check_exceptions
{
    while read FSNAME FSLIMIT
    do
        IN_FILE="N"

        # NFS sanity check
        echo "$FSNAME" | grep ':' >/dev/null && FSNAME=$(echo $FSNAME | cut -d':' -f2)

        [[ "$FSNAME" != "$FSMOUNT" ]] && continue

        [[ -z "$FSLIMIT" ]] && continue

        echo "$FSLIMIT" | grep -i MB >/dev/null && {
            IN_FILE="MB"
            FSLIMIT=${FSLIMIT%MB}
            (( FSLIMIT = FSLIMIT * 1024 ))
        }

        echo "$FSLIMIT" | grep "%" >/dev/null && {
            IN_FILE="PC"
            FSLIMIT=${FSLIMIT%\%}
        }

        case $IN_FILE in
        MB)
            if (( FSMB_FREE < FSLIMIT ))
            then
                return 1   # MB Free exceeded
            else
                return 3   # OK
            fi
            ;;
        PC)
            if (( PC_USED > FSLIMIT ))
            then
                return 2   # % Used exceeded
            else
                return 3   # OK
            fi
            ;;
        *)
            return 4       # Use defaults
            ;;
        esac
    done < $DATA_EXCEPTIONS

    return 4
}
####################################
function display_output
{
    if [[ -s $OUTFILE ]]
    then
        print "\nFull Filesystem(s) on $THISHOST\n"
        cat $OUTFILE
        print
    fi
}
####################################
######## START OF MAIN #############
####################################

load_FS_data

if [[ -s $EXCEPTIONS ]]
then
    load_EXCEPTIONS_data
    EXCEPT_FILE="Y"
fi

while read FSDEVICE FSSIZE FSMB_FREE PC_USED FSMOUNT
do
    FSMB_FREE=${FSMB_FREE%MB}
    PC_USED=${PC_USED%\%}

    typeset -i FSMB_FREE PC_USED FSSIZE

    if [[ $EXCEPT_FILE = "Y" ]]
    then
        check_exceptions
        CE_RC=$?

        case $CE_RC in
        1)
            (( FS_FREE_OUT = FSMB_FREE / 1024 ))
            echo "$FSDEVICE mounted on $FSMOUNT has ${FS_FREE_OUT}MB Free" >> $OUTFILE
            ;;
        2)
            echo "$FSDEVICE mounted on $FSMOUNT is ${PC_USED}% used" >> $OUTFILE
            ;;
        3)
            :   # OK
            ;;
        4)
            if (( FSSIZE >= FSTRIGGER ))
            then
                if (( FSMB_FREE < MIN_MB_FREE ))
                then
                    (( FS_FREE_OUT = FSMB_FREE / 1024 ))
                    echo "$FSDEVICE mounted on $FSMOUNT has ${FS_FREE_OUT}MB Free" >> $OUTFILE
                fi
            else
                MAX_PERCENT=${MAX_PERCENT%\%}
                if (( PC_USED > MAX_PERCENT ))
                then
                    echo "$FSDEVICE mounted on $FSMOUNT is ${PC_USED}% used" >> $OUTFILE
                fi
            fi
            ;;
        esac
    else
        if (( FSSIZE >= FSTRIGGER ))
        then
            if (( FSMB_FREE < MIN_MB_FREE ))
            then
                (( FS_FREE_OUT = FSMB_FREE / 1024 ))
                echo "$FSDEVICE mounted on $FSMOUNT has ${FS_FREE_OUT}MB Free" >> $OUTFILE
            fi
        else
            MAX_PERCENT=${MAX_PERCENT%\%}
            if (( PC_USED > MAX_PERCENT ))
            then
                echo "$FSDEVICE mounted on $FSMOUNT is ${PC_USED}% used" >> $OUTFILE
            fi
        fi
    fi
done < $WORKFILE

display_output

# End of Script
