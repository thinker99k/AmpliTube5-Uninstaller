#!/bin/zsh


### for debug
DEBUG=1

dbg(){
  if [[ $DEBUG -eq 1 ]]; then
    echo "DEBUG : $1"
  fi
}


### global variables
readonly PKG_NAME="com.ikmultimedia.AmpliTube5"
readonly CORE_PATH="/Library/Application Support/IK Multimedia/AmpliTube 5"

readonly PROC_NAME1="AmpliTube 5"
readonly PROC_NAME2="IK Product Manager"

readonly PKGFILES="pkgfiles.txt"
readonly FILTERED="filtered.txt"


### io
readonly DEFAULT="\033[0m"
readonly GREEN="\033[32m"
readonly YELLOW="\033[33m"
readonly RED="\033[31m"

# color (color:string)
color() {
  case "$1" in
    GREEN) echo "${GREEN}" ;;
    YELLOW) echo "${YELLOW}" ;;
    RED) echo "${RED}" ;;
    *) echo "${DEFAULT}" ;;
  esac
}

# msg_open (color:string) (msg:string)
msg_open(){
  local msg_open_color
  msg_open_color=$(color "$1")

  # stderr
  if [[ "$1" == "RED" ]]; then
    printf "${msg_open_color}%s${DEFAULT}" "$2" >&2

  # stdout
  else
    printf "${msg_open_color}%s${DEFAULT}" "$2"
  fi
}

# msg_close (color:string) (msg:string)
msg_close(){
  local msg_close_color
  msg_close_color=$(color "$1")

  # stderr
  if [[ "$1" == "RED" ]]; then
    printf "${msg_close_color}%s${DEFAULT}\n" "$2" >&2

  # stdout
  else
    printf "${msg_close_color}%s${DEFAULT}\n" "$2"
  fi
}

# stat (color:string) (msg:string)
stat(){
  local stat_color
  stat_color=$(color "$1")

  local cols
  cols=$(tput cols 2>/dev/null || echo 80)
  local msg="[ $2 ]"
  local col_pos=$(( cols - ${#msg} ))

  tput hpa ${col_pos}
  printf "[ ${stat_color}%s${DEFAULT} ]\n" "$2"
}


get_yn() {
  local answer
  local cnt=0

  while true; do
    if [[ ${cnt} -ge 3 ]]; then
    msg_close RED "YOU MORON"
      exit 1;
    fi

    msg_open DEFAULT "$1"

    read -r answer
    case "${answer}" in
      [yY] | [yY][eE][sS] )
        return 0
        ;;

      [nN] | [nN][oO] )
        return 1
        ;;

      * )
        msg_open YELLOW "** Warning ** "
        msg_close YELLOW "Invalid input."
        ;;
    esac

    ((cnt++))
  done
}


### 1
chk_priv() {
  msg_open DEFAULT "[1/7] Check root privilege... "

  if [[ $EUID -ne 0 ]]; then
    stat RED "FAIL"
    msg_open RED "** ERROR ** "
    msg_close RED "Run script with root privilege"
    exit 1

  else
    stat GREEN "OK"
  fi
}

chk_pkg() {
  msg_open DEFAULT "[2/7] Check if ${PKG_NAME} exists... "

  # installed
  if pkgutil --pkgs | grep -q "^${PKG_NAME}$"; then
    stat GREEN "OK"
    return

  # installed but NO receipt
  # ex. user delete just AmpliTube 5.app from /Application
  elif [[ -d "${CORE_PATH}" ]]; then
    stat RED "FAIL"
    msg_open RED "** ERROR ** "
    msg_close RED "Package Receipt not found, reinstall Amplitube 5"
    exit 1

  # not installed
  else
    stat YELLOW "NO"
    msg_open YELLOW "** Warning ** "
    msg_close YELLOW "Nothing to uninstall"
    exit 0
  fi
}

kill_proc() {
  # 1st try -> pkill (-15 : SIGTERM)
  pkill -x "$1" > /dev/null 2>&1
  sleep 2
  if ! pgrep -x "$1" > /dev/null; then
    return 0
  fi

  # 2nd try -> pkill force (-9 : SIGKILL)
  pkill -9 -x "$1" > /dev/null 2>&1
  sleep 2
  if ! pgrep -x "$1" > /dev/null; then
    return 0
  fi

  return 1
}

find_proc() {
  # process found
  if pgrep -x "$1" > /dev/null; then
    msg_open DEFAULT "FOUND... "

    # kill success
    if kill_proc "$1"; then
      return 0

    # kill fail
    else
      return 1
    fi

  # process NOT found
  else
    msg_open DEFAULT "NO... "
    return 0
  fi
}

chk_at5() {
  msg_open DEFAULT "[3/7] Kill ${PROC_NAME1} if running... "

  if find_proc "${PROC_NAME1}"; then
    stat GREEN "OK";

  else
    stat RED "FAIL"
    msg_open RED "** ERROR ** "
    msg_close RED "Failed to terminate ${PROC_NAME1}"
    exit 1
  fi
}

