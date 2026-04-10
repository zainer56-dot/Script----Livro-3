#!/usr/bin/ksh
#
# SCRIPT: chpwd_menu.ksh
# AUTHOR: Zainer Araujo
# DATE: 11/05/2025
# PLATFORM: AIX
# REV: 1.1.P
#
# PURPOSE:
#   Script de menu para a Equipe de Operações alterar senhas
#   de usuários usando sudo + pwdadm.
#
#   ATENÇÃO:
#   - Usuários devem estar autorizados no /etc/sudoers
#   - Use SEMPRE /usr/local/sbin/visudo para editar sudoers
#

#######################################################
# FUNÇÕES
#######################################################
usage() {
  echo "\nUso inválido."
}

chg_pwd() {
  USER_NAME="$1"

  echo "\nO próximo prompt de senha é para A SUA SENHA NORMAL"
  echo "NÃO para a nova senha..."

  # Desativa histórico de senha
  /usr/local/bin/sudo /usr/bin/pwdadm -f NOCHECK "$USER_NAME"
  if [ $? -ne 0 ]; then
    echo "\nERRO: Falha ao desativar o histórico de senhas"
    return 1
  fi

  # Altera a senha
  /usr/local/bin/sudo /usr/bin/pwdadm "$USER_NAME"
  if [ $? -ne 0 ]; then
    echo "\nERRO: Falha ao alterar a senha de $USER_NAME"
    return 1
  fi

  # Força troca no próximo login
  /usr/local/bin/sudo /usr/bin/pwdadm -f ADMCHG "$USER_NAME"
  return 0
}

#######################################################
# MAIN
#######################################################
OPT=0
MSG=""

while [ "$OPT" -ne 99 ]
do
  clear

  # Barra superior
  tput smso
  printf "  MENU DE ALTERAÇÃO DE SENHAS - %s  \n" "$(hostname)"
  tput sgr0

  echo "\n\n"
  echo "  10. Alterar senha de usuário"
  echo "\n"
  echo "  99. Sair"
  echo "\n"

  # Barra inferior (mensagens)
  tput smso
  printf "  %s\n" "$MSG"
  tput sgr0

  MSG=""

  echo "\nEscolha uma opção: \c"
  read OPT

  case "$OPT" in
    10)
      echo "\nNome do usuário para alteração de senha: \c"
      read USERNAME

      if grep "^${USERNAME}:" /etc/passwd >/dev/null 2>&1; then
        chg_pwd "$USERNAME"
        if [ $? -eq 0 ]; then
          MSG="Senha do usuário $USERNAME alterada com sucesso"
        else
          MSG="ERRO: Falha ao alterar a senha de $USERNAME"
        fi
      else
        MSG="ERRO: Usuário inválido: $USERNAME"
      fi
      ;;
    99)
      clear
      exit 0
      ;;
    *)
      MSG="Opção inválida selecionada"
      ;;
  esac
done
