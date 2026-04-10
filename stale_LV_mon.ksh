#!/bin/ksh
#
# SCRIPT: stale_LV_mon.ksh
#
# AUTHOR: Zainer Araujo
# DATE: 01/12/2025
# REV: 1.2.P
#
# PLATFORM: AIX ONLY
#
# PURPOSE:
#   Este shell script consulta o sistema AIX em busca de
#   stale Physical Partitions (PPs) em todos os Logical Volumes
#   ativos pertencentes a todos os Volume Groups ativos.
#
# set -x  # Descomente para debugar este script
# set -n  # Descomente para checar a sintaxe sem executar nada
#

###################################################
############# DEFINIR VARIÁVEIS AQUI ###############
###################################################

THIS_HOST=$(hostname)     # Hostname da máquina
STALE_LV_COUNT=0          # Contador de LVs com stale PP

###################################################
############# COLETA DOS VGs ATIVOS ################
###################################################

echo
echo "Coletando lista de Volume Groups ativos..."
ACTIVE_VG_LIST=$(lsvg -o)

###################################################
############# PROCESSAMENTO DOS LVs ################
###################################################

echo
echo "Percorrendo Logical Volumes ativos em cada VG"
echo "...isso pode levar alguns minutos, por favor aguarde..."
echo

for VG in $ACTIVE_VG_LIST
do
    echo "Verificando VG: $VG"

    # Listar LVs ativos (estado OPEN) do VG atual
    lsvg -l $VG | awk '$6 == "open" {print $1}' | while read LV
    do
        # Extrair o número de stale PPs do LV
        NUM_STALE_PP=$(lslv -L $LV 2>/dev/null \
            | awk '/STALE PP/ {print $3}')

        # Garantir valor numérico
        [[ -z "$NUM_STALE_PP" ]] && NUM_STALE_PP=0

        if (( NUM_STALE_PP > 0 ))
        then
            (( STALE_LV_COUNT = STALE_LV_COUNT + 1 ))
            echo "  ${THIS_HOST}: VG=${VG} LV=${LV} possui ${NUM_STALE_PP} stale PPs"
        fi
    done
done

###################################################
################# RESULTADO FINAL ##################
###################################################

if (( STALE_LV_COUNT == 0 ))
then
    echo
    echo "Nenhum stale PP foi encontrado em qualquer LV ativo."
    echo
else
    echo
    echo "Total de Logical Volumes com stale PPs: ${STALE_LV_COUNT}"
    echo
fi

exit 0
