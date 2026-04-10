#!/bin/ksh
#
# SCRIPT: PQ_UP_manager.ksh
# AUTHOR: Zainer Araujo
# DATE: 08/11/2025
# REV: 3.0.P
#
# PLATFORM/SYSTEMS: AIX, CUPS, HP-UX, Linux, OpenBSD, Solaris
#
# PURPOSE: Habilitar impressão e enfileiramento nas filas de impressão
# de forma separada, de acordo com o SO e subsistema.
#
# REV LIST:
# 3.0.P - Reconstruído para correção de sintaxe e suporte multi-plataforma

###################################################
# FUNÇÕES
###################################################

# -------------------------------
# AIX Classic Printing
# -------------------------------
AIX_classic_printing() {
  for Q in $(enq -AW | tail -n +3 | awk '$2=="DOWN"{print $1}'); do
    enable $Q
    if (( $? != 0 )); then
      echo "A fila de impressão $Q falhou ao ser habilitada."
    else
      echo "Fila $Q habilitada com sucesso."
    fi
  done
}

# -------------------------------
# AIX System V Printing
# -------------------------------
AIX_SYSV_printing() {
  LOOP=0
  lpc status all | egrep ':|printing|queueing' | while read LINE; do
    case $LINE in
      *:) Q=$(echo $LINE | cut -d':' -f1);;
      printing*) PSTATUS=$(echo $LINE | awk '{print $3}');;
      queueing*) QSTATUS=$(echo $LINE | awk '{print $3}');;
    esac

    ((LOOP = LOOP + 1))
    if ((LOOP == 3)); then
      # Imprimir
      if [ "$PSTATUS" = "disabled" ]; then
        lpc start $Q >/dev/null
        (( $? == 0 )) && echo "Fila $Q impressão reiniciada"
      fi
      # Enfileirar
      if [ "$QSTATUS" = "disabled" ]; then
        lpc enable $Q >/dev/null
        (( $? == 0 )) && echo "Fila $Q enfileiramento reativado"
      fi
      LOOP=0
    fi
  done
}

# -------------------------------
# CUPS Printing
# -------------------------------
CUPS_printing() {
  LOOP=0
  lpc status all | egrep ':|printing|queuing' | while read LINE; do
    case $LINE in
      *:) Q=$(echo $LINE | cut -d':' -f1);;
      printing*) PSTATUS=$(echo $LINE | awk '{print $3}');;
      queuing*) QSTATUS=$(echo $LINE | awk '{print $3}');;
    esac

    ((LOOP = LOOP + 1))
    if ((LOOP == 3)); then
      [ "$PSTATUS" = "disabled" ] && cupsenable $Q && echo "Fila $Q impressão reiniciada"
      [ "$QSTATUS" = "disabled" ] && accept $Q && echo "Fila $Q enfileiramento reativado"
      LOOP=0
    fi
  done
}

# -------------------------------
# HP-UX Printing
# -------------------------------
HP_UX_printing() {
  lpstat | grep Warning: | while read LINE; do
    [ "$(echo $LINE | grep 'is down')" ] && enable $(echo $LINE | awk '{print $3}')
    [ "$(echo $LINE | grep 'queue is turned off')" ] && accept $(echo $LINE | awk '{print $3}')
  done
}

# -------------------------------
# Linux Printing
# -------------------------------
Linux_printing() {
  LOGFILE="/usr/local/log/PQlog.log"
  [ -f $LOGFILE ] || touch $LOGFILE

  lpc status | tail -n +2 | while read QUEUE PRINTSTAT QUEUESTAT _; do
    [ "$PRINTSTAT" = "disabled" ] && {
      echo "$QUEUE impressão está $PRINTSTAT" | tee -a $LOGFILE
      lpc start $QUEUE | tee -a $LOGFILE
      (( $? == 0 )) && echo "$QUEUE impressão reiniciada" | tee -a $LOGFILE
    }
    [ "$QUEUESTAT" = "disabled" ] && {
      echo "$QUEUE enfileiramento está $QUEUESTAT" | tee -a $LOGFILE
      lpc enable $QUEUE | tee -a $LOGFILE
      (( $? == 0 )) && echo "$QUEUE enfileiramento reiniciado" | tee -a $LOGFILE
    }
  done
}

# -------------------------------
# OpenBSD Printing
# -------------------------------
OpenBSD_printing() {
  LOOP=0
  lpc status all | egrep ':|printing|queuing' | while read LINE; do
    case $LINE in
      *:) Q=$(echo $LINE | cut -d':' -f1);;
      printing*) PSTATUS=$(echo $LINE | awk '{print $3}');;
      queuing*) QSTATUS=$(echo $LINE | awk '{print $3}');;
    esac

    ((LOOP = LOOP + 1))
    if ((LOOP == 3)); then
      [ "$QSTATUS" = "disabled" ] && lpc enable $Q && echo "Fila $Q enfileiramento reabilitado"
      [ "$PSTATUS" = "disabled" ] && lpc up $Q && echo "Fila $Q impressão reiniciada"
      LOOP=0
    fi
  done
}

# -------------------------------
# Solaris Printing
# -------------------------------
Solaris_printing() {
  LOOP=0
  lpc status all | egrep ':|printing|queueing' | while read LINE; do
    case $LINE in
      *:) Q=$(echo $LINE | cut -d':' -f1);;
      printing*) PSTATUS=$(echo $LINE | awk '{print $3}');;
      queueing*) QSTATUS=$(echo $LINE | awk '{print $3}');;
    esac

    ((LOOP = LOOP + 1))
    if ((LOOP == 3)); then
      [ "$PSTATUS" = "disabled" ] && lpc start $Q && echo "Fila $Q impressão reiniciada"
      [ "$QSTATUS" = "disabled" ] && lpc enable $Q && echo "Fila $Q enfileiramento reabilitado"
      LOOP=0
    fi
  done
}

###################################################
# MAIN
###################################################

# Se CUPS estiver em execução, chama a função CUPS
ps auxw | grep -q "[c]upsd"
if (( $? == 0 )); then
  echo "CUPS detectado. Usando funções CUPS."
  CUPS_printing
  exit 0
fi

# Detecta o SO
OS=$(uname)
case $OS in
  AIX)
    # Detecta subsistema de impressão
    if ps -ef | grep -q '[q]daemon'; then
      AIX_classic_printing
    elif ps -ef | grep -q '[l]psched'; then
      AIX_SYSV_printing
    fi
    ;;
  HP-UX) HP_UX_printing ;;
  Linux) Linux_printing ;;
  OpenBSD) OpenBSD_printing ;;
  SunOS) Solaris_printing ;;
  *)
    echo "ERRO: Sistema Operacional não suportado: $OS"
    exit 1
    ;;
esac

exit 0
