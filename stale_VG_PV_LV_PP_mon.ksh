#!/usr/bin/ksh
#
# SCRIPT: stale_VG_PV_LV_PP_mon.ksh
#
# AUTHOR: Zainer Araujo
# DATE: 01/11/2025
# REV: 1.2.P
#
# PLATFORM: AIX
#

ATTEMPT_RESYNC=FALSE
LOGFILE="/tmp/stale_PP_log"
THIS_HOST=$(hostname)

STALE_PP_COUNT=0
STALE_PV_COUNT=0

PV_LIST=""
INACTIVE_PV_LIST=""
STALE_PV_LIST=""
STALE_LV_LIST=""
STALE_VG_LIST=""
RESYNC_LV_LIST=""

> "$LOGFILE"
date >> "$LOGFILE"
echo "\n$THIS_HOST\n" >> "$LOGFILE"

function trap_exit {
    echo "\n...SAINDO EM SIGNAL TRAP...\n" | tee -a "$LOGFILE"
}

trap 'trap_exit; exit 1' 1 2 3 5 15

echo "\nProcurando Volume Groups com stale PVs...\c" | tee -a "$LOGFILE"

for VG in $(lsvg -o)
do
    NUM_STALE_PV=$(lsvg "$VG" | awk '/STALE PVs:/ {print $3}')
    if (( NUM_STALE_PV > 0 ))
    then
        STALE_VG_LIST="$STALE_VG_LIST $VG"
        PV_LIST="$PV_LIST $(lsvg -p "$VG" | tail +3 | awk '{print $1}')"
        (( STALE_PV_COUNT += NUM_STALE_PV ))
    fi
done

if (( STALE_PV_COUNT == 0 ))
then
    echo "\nNenhum stale disk mirror encontrado...SAINDO...\n" \
    | tee -a "$LOGFILE"
    exit 0
fi

echo "\nStale PVs encontrados. Verificando stale PPs...\n" | tee -a "$LOGFILE"

for HDISK in $PV_LIST
do
    PV_STATE=$(lspv "$HDISK" | awk '/PV STATE:/ {print $3}')
    if [[ "$PV_STATE" != "active" ]]
    then
        INACTIVE_PV_LIST="$INACTIVE_PV_LIST $HDISK"
        continue
    fi

    NUM_STALE_PP=$(lspv -L "$HDISK" | awk '/STALE PARTITIONS:/ {print $3}')
    if (( NUM_STALE_PP > 0 ))
    then
        STALE_PV_LIST="$STALE_PV_LIST $HDISK"
        (( STALE_PP_COUNT += NUM_STALE_PP ))
    fi
done

for PV in $STALE_PV_LIST
do
    STALE_LV_LIST="$STALE_LV_LIST $(lspv -l "$PV" | tail +3 | awk '{print $1}')"
done

for LV in $STALE_LV_LIST
do
    LV_NUM_STALE_PP=$(lslv "$LV" | awk '/STALE PPs:/ {print $3}')
    (( LV_NUM_STALE_PP > 0 )) && RESYNC_LV_LIST="$RESYNC_LV_LIST $LV"
done

if [[ -n "$INACTIVE_PV_LIST" ]]
then
    for PV in $INACTIVE_PV_LIST
    do
        echo "\nWARNING: PV $PV está INACTIVE" | tee -a "$LOGFILE"
        echo "Contato com IBM Support recomendado.\n" | tee -a "$LOGFILE"
    done
fi

echo "\nVolume Groups afetados:\n$STALE_VG_LIST" | tee -a "$LOGFILE"
echo "\nPhysical Volumes com stale PPs:\n$STALE_PV_LIST" | tee -a "$LOGFILE"
echo "\nLogical Volumes que precisam de resync:\n$RESYNC_LV_LIST" | tee -a "$LOGFILE"

if [[ "$ATTEMPT_RESYNC" = "TRUE" ]]
then
    echo "\nTentando resync dos LVs...\n" | tee -a "$LOGFILE"
    syncvg -l $RESYNC_LV_LIST >> "$LOGFILE" 2>&1
    if (( $? != 0 ))
    then
        echo "\nERRO no resync\n" | tee -a "$LOGFILE"
        exit 2
    fi
else
    echo "\nAuto-resync desabilitado\n" | tee -a "$LOGFILE"
fi

echo "\nLog disponível em: $LOGFILE\n"
exit 0
