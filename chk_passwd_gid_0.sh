#!/bin/bash
#
# SCRIPT: chk_passwd_gid_0.sh
# PURPOSE: Verifica usuários não-root que possuem GID=0
#

# -------------------------
# Compatibilidade Solaris
# -------------------------
case $(uname) in
  SunOS) alias awk='nawk' ;;
esac

# -------------------------
# Início do main
# -------------------------
awk -F ':' '{print $1, $4}' /etc/passwd | while read USER GID; do
  # Ignora o root
  if [ "$USER" != "root" ]; then
    # Testa se GID = 0
    if [ "$GID" -eq 0 ]; then
      echo "WARNING: $USER is member of the root/system group"
    fi
  fi
done
