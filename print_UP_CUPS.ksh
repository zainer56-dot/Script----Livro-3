#!/usr/bin/ksh
#
# SCRIPT: print_UP_CUPS.ksh
#
# AUTHOR: Zainer Araujo
# DATE: 08/11/2025
# REV: 2.1.P
#
# PLATFORM: QUALQUER SISTEMA EXECUTANDO O DAEMON CUPS
#
# PURPOSE:
#   Habilitar impressão (printing) e enfileiramento (queuing)
#   separadamente para cada fila de impressão via CUPS.
#
# REV LIST:
# set -x  # Descomente para depurar
# set -n  # Descomente para verificar sintaxe sem executar
#
#################################################

LOOP=0
Q=""
PSTATUS=""
QSTATUS=""

# Captura 3 linhas por fila: nome, printing, queuing
lpc status all | egrep ':|printing|queuing' | while read LINE
do
  case "$LINE" in
    *:)
      Q=$(echo "$LINE" | cut -d':' -f1)
      ;;
    printing*)
      PSTATUS=$(echo "$LINE" | awk '{print $3}')
      ;;
    queuing*)
      QSTATUS=$(echo "$LINE" | awk '{print $3}')
      ;;
  esac

  # Incrementa o contador
  (( LOOP = LOOP + 1 ))

  # Já temos as três linhas da fila
  if (( LOOP == 3 ))
  then
    # Verifica o status de impressão
    case "$PSTATUS" in
      disabled)
        cupsenable "$Q" >/dev/null 2>&1
        if [ $? -eq 0 ]; then
          echo "\n$Q: impressão reiniciada"
        fi
        sleep 1
        ;;
      enabled|*)
        :   # No-op
        ;;
    esac

    # Verifica o status de enfileiramento
    case "$QSTATUS" in
      disabled)
        accept "$Q" >/dev/null 2>&1
        if [ $? -eq 0 ]; then
          echo "$Q: enfileiramento reativado\n"
        fi
        ;;
      enabled|*)
        :   # No-op
        ;;
    esac

    # Reseta para a próxima fila
    LOOP=0
    Q=""
    PSTATUS=""
    QSTATUS=""
  fi
done

exit 0