chk_ikpm() {
  msg_open DEFAULT "[4/7] Kill ${PROC_NAME2} if running... "

  if find_proc "${PROC_NAME2}"; then
    stat GREEN "OK";

  else
    stat RED "FAIL"
    msg_open RED "** ERROR ** "
    msg_close RED "Failed to terminate ${PROC_NAME2}"
    exit 1
  fi
}


### 2
# temporary root path
tmp_path=""
# ex.
# a/b/AmpliTube 5 <-- tmp_path
# a/b/AmpliTube 5/c
# a/b/AmpliTube 5/c/d
# ...
# x/y/AmpliTube 5 <-- tmp_path
# x/y/AmpliTube 5/z
# x/y/AmpliTube 5/z/w

# about "AmpliTube 5"
do_list1() {
  while IFS= read -r line; do
    # if tmp_path is NOT null
    if [[ -n "${tmp_path}" ]]; then

      # current line include tmp_path
      if [[ "${line}" == "${tmp_path}/"* ]]; then
        continue

      # current line is border (previous line was last child)
      else
        # flush
        tmp_path=""
      fi
    fi
    # from now and after, tmp_path IS null

    # current line include "[Aa]mpli[Tt]ube\ ?5"
    if [[ "${line}" =~ [Aa]mpli[Tt]ube\ ?5 ]]; then
      tmp_path="${line}"
      echo "/${tmp_path}" >> "${FILTERED}"

    # very parent path, unrelated to AmpliTube 5
    else
      continue
    fi
  done < "${PKGFILES}"
}

# about "X-DRIVE", "X-SPACE", "X-TIME", "X-VIBE" (all case insensitive)
do_list2() {
  while IFS= read -r line; do
    # if tmp_path is NOT null
    if [[ -n "${tmp_path}" ]]; then

      # current line include tmp_path
      if [[ "${line}" == "${tmp_path}/"* ]]; then
        continue

      # current line is border (previous line was last child)
      else
        # flush
        tmp_path=""
      fi
    fi
    # from now and after, tmp_path IS null

    # current line include "X-(DRIVE|SPACE|TIME|VIBE)"(case insensitive)
    if [[ "${line}" =~ [Xx]-([Dd][Rr][Ii][Vv][Ee]|[Ss][Pp][Aa][Cc][Ee]|[Tt][Ii][Mm][Ee]|[Vv][Ii][Bb][Ee]) ]]; then
      tmp_path="${line}"
      echo "/${tmp_path}" >> "${FILTERED}"

    # very parent path, unrelated to AmpliTube 5
    else
      continue
    fi
  done < "${PKGFILES}"
}

do_list() {
  msg_open DEFAULT "[5/7] Make list of files pkg wrote... "

  # get full list of files which pkg installer write
  pkgutil --files com.ikmultimedia.AmpliTube5 > "${PKGFILES}" 2>/dev/null || exit 1

  # colon = null command
  : > "${FILTERED}"

  do_list1
  do_list2

  stat GREEN "OK"
}

do_remove() {
  msg_open YELLOW "** Warning ** "
  msg_close YELLOW "This is the point of no return."
  msg_close RED "ALL FILES WILL BE PERMANENTLY DELETED."

  if ! get_yn "Are you sure you want to proceed? Y(es)/ N(o) : "; then
    msg_close DEFAULT "Deletion cancelled by user. Exiting safely..."
    exit 0
  fi

  msg_open DEFAULT "[6/7] Remove files... "

  # filtered.txt is empty
  if [[ ! -s "${FILTERED}" ]]; then
    stat RED "FAIL"
    msg_open RED "** ERROR ** "
    msg_close RED "File list is empty. Nothing to remove."
    exit 1
  fi

  local err_cnt=0
  while IFS= read -r line; do
    # ignore empty line
    [[ -z "${line}" ]] && continue

    # delete
    if ! rm -rf "${line}" 2>/dev/null; then
      ((err_cnt++))
    fi
  done < "${FILTERED}"

  if [[ ${err_cnt} -eq 0 ]]; then
    stat GREEN "OK"

  else
    stat RED "FAIL"
    msg_open RED "** ERROR ** "
    msg_close DEFAULT "Failed to remove ${err_cnt} items. Please check ${FILTERED} manually."
    exit 1
  fi
}

do_cleanup() {
  msg_open DEFAULT "[7/7] Final cleanup... "

  pkgutil --forget "${PKG_NAME}" > /dev/null 2>&1 || exit 1
  rm -f "${PKGFILES}" "${FILTERED}" 2>/dev/null

  stat GREEN "OK"
}

main() {
  msg_close DEFAULT "[[ AmpliTube 5 Uninstaller ]]"

  if ! get_yn "Are you sure you want to remove AmpliTube5? Y(es)/ N(o) : "; then
    msg_close DEFAULT "Exiting..."
    exit 0
  fi

  ### 1
  chk_priv
  chk_pkg
  chk_at5
  chk_ikpm

  ### 2
  do_list
  do_remove
  do_cleanup

  msg_close GREEN "******* Uninstallation Complete!! *******"
}

main
