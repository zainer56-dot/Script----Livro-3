#!/usr/bin/ksh
#
# SCRIPT: pingnodes.ksh
# AUTOR: Zainer Araujo
# DATA: 20-02-2025
#
# PROPÓSITO:
#   Pingar uma lista de nós e enviar notificação por e-mail
#   caso algum nó esteja inacessível.
#
# REV: 1.0.A
#

#######################################################
# Trap para saída limpa (kill -9 não pode ser capturado)
trap 'echo "\nSaindo devido a um sinal capturado...\n"; exit 1' 1 2 3 15
#######################################################

# ---------------- VARIÁVEIS ----------------
PING_COUNT=3
PACKET_SIZE=56
INTERVAL=3

typeset -u PINGNODES="TRUE"
typeset -u MAILOUT="TRUE"

UNAME=$(uname)
THISHOST=$(hostname)

PINGFILE="/usr/local/bin/ping.list"
MAILFILE="/usr/local/bin/mail.list"
PING_OUTFILE="/tmp/pingfile.out"

> "$PING_OUTFILE"

# ---------------- LISTA DE NÓS ----------------
if [ -s "$PINGFILE" ]
then
    PINGLIST=$(grep -v '^[[:space:]]*#' "$PINGFILE" | sed '/^$/d')
else
    echo "\nERRO: Arquivo ausente - $PINGFILE"
    echo "Lista de nós desconhecida...SAINDO...\n"
    exit 2
fi

# ---------------- LISTA DE E-MAILS ----------------
if [ -s "$MAILFILE" ]
then
    MAILLIST=$(grep -v '^[[:space:]]*#' "$MAILFILE" | sed '/^$/d')
else
    echo "\nAVISO: Arquivo ausente - $MAILFILE"
    echo "Nenhuma notificação será enviada\n"
    MAILOUT="FALSE"
fi

####################################################
############## FUNÇÕES ##############################
####################################################

function ping_host {
    if (( $# != 1 ))
    then
        echo "ERRO: argumento inválido para ping_host"
        return 1
    fi

    HOST="$1"

    case "$UNAME" in
        AIX|OpenBSD|Linux)
            ping -c "$PING_COUNT" "$HOST" 2>/dev/null
            ;;
        HP-UX)
            ping "$HOST" "$PACKET_SIZE" "$PING_COUNT" 2>/dev/null
            ;;
        SunOS)
            ping -s "$HOST" "$PACKET_SIZE" "$PING_COUNT" 2>/dev/null
            ;;
        *)
            echo "ERRO: Sistema operacional não suportado: $UNAME"
            return 1
            ;;
    esac
}

####################################################
function ping_nodes {

if [[ "$PINGNODES" != "TRUE" ]]
then
    return
fi

echo

for HOSTPINGING in $PINGLIST
do
    echo "Pingando --> $HOSTPINGING...\c"

    PINGSTAT=$(ping_host "$HOSTPINGING" | awk '/transmitted/ {print $4}')

    if [[ -z "$PINGSTAT" ]]
    then
        echo "Host desconhecido"
        continue
    fi

    if (( PINGSTAT == 0 ))
    then
        echo "Inacessível...Tentando novamente...\c"
        sleep "$INTERVAL"

        PINGSTAT2=$(ping_host "$HOSTPINGING" | awk '/transmitted/ {print $4}')

        if (( PINGSTAT2 == 0 ))
        then
            echo "Inacessível"
            echo "Não foi possível pingar $HOSTPINGING a partir de $THISHOST" \
            | tee -a "$PING_OUTFILE"
        else
            echo "OK"
        fi
    else
        echo "OK"
    fi
done
}

####################################################
function send_notification {

if [ -s "$PING_OUTFILE" ] && [[ "$MAILOUT" = "TRUE" ]]
then
    case "$UNAME" in
        AIX|HP-UX|Linux|OpenBSD)
            SENDMAIL="/usr/sbin/sendmail"
            ;;
        SunOS)
            SENDMAIL="/usr/lib/sendmail"
            ;;
        *)
            echo "Sendmail não suportado neste sistema"
            return
            ;;
    esac

    echo "\nEnviando notificação por e-mail..."
    $SENDMAIL -f "zainer@$THISHOST" $MAILLIST < "$PING_OUTFILE"
fi
}

####################################################
############### PRINCIPAL ###########################
####################################################

ping_nodes
send_notification

exit 0
