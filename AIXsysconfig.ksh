#!/usr/bin/ksh
#
# SCRIPT: AIXsysconfig.ksh
#
# AUTHOR: Zainer Araujo
# REV: 2.1.A
# DATE: 06/11/2025
#
# PLATFORM: AIX only
#
# PURPOSE:
#   Capturar um snapshot completo da configuração do sistema AIX
#   para comparação posterior em caso de problemas.
#

#################################################
# VARIÁVEIS
#################################################
THISHOST=$(/usr/bin/hostname)
DATETIME=$(date +%m%d%y_%H%M%S)
WORKDIR="/usr/local/reboot"
SYSINFO_FILE="${WORKDIR}/sys_snapshot.${THISHOST}.${DATETIME}"

#################################################
# FUNÇÕES
#################################################
get_host() {
  hostname
}

get_OS() {
  uname -s
}

get_OS_level() {
  oslevel -r
  OSL=$(oslevel -r | cut -c1-2)
  if (( OSL >= 53 )); then
    echo "Technology Level:"
    oslevel -s
  fi
}

get_ML_for_AIX() {
  instfix -i | grep AIX_ML
}

print_sys_config() {
  prtconf
}

get_TZ() {
  grep '^TZ=' /etc/environment | awk -F= '{print $2}'
}

get_real_mem() {
  echo "$(bootinfo -r) KB"
}

get_arch() {
  ARCH=$(uname -M 2>/dev/null)
  [[ -z "$ARCH" ]] && ARCH=$(uname -p)
  echo "$ARCH"
}

get_devices() {
  lsdev -C
}

get_long_devdir_Listagem() {
  ls -l /dev
}

get_tape_drives() {
  lsdev -Cc tape
}

get_cdrom() {
  lsdev -Cc cdrom
}

get_adapters() {
  lsdev -Cc adapter
}

get_routes() {
  netstat -rn
}

get_netstats() {
  netstat -i
}

get_fs_stats() {
  df -k
  echo
  mount
}

get_VGs() {
  lsvg | sort
}

get_varied_on_VGs() {
  lsvg -o | sort
}

get_LV_info() {
  for VG in $(get_varied_on_VGs); do
    lsvg -l "$VG"
  done
}

get_paging_space() {
  lsps -a
  echo
  lsps -s
}

get_disk_info() {
  lspv
}

get_VG_disk_info() {
  for VG in $(get_varied_on_VGs); do
    lsvg -p "$VG"
  done
}

get_HACMP_info() {
  if [ -x /usr/sbin/cluster/utilities/cllsif ]; then
    /usr/sbin/cluster/utilities/cllsif
    echo
  fi
  if [ -x /usr/sbin/cluster/utilities/clshowres ]; then
    /usr/sbin/cluster/utilities/clshowres
  fi
}

get_printer_info() {
  lpstat -W | tail +3
}

get_process_info() {
  ps -ef
}

get_sna_info() {
  sna -d s 2>/dev/null
  if (( $? != 0 )); then
    lssrc -s sna -l
  fi
}

get_udp_x25_procs() {
  ps -ef | egrep 'udp|x25' | grep -v grep
}

get_sys_cfg() {
  lscfg
}

get_long_sys_config() {
  lscfg -vp
}

get_installed_filesets() {
  lslpp -L
}

check_for_broken_filesets() {
  lppchk -vm3 2>&1
}

last_logins() {
  last | head -100
}

#################################################
# MAIN
#################################################
if [[ "$(get_OS)" != "AIX" ]]; then
  echo "\nERRO: Este script só pode ser executado em AIX\n"
  exit 1
fi

if [ ! -d "$WORKDIR" ]; then
  mkdir -p "$WORKDIR" || {
    echo "\nERRO: Não foi possível criar $WORKDIR\n"
    exit 2
  }
fi

{
echo "\n[ $(basename $0) - $(date) ]"
echo "Host:                $(get_host)"
echo "Fuso Horário:        $(get_TZ)"
echo "Memória Real:        $(get_real_mem)"
echo "Arquitetura:         $(get_arch)"
echo "Sistema Operacional: $(get_OS)"
echo "Nível do AIX:        $(get_OS_level)"

echo "\n==== CONFIGURAÇÃO DO SISTEMA ===="
print_sys_config

echo "\n==== DISPOSITIVOS ===="
get_devices

echo "\n==== /dev (listagem longa) ===="
get_long_devdir_Listagem

echo "\n==== FITAS ===="
get_tape_drives

echo "\n==== CD-ROM ===="
get_cdrom

echo "\n==== ADAPTADORES ===="
get_adapters

echo "\n==== ROTAS ===="
get_routes

echo "\n==== NETWORK STATS ===="
get_netstats

echo "\n==== FILESYSTEMS ===="
get_fs_stats

echo "\n==== VOLUME GROUPS ===="
get_VGs

echo "\n==== VGs VARIED-ON ===="
get_varied_on_VGs

echo "\n==== LOGICAL VOLUMES ===="
get_LV_info

echo "\n==== PAGING SPACE ===="
get_paging_space

echo "\n==== DISKS ===="
get_disk_info

echo "\n==== DISKS POR VG ===="
get_VG_disk_info

echo "\n==== HACMP ===="
get_HACMP_info

echo "\n==== IMPRESSORAS ===="
get_printer_info

echo "\n==== PROCESSOS ===="
get_process_info

echo "\n==== SNA ===="
get_sna_info

echo "\n==== UDP / X25 ===="
get_udp_x25_procs

echo "\n==== LSCFG ===="
get_sys_cfg

echo "\n==== LSCFG DETALHADO ===="
get_long_sys_config

echo "\n==== FILESETS ===="
get_installed_filesets

echo "\n==== FILESETS CORROMPIDOS ===="
check_for_broken_filesets

echo "\n==== ÚLTIMOS LOGINS ===="
last_logins

echo "\nRelatório salvo em: $SYSINFO_FILE"
} | tee -a "$SYSINFO_FILE"
