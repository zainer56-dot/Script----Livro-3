#!/bin/ksh
#
# SCRIPT: print_UP_HP-UX.ksh
#
# AUTHOR: Zainer Araujo
# DATE: 03/11/2025
# REV: 1.1.P
#
# PLATFORM: Somente HP-UX
#
# PURPOSE:
#   Habilitar impressão (printing) e enfileiramento (queueing)
#   separadamente em cada fila de impressão em sistemas HP-UX.
#
# REV LIST:
# set -x  # Descomente para depurar
# set -n  # Descomente para verificar sintaxe sem executar
#
############################################################

lpstat | grep "Warning:" | while read LINE
do
  QUEUE=$(echo "$LINE" | awk '{print $3}')

  # Se a impressora estiver DOWN, habilita a impressão
  echo "$LINE" | grep "is down" >/dev/null 2>&1
  if [ $? -eq 0 ]
  then
    enable "$QUEUE" >/dev/null 2>&1
    if [ $? -eq 0 ]
    then
      echo "\n$QUEUE: impressão habilitada"
    fi
  fi

  # Se o enfileiramento estiver desabilitado, reativa
  echo "$LINE" | grep "queue is turned off" >/dev/null 2>&1
  if [ $? -eq 0 ]
  then
    accept "$QUEUE" >/dev/null 2>&1
    if [ $? -eq 0 ]
    then
      echo "$QUEUE: enfileiramento reativado"
    fi
  fi
done

exit 0
