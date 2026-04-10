#!/bin/ksh
#
# SCRIPT: printing_only_UP_Linux.ksh
#
# AUTHOR: Zainer Araujo
# DATE: 03/11/2025
# REV: 1.1.P
#
# PLATFORM: Somente Linux
#
# PURPOSE: Este script é usado para habilitar a impressão em cada impressora
#
em um sistema Linux. O registro (logging) está habilitado.
#
# REV LIST:
#
# set-x # Descomente para depurar este script
# set-n # Descomente para verificar a sintaxe sem executar nada
#
#################################################
# Variáveis iniciais aqui
#################################################
LOGILE=/usr/local/log/PQlog.log
[-f $LOGFILE ] || echo /dev/null > $LOGFILE
#################################################
lpc status | tail +2 | while read pqstat[1] pqstat[2] pqstat[3] junk
do
# Verifica o status da impressão para cada impressora
case ${pqstat[2]} in
disabled)
# A impressão está desativada – exibe o status e reinicia a impressão
echo "${pqstat[1]} Printing is ${pqstat[2]}" \
| tee-a$LOGFILE
lpc start ${pqstat[1]} | tee-a $LOGFILE
(($? == 0)) && echo "${pqstat[1]} Printing Restarted" \
| tee-a $LOGFILE
;;
enabled|*) : # No-Op – Não faz nada
;;
esac
done
