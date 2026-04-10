#!/usr/bin/ksh
#
# SCRIPT: stale_PP_mon.ksh
#
# AUTHOR: Zainer Araujo
# DATE: 01/11/2025
# REV: 1.3.P
#
# PLATFORM: AIX ONLY
#
# PURPOSE:
#   Consultar o sistema AIX por stale Physical Partitions (PPs)
#   em todos os Physical Volumes pertencentes a Volume Groups
#   atualmente varied-on.
#
# set -x  # Descomente para debugar este script
# set -n  # Descomente para checar a sintaxe sem executar nada
#

###################################################
############# DEFINIR VARIÁVEIS AQUI ###############
###################################################

THIS_HOST=$(hostname)
HDISK_LIST=""
STALE_HDISK_LIST=""
STALE_PP_COUNT=0

###################################################
############# COLETAR HDisks ATIVOS ################
###################################################

echo
echo "Coletando lista de Volume Groups ativos..."

for VG in $(lsvg -o)
do
    echo "Consultando VG $VG para obter lista de hdisks"
    HDISK_LIST="$HDISK_LIST $(lsvg -p $VG | awk '/disk/ {print $1}')"
done

# Remover duplicados
HDISK_LIST=$(echo "$HDISK_LIST" | tr ' ' '\n' | sort -u)

###################################################
############# CONSULTAR STALE PPs ##################
###################################################

echo
echo "Iniciando consulta individual de hdisks"
echo

for HDISK in $HDISK_LIST
do
    echo "Consultando $HDISK por stale partitions..."

    NUM_STALE_PP=$(lspv -L $HDISK 2>/dev/null \
        | awk '/STALE PARTITIONS/ {print $3}')

    [[ -z "$NUM_STALE_PP" ]] && NUM_STALE_PP=0

    if (( NUM_STALE_PP > 0 ))
    then
        (( STALE_PP_COUNT = STALE_PP_COUNT + NUM_STALE_PP ))
        STALE_HDISK_LIST="$STALE_HDISK_LIST $HDISK"

        echo "  ${THIS_HOST}: $HDISK possui ${NUM_STALE_PP} stale partitions"
    fi
done

###################################################
################ RESULTADO FINAL ###################
###################################################

if (( STALE_PP_COUNT == 0 ))
then
    echo
    echo "${THIS_HOST}: Nenhum stale PP foi encontrado no sistema."
    echo
else
    echo
    echo "Resumo:"
    echo "  Total de stale PPs encontrados: ${STALE_PP_COUNT}"
    echo "  HDisks afetados: ${STALE_HDISK_LIST}"
    echo
fi

exit 0
