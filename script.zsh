#!/bin/zsh

### Options & Flags ###
DEBUG=0
VERBOSE=0

while [[ "$#" -gt 0 ]]; do
  case $1 in
    -d|--debug)
      DEBUG=1
      shift
      ;;
    -v|--verbose)
      VERBOSE=1
      shift
      ;;
    -h|--help)
      echo "Usage: $0 [options]"
      echo "Options:"
      echo "  -d, --debug    Enable debug mode"
      echo "  -v, --verbose  Enable verbose output"
      echo "  -h, --help     Show this help message"
      exit 0
      ;;
    *)
      echo "[Warning] Unknown parameter passed: $1"
      exit 1
      ;;
  esac
done


### config ###
USER_HOME="/Users/${SUDO_USER:-$USER}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TEMP_DIR="/tmp/AmpliTube5-Uninstaller"

readonly PKG_NAME="com.ikmultimedia.AmpliTube5"
readonly PROC_NAME1="AmpliTube 5"
readonly PROC_NAME2="IK Product Manager"


### msg ###
readonly DEFAULT="\033[0m"
readonly GREEN="\033[32m"
readonly YELLOW="\033[33m"
readonly RED="\033[31m"

readonly STEPS=10
CURRSTEP=0

# msg_color (color: string)
msg_color() {
  case "$1" in
    GREEN) echo "${GREEN}" ;;
    YELLOW) echo "${YELLOW}" ;;
    RED) echo "${RED}" ;;
    *) echo "${DEFAULT}" ;;
  esac
}

# msg_open (color: string) (msg: string)
msg_open(){
  local msg_open_color
  msg_open_color=$(msg_color "$1")

  # stderr
  if [[ "$1" == "RED" ]]; then
    printf "${msg_open_color}%s${DEFAULT}" "$2" >&2

  # stdout
  else
    printf "${msg_open_color}%s${DEFAULT}" "$2"
  fi
}

# msg_close (color: string) (msg: string)
msg_close(){
  local msg_close_color
  msg_close_color=$(msg_color "$1")

  # stderr
  if [[ "$1" == "RED" ]]; then
    printf "${msg_close_color}%s${DEFAULT}\n" "$2" >&2

  # stdout
  else
    printf "${msg_close_color}%s${DEFAULT}\n" "$2"
  fi
}

