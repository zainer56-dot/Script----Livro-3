#!/bin/bash

############################################
# SCRIPT: system_snapshot.sh
# AUTOR: Zainer Araujo
# PROPÓSITO:
#   Criar um snapshot compactado de diretórios
#   importantes do sistema.
############################################

# Encerrar o script se qualquer comando falhar
set -e

# Diretórios para capturar a configuração do sistema
CONFIG_DIRS=(
  "/etc"
  "/var"
  "/home"
)

# Diretório onde o snapshot será armazenado
BACKUP_DIR="/path/to/backup"

# Nome do arquivo de snapshot com data e hora
SNAPSHOT_NAME="snapshot-$(date +%Y-%m-%d_%H-%M-%S).tar.gz"

# Criar diretório de backup se não existir
mkdir -p "$BACKUP_DIR"

echo "Iniciando criação do snapshot..."
echo "Destino: $BACKUP_DIR/$SNAPSHOT_NAME"

# Criar o snapshot
tar -czpf "$BACKUP_DIR/$SNAPSHOT_NAME" "${CONFIG_DIRS[@]}"

# Verificar sucesso
if [[ $? -eq 0 ]]; then
  echo "Snapshot criado com sucesso:"
  echo "➡ $BACKUP_DIR/$SNAPSHOT_NAME"
else
  echo "ERRO: Falha ao criar o snapshot." >&2
  exit 1
fi

exit 0
