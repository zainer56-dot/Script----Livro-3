#!/usr/bin/ksh
#
# SCRIPT: SUN_swap_mon.ksh
#
# AUTHOR: Zainer Araujo
# DATE: 05/11/2025
# REV: 1.2.P
#
# PLATFORM: Solaris ONLY
#
# PURPOSE:
#   Produz um relatório de swap space do sistema Solaris:
#   - Total em MB
#   - MB usados
#   - MB livres
#   - % usado
#   - % livre
#

###########################################################
################ DEFINE VARIABLES HERE ####################
###########################################################

PC_LIMIT=65
THISHOST=$(hostname)

###########################################################
################ INITIALIZE THE REPORT ####################
###########################################################

print
print "Swap Space Report for $THISHOST"
print
date
print

###########################################################
############# CAPTURE AND PROCESS DATA ####################
###########################################################

# Captura os valores de swap em KB a partir do swap -s
set -- $(swap -s | \
    awk -F'[ ,]+' '
        {
            for (i=1; i<=NF; i++) {
                if ($i ~ /used$/)      used=$(i-1)
                if ($i ~ /available$/) free=$(i-1)
            }
            print used, free
        }')

SW_USED=$1
SW_FREE=$2

# Sanity check
if [[ -z "$SW_USED" || -z "$SW_FREE" ]]
then
    print "ERROR: Unable to determine swap usage."
    exit 1
fi

###########################################################
# CALCULATIONS
###########################################################

(( SW_TOTAL = SW_USED + SW_FREE ))

(( SW_TOTAL_MB = SW_TOTAL / 1024 ))
(( SW_USED_MB  = SW_USED  / 1024 ))
(( SW_FREE_MB  = SW_FREE  / 1024 ))

(( PC_USED = (SW_USED * 100) / SW_TOTAL ))
(( PC_FREE = 100 - PC_USED ))

###########################################################
# OUTPUT
###########################################################

print "Total Amount of Swap Space:        ${SW_TOTAL_MB}MB"
print "Total MB of Swap Space Used:       ${SW_USED_MB}MB"
print "Total MB of Swap Space Free:       ${SW_FREE_MB}MB"
print
print "Percent of Swap Space Used:        ${PC_USED}%"
print "Percent of Swap Space Free:        ${PC_FREE}%"
print

###########################################################
# LIMIT CHECK
###########################################################

if (( PC_USED >= PC_LIMIT ))
then
    tput smso
    print "WARNING: Swap Space has exceeded the ${PC_LIMIT}% upper limit!"
    tput rmso
    print
fi

print