# getYesOrNo (msg: string)
getYesOrNo() {
  local answer
  local cnt=0

  while true; do
    if [[ ${cnt} -ge 3 ]]; then
      msg_close RED "YOU MORON"
      exit 1;
    fi

    msg_close DEFAULT "$1"
    msg_open DEFAULT "Y(es)/ N(o) : "

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

## msg_stat() and msg_step() must be used as pair
# msg_step (msg: string)
msg_step(){
  ((CURRSTEP++))
  msg_open DEFAULT "[${CURRSTEP}/${STEPS}] $1"
}

# msg_stat (color: string) (msg: string)
msg_stat(){
  local msg_stat_color
  msg_stat_color=$(msg_color "$1")

  local cols
  cols=$(tput cols 2>/dev/null || echo 80)
  local msg="[ $2 ]"
  local col_pos=$(( cols - ${#msg} ))

  tput hpa ${col_pos}
  printf "[ ${msg_stat_color}%s${DEFAULT} ]\n" "$2"
}


### targets ###
# delete in this order guarantee clean remove

# TARGET0 : /Applications
# can be deleted by user or not
# -> must delete on purpose
readonly APP_PATH="/Applications/AmpliTube\ 5.app/"

# TARGET1 : pkgutil exist, /Library, /Applications(duplicated)
# about 50%?
# -> delete if pkgutil have receipt
readonly TARGET1="installer"
readonly PKGFILES="pkgfiles.txt"
readonly FILTERED1="filtered1.txt"
FLAG[1]=0

# TARGET2 : ~/Library, /Library(duplicated)
# users will not touch this
# -> will be deleted unconditionally(FLAG=1)
readonly TARGET2="app cache"
readonly PKGCACHES="pkgcaches.txt"
readonly FILTERED2="filtered2.txt"
FLAG[2]=0

# TARGET3 : ~/Documents
# can be deleted by user
# -> must delete on purpose
readonly TARGET3="user data"
readonly DOCUMENTS="documents.txt"
readonly FILTERED3="filtered3.txt"
FLAG[3]=0


### chk ###
chk_priv() {
  msg_step "Check root privilege... "

  if [[ ${EUID} -ne 0 ]]; then
    msg_stat RED "FAIL"
    msg_open RED "** ERROR ** "
    msg_close RED "Run script with root privilege"
    exit 1

  else
    msg_stat GREEN "OK"
  fi
}

# killGentlely (name: string)
killGentlely() {
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

# chk_proc1() (process name: string)
chk_proc1() {
  local process_name="$1"

  msg_step "Kill ${process_name} if running... "

  if pgrep -x "${process_name}" > /dev/null; then
    msg_open DEFAULT "FOUND... "

    if killGentlely "${process_name}"; then
      msg_stat GREEN "OK";

    else
      msg_stat RED "FAIL"
      msg_open RED "** ERROR ** "
      msg_close RED "Failed to terminate ${process_name}"
      exit 1
    fi

  else
    msg_open DEFAULT "NO... "
    msg_stat GREEN "OK"
  fi
}

chk_proc() {
  chk_proc1 "${PROC_NAME1}"
  chk_proc1 "${PROC_NAME2}"
}


### do ###
# "AmpliTube 5" (space none or once, case insensitive)
readonly REGEX1="[Aa]mpli[Tt]ube\ ?5"

# "X-DRIVE", "X-SPACE", "X-TIME", "X-VIBE" (all case insensitive)
readonly REGEX2="[Xx]-([Dd][Rr][Ii][Vv][Ee]|[Ss][Pp][Aa][Cc][Ee]|[Tt][Ii][Mm][Ee]|[Vv][Ii][Bb][Ee])"

# in fact, theres NO X-~ pedals in library (both system and user)
# it's in ~/Documents, but pkgutil says installer touches library
# leave this long regex just in case -- IK code like dog ass

# filterRegex (output_path: string) (input_path: string)
filterRegex() {
  local output="$1"
  local input="$2"

  # find temporary root path
  local tmp_path
  # ex.
  # a/b/AmpliTube 5 <-- temporary root
  # a/b/AmpliTube 5/c
  # a/b/AmpliTube 5/c/d
  # ...
  # x/AmpliTube 5 <-- temporary root
  # x/AmpliTube 5/y
  # x/AmpliTube 5/y/z

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

    # if regex matches
    if [[ "${line}" =~ ${REGEX1} || "${line}" =~ ${REGEX2} ]]; then
      tmp_path="${line}"
      echo "${tmp_path}" >> "${output}"

    # very parent path, unrelated to AmpliTube 5
    else
      continue
    fi
  done < "${input}"
}

# chk_file1 (output_file: string) (input_file: string)
chk_file1() {
  local output_file="${TEMP_DIR}/$1"
  local input_file="${TEMP_DIR}/$2"

  : > "${output_file}"
  filterRegex "${output_file}" "${input_file}"

  if [[ -s "${output_file}" ]]; then
    msg_stat GREEN "OK"
    return 0
  else
    msg_stat RED "NO"
    msg_open RED "** ERROR ** "
    msg_close RED "file list of ${TARGET1} empty"
    return 1
  fi
}

chk_file() {
  mkdir -p "${TEMP_DIR}"

  # TARGET 1
  msg_step "Make file list of ${TARGET1}... "

  if pkgutil --pkgs | grep -q "^${PKG_NAME}$" ; then
    pkgutil --files "${PKG_NAME}" > "${TEMP_DIR}/${PKGFILES}" 2>/dev/null || true
    # pkgutil not print / at start, so add it
    sed -i '' 's/^/\//' "${TEMP_DIR}/${PKGFILES}" # macOS(bsd) specific sed

    chk_file1 "${FILTERED1}" "${PKGFILES}" && FLAG[1]=1

  else
    msg_stat YELLOW "SKIP"
  fi

  # TARGET 2
  msg_step "Make file list of ${TARGET2}... "

  sudo find /Library "${USER_HOME}"/Library \
    -path "*/Library/Containers" -prune -o \
    \( -iname "*amplitube*" -o \
    -iname "*x-drive*" -o \
    -iname "*x-space*" -o \
    -iname "*x-time*" -o \
    -iname "*x-vibe*" \) \
    -print 2>/dev/null | sort \
    > "${TEMP_DIR}/${PKGCACHES}"

  chk_file1 "${FILTERED2}" "${PKGCACHES}" && FLAG[2]=1

  # TARGET 3
  msg_step "Make file list of ${TARGET3}... "

  sudo find "${USER_HOME}"/Documents \
    \( -iname "*amplitube*" -o \
    -iname "*x-drive*" -o \
    -iname "*x-space*" -o \
    -iname "*x-time*" -o \
    -iname "*x-vibe*" \) \
    -print 2>/dev/null | sort \
    > "${TEMP_DIR}/${DOCUMENTS}"

  chk_file1 "${FILTERED3}" "${DOCUMENTS}" && FLAG[3]=1
}


# removeFiles (death_note: string)
removeFiles() {
  local err_cnt=0

  while IFS= read -r line; do
    # ignore empty line
    [[ -z "${line}" ]] && continue

    if (( VERBOSE )); then
      msg_close DEFAULT "${line}"
    fi

    # delete
    if ! rm -rf "${line}" 2>/dev/null; then
      ((err_cnt++))
    fi
  done < "$1"

  if [[ ${err_cnt} -eq 0 ]]; then
    return 0

  else
    return 1
  fi
}

# do_remove1 (death_note: string)
do_remove1() {
  local death_note="${TEMP_DIR}/$1"

  if removeFiles "${death_note}"; then
    msg_stat GREEN "OK"
  else
    msg_stat RED "FAIL"
    msg_open RED "** ERROR ** "
    msg_close RED "Failed to remove some items. Please check ${death_note} manually."
  fi
}

do_remove() {
  if (( !( FLAG[1] || FLAG[2] || FLAG[3] ) )); then
    msg_open YELLOW "** Warning ** "
    msg_close YELLOW "Nothing to remove"
    ((CURRSTEP+=3))
    return
  fi

  msg_open YELLOW "** Warning ** "
  msg_close DEFAULT "This is the point of no return."
  msg_close RED "ALL FILES WILL BE PERMANENTLY DELETED."

  if ! getYesOrNo "Are you sure you want to proceed?"; then
    msg_close YELLOW "Deletion cancelled by user. Exiting..."
    exit 0
  fi

  # some lines will be duplicated in filtered?.txt(death note)
  # but rm -rf will ignore it, makes no error

  # TARGET0 : /Applications
  rm -rf "${APP_PATH}"

  # TARGET1 : pkgutil exist, /Library, /Applications(duplicated)
  msg_step "Remove ${TARGET1}... "

  if (( FLAG[1] )); then
    do_remove1 "${FILTERED1}" "${TARGET1}"
    pkgutil --forget "${PKG_NAME}" > /dev/null 2>&1 || true

  else
    msg_stat YELLOW "skip"
  fi

  # TARGET2 : ~/Library, /Library(duplicated)
  msg_step "Remove ${TARGET2}... "

  if (( FLAG[2] )); then
    do_remove1 "${FILTERED2}"

  else
    msg_stat YELLOW "skip"
  fi

  # TARGET3 : ~/Documents
  msg_step "Remove ${TARGET2}... "

  if (( FLAG[3] )); then
    do_remove1 "${FILTERED3}"

  else
      msg_stat YELLOW "SKIP"
  fi
}

do_cleanup() {
  msg_step "Final cleanup... "

  rm -rf "${TEMP_DIR}" 2>/dev/null

  msg_stat GREEN "OK"
}


main() {
  msg_close DEFAULT "[[ AmpliTube 5 Uninstaller ]]"

  if ! getYesOrNo "Are you sure you want to remove AmpliTube5?"; then
    msg_close DEFAULT "Exiting..."
    exit 0
  fi

  chk_priv
  chk_proc
  chk_file

  do_remove
  do_cleanup

  msg_close GREEN "******* Uninstallation Complete!! *******"
}

main
