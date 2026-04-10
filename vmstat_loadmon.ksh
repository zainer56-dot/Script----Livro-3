#!/bin/ksh
#
# SCRIPT: vmstat_loadmon.ksh
# AUTHOR: Zainer Araujo
# DATE: 12/10/2025
# REV: 1.1.P
# PLATFORM: AIX, HP-UX, Linux, OpenBSD, Solaris
#
# PURPOSE:
#   Este shell script coleta duas amostras de uso de CPU
#   usando o comando vmstat.
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

SECS=300        # Segundos por sample
INTERVAL=2      # Número total de samples
STATCOUNT=0     # Loop counter
OS=$(uname)     # UNIX flavor

###################################################
##### CONFIGURAR O AMBIENTE PARA CADA OS AQUI ######
###################################################
# Os F-numbers apontam para os fields corretos
# no output do comando vmstat para cada UNIX flavor

case $OS in
    AIX)
        F1=14   # us
        F2=15   # sy
        F3=16   # id
        F4=17   # wa
        ;;
    HP-UX)
        F1=16   # us
        F2=17   # sy
        F3=18   # id
        ;;
    Linux)
        F1=13   # us
        F2=14   # sy
        F3=15   # id
        F4=16   # wa
        ;;
    OpenBSD)
        F1=17   # us
        F2=18   # sy
        F3=19   # id
        ;;
    SunOS)
        F1=20   # us
        F2=21   # sy
        F3=22   # id
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

echo "Coletando CPU Statistics usando vmstat..."
echo "Existem $INTERVAL sampling periods"
echo "Cada interval dura $SECS seconds"
echo
echo "...Por favor, aguarde enquanto as estatísticas são coletadas..."
echo

###################################################
############# COLETA E PROCESSAMENTO ##############
###################################################

vmstat $SECS $INTERVAL \
| egrep -v '[a-zA-Z]|^$' \
| awk '{print $'"$F1"', $'"$F2"', $'"$F3"', $'"$F4"'}' \
| while read FIRST SECOND THIRD FOURTH
do
    # Ignorar o primeiro sample (desde o reboot)
    if (( STATCOUNT == 1 ))
    then
        case $OS in
            AIX|Linux)
                echo
                echo "User part       : ${FIRST}%"
                echo "System part     : ${SECOND}%"
                echo "Idle part       : ${THIRD}%"
                echo "I/O wait state  : ${FOURTH}%"
                echo
                ;;
            HP-UX|OpenBSD|SunOS)
                echo
                echo "User part   : ${FIRST}%"
                echo "System part: ${SECOND}%"
                echo "Idle time  : ${THIRD}%"
                echo
                ;;
        esac
    fi

    ((STATCOUNT = STATCOUNT + 1))
done
