#!/bin/ksh
#
# SCRIPT: SSAidentify.ksh
# AUTHOR: Zainer Araujo
# REV: 2.5.A
#

SCRIPTNAME=$(basename "$0")
THISHOST=$(hostname)

HDISKFILE="/tmp/disklist.out"
PDISKFILE="/tmp/pdisklist.identify"

> "$HDISKFILE"
> "$PDISKFILE"

typeset -u MODE="DEFINED_DISKS"
typeset -u STATE="UNKNOWN"
typeset SWITCH

##############################################
function usage {
cat <<EOF

USO:
  $SCRIPTNAME [-v] on|off
  $SCRIPTNAME on|off pdisk# [hdisk# ...]

-v   Atua apenas nos discos VARIED-ON
-?   Exibe o manual

EOF
exit 1
}
##############################################
function man_page {
more <<EOF

MAN PAGE - SSAidentify.ksh

Script para ligar ou desligar as luzes de identificação
dos discos SSA em sistemas AIX.

Pode operar:
- Todos os discos definidos
- Apenas discos VARIED-ON (-v)
- Discos individuais (pdisk / hdisk)

EOF
}
##############################################
function cleanup {
echo "\nSaindo devido a sinal recebido..."
[[ -n "$TWIRL_PID" ]] && kill -9 "$TWIRL_PID" 2>/dev/null
exit 1
}
##############################################
function twirl {
while :
do
  for c in '-' '\' '|' '/'
  do
    print -n "$c\b"
    sleep 1
  done
done
}
##############################################
function all_defined_pdisks {
echo "\n${STATE} TODAS as luzes dos pdisks DEFINIDOS...\n"

lsdev -C -c pdisk -s ssar -H | awk '{print $1}' | while read PDISK
do
  echo "${STATE} ==> $PDISK"
  ssaidentify -l "$PDISK" -"${SWITCH}" || echo "Falhou: $PDISK"
done

echo "\nTAREFA CONCLUÍDA\n"
}
##############################################
function all_varied_on_pdisks {
trap cleanup 1 2 3 15

> "$HDISKFILE"
> "$PDISKFILE"

echo "\nColetando discos VARIED-ON...\c"
for VG in $(lsvg -o)
do
  lspv | grep "$VG" | awk '{print $1}' >> "$HDISKFILE"
done

twirl &
TWIRL_PID=$!

for HDISK in $(cat "$HDISKFILE")
do
  ssaxlate -l "$HDISK" >> "$PDISKFILE" 2>/dev/null
done

kill -9 "$TWIRL_PID" 2>/dev/null
echo "\b "

sort -u "$PDISKFILE" | while read PDISK
do
  echo "${STATE} ==> $PDISK"
  ssaidentify -l "$PDISK" -"${SWITCH}"
done

echo "\nTAREFA CONCLUÍDA\n"
}
##############################################
function list_of_disks {

echo "\n${STATE} luzes individuais...\n"

for PDISK in $PDISKLIST
do
  if [ -c "/dev/$PDISK" ]
  then
    ssaidentify -l "$PDISK" -"${SWITCH}" \
      || echo "Falha ao ${STATE} $PDISK"
  else
    echo "ERRO: $PDISK não existe em $THISHOST"
  fi
done

echo "\nTAREFA CONCLUÍDA\n"
}
##############################################
############# INÍCIO #########################
##############################################

trap cleanup 1 2 3 15

(( $# == 0 )) && usage

command -v ssaidentify >/dev/null 2>&1 || {
  echo "ERRO: ssaidentify não encontrado"
  exit 1
}

command -v ssaxlate >/dev/null 2>&1 || {
  echo "ERRO: ssaxlate não encontrado"
  exit 1
}

while getopts ":vV?" OPT
do
  case $OPT in
    v|V) MODE="VARIED_ON" ;;
    ?) man_page; exit 0 ;;
  esac
done
shift $((OPTIND -1))

case "$1" in
  on|ON)  STATE="ON";  SWITCH="y" ;;
  off|OFF) STATE="OFF"; SWITCH="n" ;;
  *) usage ;;
esac
shift

##############################################
############# EXECUÇÃO ########################
##############################################

if [[ $# -eq 0 && $MODE = "DEFINED_DISKS" ]]
then
  all_defined_pdisks

elif [[ $# -eq 0 && $MODE = "VARIED_ON" ]]
then
  all_varied_on_pdisks

else
  HDISKLIST=""
  PDISKLIST=""

  for ARG in "$@"
  do
    case $ARG in
      hdisk*) HDISKLIST="$HDISKLIST $ARG" ;;
      pdisk*) PDISKLIST="$PDISKLIST $ARG" ;;
    esac
  done

  for HDISK in $HDISKLIST
  do
    PDISKLIST="$PDISKLIST $(ssaxlate -l "$HDISK" 2>/dev/null)"
  done

  [[ -z "$PDISKLIST" ]] && {
    echo "ERRO: nenhum disco válido"
    exit 1
  }

  list_of_disks
fi

exit 0
