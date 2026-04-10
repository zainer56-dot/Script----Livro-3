#!/usr/bin/ksh
#
# SCRIPT: enable_AIX_classic.ksh
#
# AUTHOR: Zainer Araujo
# DATE: 14/03/2025
# REV: 1.1.P
#
# PLATFORM: AIX
#
# PURPOSE:
#   Habilitar automaticamente filas de impressão que estejam DOWN
#   em sistemas AIX.
#
# REV LIST:
# set -x  # Descomente para depuração
# set -n  # Descomente para verificar sintaxe sem executar
#

# Percorre todas as filas de impressão que estão DOWN
for Q in $( enq -AW | tail +3 | grep DOWN | awk '{print $1}' )
do
  enable "$Q"

  if [ $? -ne 0 ]; then
    echo "\nA fila de impressão $Q NÃO conseguiu ser habilitada.\n"
  else
    echo "Fila de impressão $Q habilitada com sucesso."
  fi
done

exit 0
