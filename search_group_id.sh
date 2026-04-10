#!/bin/bash
#
# SCRIPT: search_group_id.sh
# AUTHOR: Zainer Araujo
# DATE: 14/04/2025
# REV: 1.1
# PURPOSE: List groups associated with each user in /etc/passwd
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
awk -F: '{print $1}' /etc/passwd | while read USER; do
  # Exibe o nome do usuário seguido dos grupos
  echo -n "${USER}: "
  id -Gn "$USER"
done
