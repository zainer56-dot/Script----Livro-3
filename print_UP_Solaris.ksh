#!/bin/ksh
#
# SCRIPT: print_UP_Solaris.ksh
#
# AUTHOR: Zainer Araujo
# DATE: 03/11/2025
# REV: 1.1.P
#
# PLATFORM: Apenas Solaris
#
# PURPOSE:
#   Este script habilita impressão e enfileiramento separadamente
#   em cada fila de impressão em sistemas Solaris.
#
# REV LIST:
# set -x  # Descomente para depurar
# set -n  # Descomente para verificar a sintaxe sem executar nada
#
#################################################

LOOP=0
# Contador de loop – para capturar três linhas por vez

lpc status all | egrep ':|printing|queueing' | while read LINE
do
  # Carrega três linhas únicas por vez
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

  # Incrementa o contador LOOP
  (( LOOP = LOOP + 1 ))

  if (( LOOP == 3 ))  # Temos todas as três linhas de dados?
  then
    # Verifica o status da impressão
    case "$PSTATUS" in
      disabled)
        lpc start "$Q" >/dev/null
        if (( $? == 0 )); then
          echo "\n$Q impressão reiniciada\n"
        fi
        ;;
      enabled|*) 
        :  # No-Op – Não faz nada
        ;;
    esac

    # Verifica o status do enfileiramento
    case "$QSTATUS" in
      disabled)
        lpc enable "$Q" >/dev/null
        if (( $? == 0 )); then
          echo "\n$Q enfileiramento reabilitado\n"
        fi
        ;;
      enabled|*)
        :  # No-Op – Não faz nada
        ;;
    esac

    # Reinicia o contador do loop para zero
    LOOP=0
  fi
done

exit 0
