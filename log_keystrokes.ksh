#!/bin/ksh
#
# SCRIPT: log_keystrokes.ksh
# AUTOR: Zainer Araujo
# DATA: 05/08/2025
# REV: 1.1 - Corrigido e funcional
# PLATAFORMA: Any Unix
#
# OBJETIVO: Monitorar sessão de login, capturando todos os comandos
# e salvando em arquivo de log, enviado por e-mail ao administrador.

#########################
# CONFIGURAÇÕES
#########################
LOG_MANAGER="logman"           # Usuário ou e-mail que receberá os logs
LOGDIR="/usr/local/logs/script" # Diretório para armazenar logs
mkdir -p "$LOGDIR"              # Garantir que o diretório exista

TS=$(date +%m%d%y%H%M%S)       # Timestamp
THISHOST=$(hostname | cut -f1-2 -d.) # Hostname curto
LOGFILE="${THISHOST}.${LOGNAME}.${TS}" # Nome do arquivo de log

touch "$LOGDIR/$LOGFILE"
chmod 600 "$LOGDIR/$LOGFILE"

# Configurações de shell
set -o vi 2>/dev/null           # Recall de comandos
stty erase ^?                   # Backspace
export PS1="[$LOGNAME:$THISHOST]@"'$PWD> '  # Prompt customizado

#########################
# FUNÇÕES
#########################
cleanup_exit() {
    # Função chamada em qualquer saída do shell (exceto kill -9)
    if [[ -s "${LOGDIR}/${LOGFILE}" ]]; then
        echo "Enviando log de auditoria para $LOG_MANAGER..."
        mailx -s "$TS - $LOGNAME Audit Report" "$LOG_MANAGER" < "${LOGDIR}/${LOGFILE}"
        gzip -f "${LOGDIR}/${LOGFILE}" 2>/dev/null
    fi
    exit
}

# Configura trap para sinais comuns
trap cleanup_exit 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 26

#########################
# EXECUÇÃO PRINCIPAL
#########################
chmod 600 "${LOGDIR}/${LOGFILE}"  # Permissão de leitura/escrita para owner
script -q "${LOGDIR}/${LOGFILE}"  # Inicia captura da sessão (modo silencioso)
chmod 400 "${LOGDIR}/${LOGFILE}"  # Define permissão somente leitura
cleanup_exit                       # Garante cleanup e envio do log
