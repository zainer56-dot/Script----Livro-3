#!/usr/bin/ksh
#
# SCRIPT: AIX_paging_mon.ksh
#
# AUTHOR: Zainer Araujo
# DATE: 05/11/2025
# REV: 1.1.P
#
# PLATFORM: AIX ONLY
#
# PURPOSE:
#   Produz um relatório de paging space do sistema AIX, incluindo:
#   - Total de paging space em MB
#   - MB de paging space usado
#   - MB de paging space livre
#   - % de paging space usado
#   - % de paging space livre
#

###########################################################
################ DEFINE VARIABLES HERE ####################
###########################################################

PC_LIMIT=65                       # Limite percentual superior
THISHOST=$(hostname)              # Nome do host
PAGING_STAT="/tmp/paging_stat.out"

###########################################################
################ INITIALIZE THE REPORT ####################
###########################################################

print
print "Paging Space Report for $THISHOST"
print
date
print

###########################################################
############# CAPTURE AND PROCESS THE DATA ################
###########################################################

# Captura os dados removendo o cabeçalho
lsps -s | tail +2 > "$PAGING_STAT"

# Loop principal
while read TOTAL PERCENT
do
    # Remover sufixos "MB" e "%"
    PAGING_MB=${TOTAL%MB}
    PAGING_PC=${PERCENT%\%}

    # Garantir que os valores são numéricos
    typeset -i PAGING_MB PAGING_PC

    # Calcular dados derivados
    (( PAGING_PC_FREE = 100 - PAGING_PC ))
    (( MB_USED = PAGING_MB * PAGING_PC / 100 ))
    (( MB_FREE = PAGING_MB - MB_USED ))

    #######################################################
    # OUTPUT
    #######################################################

    print "Total MB of Paging Space:        ${PAGING_MB}MB"
    print "Total MB of Paging Space Used:   ${MB_USED}MB"
    print "Total MB of Paging Space Free:   ${MB_FREE}MB"
    print
    print "Percent of Paging Space Used:    ${PAGING_PC}%"
    print "Percent of Paging Space Free:    ${PAGING_PC_FREE}%"
    print

    #######################################################
    # LIMIT CHECK
    #######################################################

    if (( PAGING_PC >= PC_LIMIT ))
    then
        tput smso
        print "WARNING: Paging Space has exceeded the ${PC_LIMIT}% upper limit!"
        tput rmso
        print
    fi

done < "$PAGING_STAT"

###########################################################
######################## CLEANUP ##########################
###########################################################

rm -f "$PAGING_STAT"
print
