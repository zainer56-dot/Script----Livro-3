#!/bin/ksh
#
# SCRIPT: sar_loadmon.ksh
# AUTHOR: Zainer Araujo
# DATE: 11/10/2025
# REV: 1.1.P
# PLATFORM: AIX, HP-UX, Linux, Solaris
#
# PURPOSE:
#   Este shell script coleta múltiplas amostras
#   de uso de CPU usando o comando sar.
#   A média dos sample periods é exibida ao usuário
#   de acordo com o UNIX flavor em execução.
#
# set -n  # Descomente para verificar a sintaxe sem executar
# set -x  # Descomente para debugar este shell script
#

###################################################
############# DEFINIR VARIÁVEIS AQUI ###############
###################################################

SECS=30          # Número de segundos por sample
INTERVAL=10      # Número total de sampling intervals
OS=$(uname)      # UNIX flavor

###################################################
##### CONFIGURAR O AMBIENTE PARA CADA OS AQUI ######
###################################################
# Estes valores apontam para os fields corretos
# no output do comando sar para cada UNIX flavor

case $OS in
    AIX|HP-UX|SunOS)
        F1=2
        F2=3
        F3=4
        F4=5
        ;;
    Linux)
        F1=3
        F2=5
        F3=6
        F4=7
        ;;
    *)
        echo
        echo "ERRO: $OS não é um operating system suportado"
        echo "...SAINDO..."
        echo
        exit 1
        ;;
esac

echo
echo "Operating System detectado: $OS"
echo

###################################################
######## INICIAR COLETA DE ESTATÍSTICAS AQUI ######
###################################################

echo "Coletando CPU Statistics usando sar..."
echo "Existem $INTERVAL sampling periods"
echo "Cada interval dura $SECS seconds"
echo
echo "...Por favor, aguarde enquanto as estatísticas são coletadas..."
echo

###################################################
############# COLETA E PROCESSAMENTO ##############
###################################################

sar $SECS $INTERVAL | grep Average \
| awk '{print $'"$F1"', $'"$F2"', $'"$F3"', $'"$F4"'}' \
| while read FIRST SECOND THIRD FOURTH
do
    case $OS in
        AIX|HP-UX|SunOS)
            echo
            echo "User part   : ${FIRST}%"
            echo "System part : ${SECOND}%"
            echo "I/O Wait    : ${THIRD}%"
            echo "Idle time   : ${FOURTH}%"
            echo
            ;;
        Linux)
            echo
            echo "User part   : ${FIRST}%"
            echo "Nice part  : ${SECOND}%"
            echo "System part: ${THIRD}%"
            echo "Idle time  : ${FOURTH}%"
            echo
            ;;
    esac
done
