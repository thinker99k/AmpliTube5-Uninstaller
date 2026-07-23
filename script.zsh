#!/bin/zsh

# for debug
DEBUG=0

function dbg(){
  if [[ $DEBUG -eq 1 ]]; then
    out "DEBUG $1"
  fi
}

function out_open(){
  echo -n "$1"
}

function out_close(){
  echo "$1"
}

function err_open(){
  echo -n "$1" >&2
}

function err_close(){
  echo "$1" >&2
}

### 1
PKG_NAME="com.ikmultimedia.AmpliTube5"
PROC_NAME="AmpliTube 5"

function chk_privilege() {
  out_open "[1/7] Check root privilege... "

  if [[ $EUID -ne 0 ]]; then
    err_close "FAIL"
    err_open "** ERROR ** "
    err_close "Run script with root privilege"
    exit 1
  else
    out_close "OK"
  fi

  dbg "[1/7]"
}

function chk_package() {
  out_open "[2/7] Check if package exists... "

  if ! pkgutil --pkgs | grep -q "^${PKG_NAME}$"; then
    err_close "NO"
    err_open "** Warning ** "
    err_close "Nothing to uninstall"
    exit 0
  else
    out_close "OK"
  fi

  dbg "[2/7]"
}

function chk_process() {
  out_open "[3/7] Kill AmpliTube5 if running... "

  if pgrep -x "$PROC_NAME" > /dev/null; then
    out_open "FOUND... "

    killall "$PROC_NAME" > /dev/null 2>&1
    sleep 10
  else
    out_close "NOT RUNNING"
    return
  fi

  # re-check is process killed
  if pgrep -x "$PROC_NAME" > /dev/null; then
    err_close "FAIL"
    err_open "** ERROR ** "
    err_close "Failed to terminate"
    exit 1
  else
    out_close "OK"
  fi

  dbg "[3/7]"
}


### 2
LIST_TXT="list.txt"

function do_make_list() {


  dbg "[4/7]"
}

function do_format_list() {

  dbg "[5/7]"
}

function do_remove_files() {

  dbg "[6/7]"
}


### 3
function cleanup() {
  rm -f "$LIST_TXT"
  # pkgutil --forget "$PKG_NAME" > /dev/null 2>&1

  # for debug
  dbg "[7/7]"
}

function get_yn() {
  local answer
  local cnt=0

  while true; do
    if [[ $cnt -ge 3 ]]; then
      echo "YOU MORON"
      exit 0;
    fi

    out_open "$1"

    read -r answer
    case "$answer" in
      [yY] | [yY][eE][sS] )
        return 0
        ;;

      [nN] | [nN][oO] )
        return 1
        ;;

      * )
        err_open "** ERROR ** "
        err_close "Invalid input."
        ;;
    esac

    ((cnt++))
  done
}

function main() {
  out_close "[ AmpliTube5 Uninstaller ]"

  if ! get_yn "Are you sure you want to remove AmpliTube5? Y(es)/ N(o) : "; then
    out_close "Exiting..."
    exit 0
  fi

  ### 1
  chk_privilege
  chk_package
  chk_process

  ### 2
  do_make_list
  do_format_list
  do_remove_files

  ### 3
  cleanup

  out_close "Uninstallation Complete!!"
}

main
