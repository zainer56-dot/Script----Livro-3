#!/usr/bin/ksh
#
# SCRIPT: linux_swap_mon.ksh
#
# AUTHOR: Zainer Araujo
# DATE: 05/11/2025
# REV: 1.1.P
#
# PLATFORM: Linux ONLY
#
# PURPOSE:
#   Produz um relatório de swap space do sistema Linux, incluindo:
#   - Total de swap em MB
#   - MB de swap usado
#   - MB de swap livre
#   - % de swap usado
#   - % de swap livre
#

###########################################################
################ DEFINE VARIABLES HERE ####################
###########################################################

THISHOST=$(hostname)    # Nome da máquina
PC_LIMIT=65             # Limite percentual superior de swap

###########################################################
################ INITIALIZE THE REPORT ####################
###########################################################

print
print "Swap Space Report for $THISHOST"
print
date
print

###########################################################
############# CAPTURE AND PROCESS THE DATA ################
###########################################################

# Captura os dados de swap em MB
free -m | awk '/^Swap:/ {print $2, $3, $4}' | while read SW_TOTAL SW_USED SW_FREE
do
    # Garantir variáveis inteiras
    typeset -i SW_TOTAL SW_USED SW_FREE
    typeset -i PERCENT_USED PERCENT_FREE

    # Evitar divisão por zero
    if (( SW_TOTAL == 0 ))
    then
        print "No swap space configured on this system."
        continue
    fi

    #######################################################
    # CALCULATIONS
    #######################################################

    (( PERCENT_USED = (SW_USED * 100) / SW_TOTAL ))
    (( PERCENT_FREE = 100 - PERCENT_USED ))

    #######################################################
    # OUTPUT
    #######################################################

    print "Total Amount of Swap Space:      ${SW_TOTAL}MB"
    print "Total MB of Swap Space Used:     ${SW_USED}MB"
    print "Total MB of Swap Space Free:     ${SW_FREE}MB"
    print
    print "Percent of Swap Space Used:      ${PERCENT_USED}%"
    print "Percent of Swap Space Free:      ${PERCENT_FREE}%"
    print

    #######################################################
    # LIMIT CHECK
    #######################################################

    if (( PERCENT_USED >= PC_LIMIT ))
    then
        tput smso
        print "WARNING: Swap Space has exceeded the ${PC_LIMIT}% upper limit!"
        tput rmso
        print
    fi
done

###########################################################
######################## END ##############################
###########################################################

print
