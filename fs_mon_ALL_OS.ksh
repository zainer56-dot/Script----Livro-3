#!/usr/bin/ksh
#
# SCRIPT: fs_mon_ALL_OS.ksh
# AUTHOR: Zainer Araujo
# REV: 6.0.P
#

#############################
# DEFAULT THRESHOLDS
#############################
MIN_MB_FREE="100MB"
MAX_PERCENT="85%"
FSTRIGGER="1000MB"

WORKFILE="/tmp/df.work"
OUTFILE="/tmp/df.outfile"
EXCEPTIONS="/usr/local/bin/exceptions"
DATA_EXCEPTIONS="/tmp/dfdata.out"
EXCEPT_FILE="N"
THISHOST=$(hostname)

> "$WORKFILE"
> "$OUTFILE"

#############################
# FORMAT VALUES (KB)
#############################
(( MIN_MB_FREE = ${MIN_MB_FREE%MB} * 1024 ))
(( FSTRIGGER   = ${FSTRIGGER%MB}   * 1024 ))

#############################
# OS DETECTION
#############################
get_OS_info() {
    uname | tr '[:lower:]' '[:upper:]'
}

#############################
# LOAD FILESYSTEM DATA
#############################
load_AIX_FS_data() {
    df -k | tail +2 | egrep -v '/dev/cd[0-9]|/proc' \
    | awk '{print $1,$2,$3,$4,$7}' > "$WORKFILE"
}

load_HP_UX_FS_data() {
    bdf | tail +2 | egrep -v '/cdrom' \
    | awk '{print $1,$2,$4,$5,$6}' > "$WORKFILE"
}

load_LINUX_FS_data() {
    df -k | tail +2 | egrep -v '/cdrom' \
    | awk '{print $1,$2,$4,$5,$6}' > "$WORKFILE"
}

load_OpenBSD_FS_data() {
    df -k | tail +2 | egrep -v '/mnt/cdrom' \
    | awk '{print $1,$2,$4,$5,$6}' > "$WORKFILE"
}

load_Solaris_FS_data() {
    df -k | tail +2 | egrep -v '/dev/fd|/etc/mnttab|/proc' \
    | awk '{print $1,$2,$4,$5,$6}' > "$WORKFILE"
}

#############################
# LOAD EXCEPTIONS
#############################
load_EXCEPTIONS_data() {
    grep -v '^#' "$EXCEPTIONS" | sed '/^$/d' > "$DATA_EXCEPTIONS"
}

#############################
# CHECK EXCEPTIONS
#############################
check_exceptions() {
    while read FSNAME FSLIMIT
    do
        FSNAME=${FSNAME#*:}

        [ -z "$FSLIMIT" ] && continue

        if [[ "$FSNAME" = "$FSMOUNT" ]]
        then
            case "$FSLIMIT" in
                *MB)
                    LIMIT=${FSLIMIT%MB}
                    (( LIMIT *= 1024 ))
                    (( FSMB_FREE < LIMIT )) && return 1 || return 3
                    ;;
                *%)
                    LIMIT=${FSLIMIT%\%}
                    (( PC_USED > LIMIT )) && return 2 || return 3
                    ;;
            esac
        fi
    done < "$DATA_EXCEPTIONS"

    return 4
}

#############################
# DISPLAY OUTPUT
#############################
display_output() {
    if [[ -s "$OUTFILE" ]]
    then
        echo
        echo "Full Filesystem(s) on $THISHOST"
        echo
        cat "$OUTFILE"
        echo
    fi
}

#############################
# MAIN
#############################
case $(get_OS_info) in
    AIX)     load_AIX_FS_data ;;
    HP-UX)   load_HP_UX_FS_data ;;
    LINUX)   load_LINUX_FS_data ;;
    OPENBSD) load_OpenBSD_FS_data ;;
    SUNOS)   load_Solaris_FS_data ;;
    *)
        echo "Unsupported OS"
        exit 1
        ;;
esac

if [[ -s "$EXCEPTIONS" ]]
then
    load_EXCEPTIONS_data
    EXCEPT_FILE="Y"
fi

while read FSDEVICE FSSIZE FSMB_FREE PC_USED FSMOUNT
do
    PC_USED=${PC_USED%\%}
    FSMB_FREE=${FSMB_FREE%MB}

    if [[ "$EXCEPT_FILE" = "Y" ]]
    then
        check_exceptions
        RC=$?

        case $RC in
            1)
                (( OUT = FSMB_FREE / 1000 ))
                echo "$FSDEVICE mounted on $FSMOUNT has ${OUT}MB Free" >> "$OUTFILE"
                ;;
            2)
                echo "$FSDEVICE mounted on $FSMOUNT is ${PC_USED}%" >> "$OUTFILE"
                ;;
            3) : ;;
            4)
                if (( FSSIZE >= FSTRIGGER ))
                then
                    (( FSMB_FREE < MIN_MB_FREE )) && \
                    echo "$FSDEVICE mounted on $FSMOUNT has $((FSMB_FREE/1000))MB Free" >> "$OUTFILE"
                else
                    (( PC_USED > ${MAX_PERCENT%\%} )) && \
                    echo "$FSDEVICE mounted on $FSMOUNT is ${PC_USED}%" >> "$OUTFILE"
                fi
                ;;
        esac
    else
        if (( FSSIZE >= FSTRIGGER ))
        then
            (( FSMB_FREE < MIN_MB_FREE )) && \
            echo "$FSDEVICE mounted on $FSMOUNT has $((FSMB_FREE/1000))MB Free" >> "$OUTFILE"
        else
            (( PC_USED > ${MAX_PERCENT%\%} )) && \
            echo "$FSDEVICE mounted on $FSMOUNT is ${PC_USED}%" >> "$OUTFILE"
        fi
    fi
done < "$WORKFILE"

display_output

# END
