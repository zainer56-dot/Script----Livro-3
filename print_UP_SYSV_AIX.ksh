#!/usr/bin/ksh
#
# SCRIPT: print_UP_SYSV_AIX.ksh
#
# AUTHOR: Zainer Araujo
# DATE: 03/11/2025
# REV: 1.1.P
#
# PLATFORM: AIX / Solaris (System V Printing)
#
# PURPOSE:
#   Habilitar impressão (printing) e enfileiramento (queueing)
#   separadamente para cada fila de impressão.
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

# Captura 3 linhas por fila: nome, printing, queueing
lpc status all | egrep ':|printing|queueing' | while read LINE
do
  case "$LINE" in
    *:)
      Q=$(echo "$LINE" | cut -d':' -f1)
      ;;
    printing*)
      PSTATUS=$(echo "$LINE" | awk '{print $3}')
      ;;
    queueing*)
      QSTATUS=$(echo "$LINE" | awk '{print $3}')
      ;;
  esac

  # Incrementa o contador
  (( LOOP = LOOP + 1 ))

  # Já temos as 3 linhas da fila
  if (( LOOP == 3 ))
  then
    # Verifica status de impressão
    case "$PSTATUS" in
      disabled)
        lpc start "$Q" >/dev/null 2>&1
        if [ $? -eq 0 ]; then
          echo "\n$Q: impressão reiniciada"
        fi
        ;;
      enabled|*)
        :   # No-op
        ;;
    esac

    # Verifica status de enfileiramento
    case "$QSTATUS" in
      disabled)
        lpc enable "$Q" >/dev/null 2>&1
        if [ $? -eq 0 ]; then
          echo "$Q: enfileiramento reativado\n"
        fi
        ;;
      enabled|*)
        :   # No-op
        ;;
    esac

    # Reseta variáveis para próxima fila
    LOOP=0
    Q=""
    PSTATUS=""
    QSTATUS=""
  fi
done

exit 0
