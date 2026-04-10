#!/bin/bash
#
# SCRIPT: uptime_loadmon.sh
# AUTHOR: Zainer Araujo
# DATE: 12/11/2025
# REV: 1.1.P
# PLATFORM: AIX, HP-UX, Linux, OpenBSD, Solaris
#
# PURPOSE:
#   Usa o comando "uptime" para extrair o load average
#   (número médio de jobs na run queue) e compara com
#   um threshold configurável.
#
# set -x  # Descomente para debugar
# set -n  # Descomente para checar sintaxe sem executar
#

###################################################
############# DEFINIR VARIÁVEIS AQUI ###############
###################################################

MAXLOAD="2.00"      # Threshold de warning
MAXLOAD_INT=${MAXLOAD%.*}
MAXLOAD_DEC=${MAXLOAD#*.}

###################################################
# DEFINIR INTERVALOS DE LOAD POR UNIX FLAVOR
###################################################

case $(uname) in
    AIX)
        L1=5
        L2=10
        L3=15
        ;;
    *)
        L1=1
        L2=5
        L3=15
        ;;
esac

###################################################
############### INÍCIO DO MAIN ####################
###################################################

echo
echo "Coletando System Load Average usando o comando \"uptime\""
echo

# Extrair somente a parte do load average (robusto)
LOADS=$(uptime | awk -F'load average: ' '{print $2}' | sed 's/,//g')

if [[ -z "$LOADS" ]]; then
    echo "ERRO: Não foi possível extrair o load average"
    exit 2
fi

set -- $LOADS
LAST1=$1
LAST5=$2
LAST15=$3

###################################################
############### CHECK DO THRESHOLD ################
###################################################

INT=${LAST1%.*}
DEC=${LAST1#*.}

WARNING=0

if (( INT > MAXLOAD_INT )); then
    WARNING=1
elif (( INT == MAXLOAD_INT )) && (( DEC >= MAXLOAD_DEC )); then
    WARNING=1
fi

###################################################
#################### OUTPUT #######################
###################################################

if (( WARNING == 1 )); then
    echo
    echo "WARNING: System load atingiu ${LAST1}"
    echo
fi

echo "System load average para os últimos ${L1} minutes  : ${LAST1}"
echo "System load average para os últimos ${L2} minutes  : ${LAST5}"
echo "System load average para os últimos ${L3} minutes  : ${LAST15}"
echo
echo "Load threshold configurado: ${MAXLOAD}"
echo
