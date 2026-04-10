#!/usr/bin/ksh
#
# SCRIPT: fs_mon_AIX_except.ksh
# AUTHOR: Zainer Araujo
# DATE: 18-12-2025
# REV: 2.1.P
#

##### DEFINIR ARQUIVOS E VARIÁVEIS #####
FSMAX=85
WORKFILE="/tmp/df.work"
OUTFILE="/tmp/df.outfile"
BINDIR="/usr/local/bin"
THISHOST=$(hostname)
EXCEPTIONS="${BINDIR}/exceptions"
DATA_EXCEPTIONS="/tmp/dfdata.out"

> "$WORKFILE"
> "$OUTFILE"

##### FUNÇÕES #####

load_EXCEPTIONS_file() {
    # Ignorar comentários e linhas em branco
    grep -Ev '^\s*#|^\s*$' "$EXCEPTIONS" > "$DATA_EXCEPTIONS"
}

check_exceptions() {
    while read FSNAME NEW_MAX
    do
        if [[ "$FSNAME" = "$FSMOUNT" ]]
        then
            NEW_MAX=${NEW_MAX%\%}
            typeset -i NEW_MAX

            if [ "$FSVALUE" -gt "$NEW_MAX" ]
            then
                return 0    # Encontrado e acima do limite
            else
                return 2    # Encontrado, mas OK
            fi
        fi
    done < "$DATA_EXCEPTIONS"

    return 1    # Não encontrado
}

######## MAIN ########

# Carregar exceções se o arquivo existir e não estiver vazio
[ -s "$EXCEPTIONS" ] && load_EXCEPTIONS_file

# Coletar dados dos filesystems
df -k | tail +2 | egrep -v '/dev/cd[0-9]|/proc' \
| awk '{print $1, $4, $7}' > "$WORKFILE"

# Processar cada filesystem
while read FSDEVICE FSVALUE FSMOUNT
do
    FSVALUE=${FSVALUE%\%}
    typeset -i FSVALUE

    if [ -s "$EXCEPTIONS" ]
    then
        check_exceptions
        RC=$?

        if [ "$RC" -eq 0 ]
        then
            echo "$FSDEVICE mounted on $FSMOUNT is ${FSVALUE}%" >> "$OUTFILE"
            continue
        elif [ "$RC" -eq 2 ]
        then
            continue
        fi
    fi

    # Usar limite padrão
    if [ "$FSVALUE" -gt "$FSMAX" ]
    then
        echo "$FSDEVICE mounted on $FSMOUNT is ${FSVALUE}%" >> "$OUTFILE"
    fi

done < "$WORKFILE"

# Exibir resultado
if [ -s "$OUTFILE" ]
then
    print "\nFull Filesystem(s) on $THISHOST\n"
    cat "$OUTFILE"
fi

exit 0
