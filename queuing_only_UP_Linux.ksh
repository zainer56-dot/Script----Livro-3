#!/bin/ksh
#
# SCRIPT: queuing_only_UP_Linux.ksh
#
# AUTHOR: Zainer Araujo
# DATE: 03/11/2025
# REV: 1.1.P
#
# PLATFORM: Somente Linux
#
# PURPOSE:
#   Este script é usado para habilitar SOMENTE o enfileiramento (queueing)
#   em cada fila de impressão em um sistema Linux.
#   O registro (logging) pode ser habilitado.
#
# REV LIST:
# set -x  # Descomente para depurar
# set -n  # Descomente para verificar a sintaxe sem executar
#
#################################################
# Variáveis iniciais
#################################################
LOGFILE="/usr/local/log/PQlog.log"

# Garante que o arquivo de log exista
[ -f "$LOGFILE" ] || : > "$LOGFILE"

#################################################
# Processa o status das filas de impressão
#################################################
lpc status | tail +2 | while read QUEUE PRINTSTAT QUEUESTAT JUNK
do
  #################################################
  # Verifica SOMENTE o status de enfileiramento
  #################################################
  case "$QUEUESTAT" in
    disabled)
      echo "$QUEUE Queueing is $QUEUESTAT" | tee -a "$LOGFILE"
      lpc enable "$QUEUE" | tee -a "$LOGFILE"
      if [ $? -eq 0 ]
      then
        echo "$QUEUE Queueing Re-enabled" | tee -a "$LOGFILE"
      fi
      ;;
    enabled|*)
      :   # No-Op
      ;;
  esac
done

exit 0
