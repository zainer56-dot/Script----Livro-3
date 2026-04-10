#!/bin/ksh
#
# SCRIPT: print_UP_Linux.ksh
#
# AUTHOR: Zainer Araujo
# DATE: 03/11/2025
# REV: 1.1.P
#
# PLATFORM: Somente Linux
#
# PURPOSE:
#   Habilitar impressão (printing) e enfileiramento (queueing)
#   separadamente em cada fila de impressão em sistemas Linux.
#   O registro (logging) pode ser habilitado.
#
# REV LIST:
# set -x  # Descomente para depurar
# set -n  # Descomente para verificar sintaxe sem executar
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
  # Verifica status de impressão
  #################################################
  case "$PRINTSTAT" in
    disabled)
      echo "$QUEUE Printing is $PRINTSTAT" | tee -a "$LOGFILE"
      lpc start "$QUEUE" | tee -a "$LOGFILE"
      if [ $? -eq 0 ]
      then
        echo "$QUEUE Printing Restarted" | tee -a "$LOGFILE"
      fi
      ;;
    enabled|*)
      :   # No-Op
      ;;
  esac

  #################################################
  # Verifica status de enfileiramento
  #################################################
  case "$QUEUESTAT" in
    disabled)
      echo "$QUEUE Queueing is $QUEUESTAT" | tee -a "$LOGFILE"
      lpc enable "$QUEUE" | tee -a "$LOGFILE"
      if [ $? -eq 0 ]
      then
        echo "$QUEUE Queueing Restarted" | tee -a "$LOGFILE"
      fi
      ;;
    enabled|*)
      :   # No-Op
      ;;
  esac
done

exit 0
