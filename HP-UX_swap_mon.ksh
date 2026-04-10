#!/usr/bin/ksh
#
# SCRIPT: HP-UX_swap_mon.ksh
#
# AUTHOR: Zainer
# DATE: 05/31/2007
# REV: 1.1.P
#
# PLATFORM: HP-UX ONLY
#
# PURPOSE:
#   Produz um relatório de swap space do sistema HP-UX, incluindo:
#   - Total de swap em MB
#   - MB de swap usado
#   - MB de swap livre
#   - % de swap usado
#   - % de swap livre
#

###########################################################
################ DEFINE VARIABLES HERE ####################
###########################################################

PC_LIMIT=65                    # Limite percentual superior
THISHOST=$(hostname)           # Nome do host

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

# swapinfo -tm gera saída agregada por dispositivo
swapinfo -tm | grep dev | while read JUNK SW_TOTAL SW_USED SW_FREE PERCENT_USED JUNK2
do
    # Remover o sufixo "%"
    PERCENT_USED_NUM=${PERCENT_USED%\%}

    # Garantir valores inteiros
    typeset -i PERCENT_USED_NUM
    typeset -i PERCENT_FREE

    (( PERCENT_FREE = 100 - PERCENT_USED_NUM ))

    #######################################################
    # OUTPUT
    #######################################################

    print "Total Amount of Swap Space:      ${SW_TOTAL}MB"
    print "Total MB of Swap Space Used:     ${SW_USED}MB"
    print "Total MB of Swap Space Free:     ${SW_FREE}MB"
    print
    print "Percent of Swap Space Used:      ${PERCENT_USED_NUM}%"
    print "Percent of Swap Space Free:      ${PERCENT_FREE}%"
    print

    #######################################################
    # LIMIT CHECK
    #######################################################

    if (( PERCENT_USED_NUM >= PC_LIMIT ))
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
