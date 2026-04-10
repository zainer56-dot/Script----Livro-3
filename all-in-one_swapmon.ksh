#!/usr/bin/ksh
#
# SCRIPT: all-in-one_swapmon.ksh
#
# AUTHOR: Zainer Araujo
# DATE: 05/11/2025
# REV: 3.1.P
#
# PLATFORM: AIX, Solaris, HP-UX, Linux, OpenBSD
#
# PURPOSE:
#   Produz um relatório de paging/swap space contendo:
#     - Total em MB
#     - MB usados
#     - MB livres
#     - % usado
#     - % livre
#

###########################################################
################ DEFINE VARIABLES HERE ####################
###########################################################

PC_LIMIT=65
THISHOST=$(hostname)

###########################################################
################ INITIALIZE REPORT ########################
###########################################################

print
print "Swap / Paging Space Report for $THISHOST"
print
date
print

###########################################################
################ SOLARIS ##################################
###########################################################
SUN_swap_mon()
{
    set -- $(swap -s | awk -F'[ ,]+' '
        {
            for (i=1;i<=NF;i++) {
                if ($i ~ /used$/) u=$(i-1)
                if ($i ~ /available$/) f=$(i-1)
            }
            print u, f
        }')

    SW_USED=$1
    SW_FREE=$2

    (( SW_TOTAL = SW_USED + SW_FREE ))
    (( PC_USED = (SW_USED * 100) / SW_TOTAL ))
    (( PC_FREE = 100 - PC_USED ))

    (( SW_TOTAL_MB = SW_TOTAL / 1024 ))
    (( SW_USED_MB  = SW_USED  / 1024 ))
    (( SW_FREE_MB  = SW_FREE  / 1024 ))

    print "Total Swap Space:          ${SW_TOTAL_MB}MB"
    print "Swap Space Used:           ${SW_USED_MB}MB"
    print "Swap Space Free:           ${SW_FREE_MB}MB"
    print
    print "Percent Used:              ${PC_USED}%"
    print "Percent Free:              ${PC_FREE}%"
    print

    (( PC_USED >= PC_LIMIT )) && {
        tput smso
        print "WARNING: Swap usage exceeded ${PC_LIMIT}%!"
        tput rmso
        print
    }
}

###########################################################
################ LINUX ####################################
###########################################################
Linux_swap_mon()
{
    free -m | awk '/^Swap:/ {
        total=$2; used=$3; free=$4
        pc_used=(used*100)/total
        pc_free=100-pc_used

        printf "Total Swap Space:          %dMB\n", total
        printf "Swap Space Used:           %dMB\n", used
        printf "Swap Space Free:           %dMB\n\n", free
        printf "Percent Used:              %d%%\n", pc_used
        printf "Percent Free:              %d%%\n\n", pc_free

        if (pc_used >= limit)
            system("tput smso; echo WARNING: Swap usage exceeded " limit "%!; tput rmso")
    }' limit=$PC_LIMIT
}

###########################################################
################ HP-UX ####################################
###########################################################
HP_UX_swap_mon()
{
    swapinfo -tm | awk '/dev/ {
        pc_used=$5
        gsub("%","",pc_used)
        pc_free=100-pc_used

        printf "Total Swap Space:          %sMB\n", $2
        printf "Swap Space Used:           %sMB\n", $3
        printf "Swap Space Free:           %sMB\n\n", $4
        printf "Percent Used:              %s\n", $5
        printf "Percent Free:              %d%%\n\n", pc_free

        if (pc_used >= limit)
            system("tput smso; echo WARNING: Swap usage exceeded " limit "%!; tput rmso")
    }' limit=$PC_LIMIT
}

###########################################################
################ AIX ######################################
###########################################################
AIX_paging_mon()
{
    lsps -s | tail +2 | while read TOTAL USED_PC
    do
        TOTAL_MB=${TOTAL%MB}
        PC_USED=${USED_PC%\%}

        (( MB_USED = TOTAL_MB * PC_USED / 100 ))
        (( MB_FREE = TOTAL_MB - MB_USED ))
        (( PC_FREE = 100 - PC_USED ))

        print "Total Paging Space:        ${TOTAL_MB}MB"
        print "Paging Space Used:         ${MB_USED}MB"
        print "Paging Space Free:         ${MB_FREE}MB"
        print
        print "Percent Used:              ${PC_USED}%"
        print "Percent Free:              ${PC_FREE}%"
        print

        (( PC_USED >= PC_LIMIT )) && {
            tput smso
            print "WARNING: Paging space exceeded ${PC_LIMIT}%!"
            tput rmso
            print
        }
    done
}

###########################################################
################ OPENBSD ##################################
###########################################################
OpenBSD_swap_mon()
{
    swapctl -lk | tail +2 | awk '
    {
        total=$2/1024
        used=$3/1024
        free=$4/1024
        pc_used=$5
        gsub("%","",pc_used)
        pc_free=100-pc_used

        printf "Total Paging Space:        %dMB\n", total
        printf "Paging Space Used:         %dMB\n", used
        printf "Paging Space Free:         %dMB\n\n", free
        printf "Percent Used:              %d%%\n", pc_used
        printf "Percent Free:              %d%%\n\n", pc_free

        if (pc_used >= limit)
            system("tput smso; echo WARNING: Paging usage exceeded " limit "%!; tput rmso")
    }' limit=$PC_LIMIT
}

###########################################################
################ MAIN #####################################
###########################################################
case $(uname) in
    AIX)     AIX_paging_mon ;;
    HP-UX)   HP_UX_swap_mon ;;
    Linux)   Linux_swap_mon ;;
    SunOS)   SUN_swap_mon ;;
    OpenBSD) OpenBSD_swap_mon ;;
    *)
        print "ERROR: Unsupported Operating System"
        exit 1
        ;;
esac

print
