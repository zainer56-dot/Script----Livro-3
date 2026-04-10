#!/bin/ksh
#
# SCRIPT: iostat_loadmon.ksh
# AUTHOR: Zainer Araujo
# DATE: 12/10/2025
# REV: 1.1.P
# PLATFORM: AIX, HP-UX, Linux, OpenBSD, Solaris
#
# PURPOSE:
#   Este shell script coleta duas amostras de uso de CPU
#   usando o comando iostat.
#
#   A primeira amostra representa a média desde o último reboot.
#   A segunda amostra representa a média durante o sampling period
#   definido por SECS e INTERVAL.
#
# set -n  # Descomente para verificar a sintaxe sem executar
# set -x  # Descomente para debugar este shell script
#

###################################################
############# DEFINIR VARIÁVEIS AQUI ###############
###################################################

SECS=300        # Número de segundos por sample
INTERVAL=2      # Número total de sampling intervals
STATCOUNT=0     # Loop counter
OS=$(uname)     # UNIX flavor

###################################################
##### CONFIGURAR O AMBIENTE PARA CADA OS AQUI ######
###################################################
# Os F-numbers apontam para os fields corretos
# no output do iostat para cada UNIX flavor

case $OS in
    AIX|HP-UX)
        SWITCH='-t'
        F1=3
        F2=4
        F3=5
        F4=6
        ;;
    Linux)
        SWITCH='-c'
        F1=1
        F2=3
        F3=4
        F4=6
        ;;
    SunOS)
        SWITCH='-c'
        F1=1
        F2=2
        F3=3
        F4=4
        ;;
    OpenBSD)
        SWITCH='-C'
        F1=1
        F2=2
        F3=3
        F4=5
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

echo "Coletando CPU Statistics usando iostat..."
echo "Existem $INTERVAL sampling periods"
echo "Cada interval dura $SECS seconds"
echo
echo "...Por favor, aguarde enquanto as estatísticas são coletadas..."
echo

###################################################
############# COLETA E PROCESSAMENTO ##############
###################################################

iostat $SWITCH $SECS $INTERVAL \
| egrep -v '[a-zA-Z]|^$' \
| awk '{print $'"$F1"', $'"$F2"', $'"$F3"', $'"$F4"'}' \
| while read FIRST SECOND THIRD FOURTH
do
    # Ignorar o primeiro sample (desde o reboot)
    if (( STATCOUNT == 1 ))
    then
        case $OS in
            AIX)
                echo
                echo "User part       : ${FIRST}%"
                echo "System part     : ${SECOND}%"
                echo "Idle part       : ${THIRD}%"
                echo "I/O wait state  : ${FOURTH}%"
                echo
                ;;
            HP-UX|OpenBSD)
                echo
                echo "User part   : ${FIRST}%"
                echo "Nice part  : ${SECOND}%"
                echo "System part: ${THIRD}%"
                echo "Idle time  : ${FOURTH}%"
                echo
                ;;
            SunOS|Linux)
                echo
                echo "User part   : ${FIRST}%"
                echo "System part: ${SECOND}%"
                echo "I/O Wait   : ${THIRD}%"
                echo "Idle time  : ${FOURTH}%"
                echo
                ;;
        esac
    fi

    ((STATCOUNT = STATCOUNT + 1))
done
