#!/bin/bash

# This is where everything is configured.

# To determine speed of machine...
#
# bash -c ' : {1..500000} ; echo $SECONDS'
#
# MBP M1: 0
# MBP Intel: 0
# x86_64 avg machine: 0
# RockPi Debian 64-bits: 1
# RPi4 RaspiOS 64-bits: 1
# RPi3 RaspiOS 32-bits: 4
# RPi2 RaspiOS 32-bits: 7
#
# Let's say if timer > 2, we're on a slow machine.

# At first we tried using uname -m te determine slow devices, but:
#
# uname -m result:
# RPi2: armv7l
# RPi3: armv7l
# RPi4 on 32-bit OS: armv7l
# RPi4 on 64-bit OS: aarch64
# RockPi: aarch64
# Apple M1: arm64
# Intel 64: x86_64#
#
# There are a ton of other possible values... and can't rely on them to detect
# a slow device.

# FROM: https://stackoverflow.com/questions/5195607/checking-bash-exit-status-of-several-commands-efficiently
# Use step(), try(), and next() to perform a series of commands and print
# [  OK  ] or [FAILED] at the end. The step as a whole fails if any individual
# command fails.
#
# Example:
#     step "Remounting / and /boot as read-write:"
#     try mount -o remount,rw /
#     try mount -o remount,rw /boot
#     next
step() {
    echo -n "$@"

    STEP_OK=0
    [[ -w /tmp ]] && echo $STEP_OK > /tmp/step.$$
}

try() {
    # Check for `-b' argument to run command in the background.
    local BG=

    [[ $1 == -b ]] && { BG=1; shift; }
    [[ $1 == -- ]] && {       shift; }

    # Run the command.
    if [[ -z $BG ]]; then
        "$@"
    else
        "$@" &
    fi

    # Check if command failed and update $STEP_OK if so.
    local EXIT_CODE=$?

    if [[ $EXIT_CODE -ne 0 ]]; then
        STEP_OK=$EXIT_CODE
        [[ -w /tmp ]] && echo $STEP_OK > /tmp/step.$$

        if [[ -n $LOG_STEPS ]]; then
            local FILE=$(readlink -m "${BASH_SOURCE[1]}")
            local LINE=${BASH_LINENO[0]}

            echo "$FILE: line $LINE: Command \`$*' failed with exit code $EXIT_CODE." >> "$LOG_STEPS"
        fi
    fi

    return $EXIT_CODE
}

echo_success() {
  #echo -n "[70G[   [32mOK[0m   ]"
  echo -n
}

echo_failure() {
  echo -n "[70G[ [31mFAILED[0m ]"
}

next() {
    [[ -f /tmp/step.$$ ]] && { STEP_OK=$(< /tmp/step.$$); rm -f /tmp/step.$$; }
    [[ $STEP_OK -eq 0 ]]  && echo_success || echo_failure
    echo

    return $STEP_OK
}

#function finish {
#
#}
#trap finish EXIT

cowsay() {
echo '[38;5;148m[39m
[38;5;184m [39m[38;5;184m [39m[38;5;184m [39m[38;5;184m [39m[38;5;184m [39m[38;5;184m [39m[38;5;184m [39m[38;5;184m [39m[38;5;184m [39m[38;5;178m [39m[38;5;214m [39m[38;5;214m [39m[38;5;214m [39m[38;5;214m [39m[38;5;214m [39m[38;5;214m [39m[38;5;214m [39m[38;5;214m [39m[38;5;214m [39m[38;5;208m [39m[38;5;208m [39m[38;5;208m_[39m[38;5;208m_[39m[38;5;208m_[39m[38;5;208m_[39m[38;5;208m_[39m[38;5;208m_[39m[38;5;208m_[39m[38;5;209m_[39m[38;5;203m_[39m[38;5;203m_[39m[38;5;203m_[39m[38;5;203m_[39m[38;5;203m_[39m[38;5;203m_[39m[38;5;203m_[39m[38;5;203m_[39m[38;5;203m_[39m[38;5;203m_[39m[38;5;203m_[39m[38;5;204m_[39m[38;5;198m_[39m[38;5;198m_[39m[38;5;198m_[39m[38;5;198m_[39m[38;5;198m_[39m[38;5;198m_[39m[38;5;198m_[39m[38;5;198m_[39m[38;5;198m_[39m[38;5;199m_[39m[38;5;199m_[39m[38;5;199m_[39m[38;5;199m_[39m[38;5;199m_[39m[38;5;199m_[39m[38;5;199m_[39m[38;5;199m_[39m[38;5;199m [39m[38;5;163m[39m
[38;5;184m [39m[38;5;184m [39m[38;5;184m [39m[38;5;184m [39m[38;5;184m [39m[38;5;184m [39m[38;5;178m [39m[38;5;214m [39m[38;5;214m [39m[38;5;214m [39m[38;5;214m [39m[38;5;214m [39m[38;5;214m [39m[38;5;214m [39m[38;5;214m [39m[38;5;214m [39m[38;5;208m [39m[38;5;208m [39m[38;5;208m [39m[38;5;208m [39m[38;5;208m/[39m[38;5;208m [39m[38;5;208mT[39m[38;5;208mo[39m[38;5;208m [39m[38;5;209ms[39m[38;5;203mt[39m[38;5;203ma[39m[38;5;203mr[39m[38;5;203mt[39m[38;5;203m [39m[38;5;203mc[39m[38;5;203my[39m[38;5;203mp[39m[38;5;203mh[39m[38;5;203me[39m[38;5;203mr[39m[38;5;204mn[39m[38;5;198mo[39m[38;5;198md[39m[38;5;198me[39m[38;5;198m [39m[38;5;198mr[39m[38;5;198mu[39m[38;5;198mn[39m[38;5;198m:[39m[38;5;198m [39m[38;5;199m.[39m[38;5;199m/[39m[38;5;199ms[39m[38;5;199mt[39m[38;5;199ma[39m[38;5;199mr[39m[38;5;199mt[39m[38;5;199m.[39m[38;5;199ms[39m[38;5;163mh[39m[38;5;163m [39m[38;5;164m\[39m[38;5;164m[39m
[38;5;184m [39m[38;5;184m [39m[38;5;184m [39m[38;5;178m [39m[38;5;214m [39m[38;5;214m [39m[38;5;214m [39m[38;5;214m [39m[38;5;214m [39m[38;5;214m [39m[38;5;214m [39m[38;5;214m [39m[38;5;214m [39m[38;5;208m [39m[38;5;208m [39m[38;5;208m [39m[38;5;208m [39m[38;5;208m [39m[38;5;208m [39m[38;5;208m [39m[38;5;208m\[39m[38;5;208m [39m[38;5;209mT[39m[38;5;203mo[39m[38;5;203m [39m[38;5;203ms[39m[38;5;203mt[39m[38;5;203mo[39m[38;5;203mp[39m[38;5;203m [39m[38;5;203mc[39m[38;5;203my[39m[38;5;203mp[39m[38;5;203mh[39m[38;5;204me[39m[38;5;198mr[39m[38;5;198mn[39m[38;5;198mo[39m[38;5;198md[39m[38;5;198me[39m[38;5;198m [39m[38;5;198mr[39m[38;5;198mu[39m[38;5;198mn[39m[38;5;199m:[39m[38;5;199m [39m[38;5;199m [39m[38;5;199m.[39m[38;5;199m/[39m[38;5;199ms[39m[38;5;199mt[39m[38;5;199mo[39m[38;5;199mp[39m[38;5;163m.[39m[38;5;163ms[39m[38;5;164mh[39m[38;5;164m [39m[38;5;164m [39m[38;5;164m/[39m[38;5;164m[39m
[38;5;178m [39m[38;5;214m [39m[38;5;214m [39m[38;5;214m [39m[38;5;214m [39m[38;5;214m [39m[38;5;214m [39m[38;5;214m [39m[38;5;214m [39m[38;5;214m [39m[38;5;208m [39m[38;5;208m [39m[38;5;208m [39m[38;5;208m [39m[38;5;208m [39m[38;5;208m [39m[38;5;208m [39m[38;5;208m [39m[38;5;208m [39m[38;5;209m [39m[38;5;203m [39m[38;5;203m-[39m[38;5;203m-[39m[38;5;203m-[39m[38;5;203m-[39m[38;5;203m-[39m[38;5;203m-[39m[38;5;203m-[39m[38;5;203m-[39m[38;5;203m-[39m[38;5;203m-[39m[38;5;204m-[39m[38;5;198m-[39m[38;5;198m-[39m[38;5;198m-[39m[38;5;198m-[39m[38;5;198m-[39m[38;5;198m-[39m[38;5;198m-[39m[38;5;198m-[39m[38;5;198m-[39m[38;5;199m-[39m[38;5;199m-[39m[38;5;199m-[39m[38;5;199m-[39m[38;5;199m-[39m[38;5;199m-[39m[38;5;199m-[39m[38;5;199m-[39m[38;5;199m-[39m[38;5;163m-[39m[38;5;163m-[39m[38;5;164m-[39m[38;5;164m-[39m[38;5;164m-[39m[38;5;164m-[39m[38;5;164m-[39m[38;5;164m-[39m[38;5;164m [39m[38;5;164m[39m
[38;5;214m [39m[38;5;214m [39m[38;5;214m [39m[38;5;214m [39m[38;5;214m [39m[38;5;214m [39m[38;5;214m [39m[38;5;208m [39m[38;5;208m [39m[38;5;208m [39m[38;5;208m [39m[38;5;208m [39m[38;5;208m [39m[38;5;208m [39m[38;5;208m [39m[38;5;208m [39m[38;5;209m [39m[38;5;203m [39m[38;5;203m [39m[38;5;203m [39m[38;5;203m [39m[38;5;203m [39m[38;5;203m [39m[38;5;203m [39m[38;5;203m [39m[38;5;203m [39m[38;5;203m [39m[38;5;203m [39m[38;5;204m\[39m[38;5;198m [39m[38;5;198m [39m[38;5;198m [39m[38;5;198m^[39m[38;5;198m_[39m[38;5;198m_[39m[38;5;198m^[39m[38;5;198m[39m
[38;5;214m [39m[38;5;214m [39m[38;5;214m [39m[38;5;214m [39m[38;5;208m [39m[38;5;208m [39m[38;5;208m [39m[38;5;208m [39m[38;5;208m [39m[38;5;208m [39m[38;5;208m [39m[38;5;208m [39m[38;5;208m [39m[38;5;209m [39m[38;5;203m [39m[38;5;203m [39m[38;5;203m [39m[38;5;203m [39m[38;5;203m [39m[38;5;203m [39m[38;5;203m [39m[38;5;203m [39m[38;5;203m [39m[38;5;203m [39m[38;5;203m [39m[38;5;204m [39m[38;5;198m [39m[38;5;198m [39m[38;5;198m [39m[38;5;198m\[39m[38;5;198m [39m[38;5;198m [39m[38;5;198m([39m[38;5;198mo[39m[38;5;198mo[39m[38;5;199m)[39m[38;5;199m\[39m[38;5;199m_[39m[38;5;199m_[39m[38;5;199m_[39m[38;5;199m_[39m[38;5;199m_[39m[38;5;199m_[39m[38;5;199m_[39m[38;5;163m[39m
[38;5;214m [39m[38;5;208m [39m[38;5;208m [39m[38;5;208m [39m[38;5;208m [39m[38;5;208m [39m[38;5;208m [39m[38;5;208m [39m[38;5;208m [39m[38;5;208m [39m[38;5;209m [39m[38;5;203m [39m[38;5;203m [39m[38;5;203m [39m[38;5;203m [39m[38;5;203m [39m[38;5;203m [39m[38;5;203m [39m[38;5;203m [39m[38;5;203m [39m[38;5;203m [39m[38;5;203m [39m[38;5;204m [39m[38;5;198m [39m[38;5;198m [39m[38;5;198m [39m[38;5;198m [39m[38;5;198m [39m[38;5;198m [39m[38;5;198m [39m[38;5;198m [39m[38;5;198m [39m[38;5;199m([39m[38;5;199m_[39m[38;5;199m_[39m[38;5;199m)[39m[38;5;199m\[39m[38;5;199m [39m[38;5;199m [39m[38;5;199m [39m[38;5;199m [39m[38;5;163m [39m[38;5;163m [39m[38;5;164m [39m[38;5;164m)[39m[38;5;164m\[39m[38;5;164m/[39m[38;5;164m\[39m[38;5;164m[39m
[38;5;208m [39m[38;5;208m [39m[38;5;208m [39m[38;5;208m [39m[38;5;208m [39m[38;5;208m [39m[38;5;208m [39m[38;5;209m [39m[38;5;203m [39m[38;5;203m [39m[38;5;203m [39m[38;5;203m [39m[38;5;203m [39m[38;5;203m [39m[38;5;203m [39m[38;5;203m [39m[38;5;203m [39m[38;5;203m [39m[38;5;203m [39m[38;5;204m [39m[38;5;198m [39m[38;5;198m [39m[38;5;198m [39m[38;5;198m [39m[38;5;198m [39m[38;5;198m [39m[38;5;198m [39m[38;5;198m [39m[38;5;198m [39m[38;5;199m [39m[38;5;199m [39m[38;5;199m [39m[38;5;199m [39m[38;5;199m [39m[38;5;199m [39m[38;5;199m [39m[38;5;199m|[39m[38;5;199m|[39m[38;5;163m-[39m[38;5;163m-[39m[38;5;164m-[39m[38;5;164m-[39m[38;5;164mw[39m[38;5;164m [39m[38;5;164m|[39m[38;5;164m[39m
[38;5;208m [39m[38;5;208m [39m[38;5;208m [39m[38;5;208m [39m[38;5;209m [39m[38;5;203m [39m[38;5;203m [39m[38;5;203m [39m[38;5;203m [39m[38;5;203m [39m[38;5;203m [39m[38;5;203m [39m[38;5;203m [39m[38;5;203m [39m[38;5;203m [39m[38;5;203m [39m[38;5;204m [39m[38;5;198m [39m[38;5;198m [39m[38;5;198m [39m[38;5;198m [39m[38;5;198m [39m[38;5;198m [39m[38;5;198m [39m[38;5;198m [39m[38;5;198m [39m[38;5;199m [39m[38;5;199m [39m[38;5;199m [39m[38;5;199m [39m[38;5;199m [39m[38;5;199m [39m[38;5;199m [39m[38;5;199m [39m[38;5;199m [39m[38;5;163m [39m[38;5;163m|[39m[38;5;164m|[39m[38;5;164m [39m[38;5;164m [39m[38;5;164m [39m[38;5;164m [39m[38;5;164m [39m[38;5;164m|[39m[38;5;164m|[39m[38;5;164m[39m
[38;5;208m[39m
[m[?25h[?1;5;2004l'
}

## /utils ----

sudo_if_required() {
  if [[ $SUDO_REQUIRED == 1 && ! $(id -u) == 0 ]]; then
    try sudo $@
  else
    try $@
  fi
}

modify_permissions() {
  local directories=("$BITCOIN_DATAPATH" "$LIGHTNING_DATAPATH" "$PROXY_DATAPATH" "$GATEKEEPER_DATAPATH" "$OTSCLIENT_DATAPATH" "$POSTGRES_DATAPATH" "$LOGS_DATAPATH" "$TRAEFIK_DATAPATH" "$TOR_DATAPATH")
  for d in "${directories[@]}"
  do
    if [[ -e $d ]]; then
      step "   [32mmodify[0m permissions: $d"
      sudo_if_required chmod -R og-rwx $d
      next
    fi
  done
}

modify_owner() {
  local directories=("${current_path}/.env" "$BITCOIN_DATAPATH" "$LIGHTNING_DATAPATH" "$PROXY_DATAPATH" "$GATEKEEPER_DATAPATH" "$OTSCLIENT_DATAPATH" "$POSTGRES_DATAPATH" "$LOGS_DATAPATH" "$TRAEFIK_DATAPATH" "$TOR_DATAPATH")
  local user=$(id -u $RUN_AS_USER):$(id -g $RUN_AS_USER)
  for d in "${directories[@]}"
  do
    if [[ -e $d ]]; then
      step "   [32mmodify[0m owner \"$RUN_AS_USER\": $d "
      sudo_if_required chown -R $user $d
      next
    fi
  done
}

configure() {
  ## build setup docker image
  local recreate=""

  if [[ $1 == 1 ]]; then
    recreate=" recreate"
  fi

  local pw_env=''
  local interactive=''
  local gen_options=''

  if [[ -t 1 ]]; then
    interactive=' -it'
  fi

  if [[ $CFG_PASSWORD ]]; then
    pw_env=" -e CFG_PASSWORD=$CFG_PASSWORD"
  fi

  echo "\nDetermining the speed of your machine..."
  local speedseconds=$(bash -c ' : {1..500000} ; echo $SECONDS')
  if [[ $speedseconds > 2 ]]; then
    clear && echo "This may take a while, since it seems we're running on a slow machine."
  else
    clear && echo "Fast machine..."
  fi

  # before starting a new cyphernodeconf, kill all the others
  local otherCyphernodeconf=$(docker ps | grep "cyphernodeconf" | awk '{ print $1 }');

  if [[ ! ''$otherCyphernodeconf == '' ]]; then
    docker rm -f $otherCyphernodeconf > /dev/null 2>&1
  fi

  local user=$(id -u):$(id -g)

  if [[ ! ''$CONFIGURE_AS_USER == '' ]]; then
      user=$CONFIGURE_AS_USER
      step "[32mconfigure[0m as user \"$CONFIGURE_AS_USER\""
  fi

  # configure features of cyphernode
  docker run -v $current_path:/data \
             -e DEFAULT_USER=$USER \
             -e DEFAULT_DATADIR_BASE=$HOME \
             -e SETUP_DIR=$SETUP_DIR \
             -e DEFAULT_CERT_HOSTNAME=$(hostname) \
             -e GATEKEEPER_VERSION=$GATEKEEPER_VERSION \
             -e TRAEFIK_VERSION=$TRAEFIK_VERSION \
             -e MOSQUITTO_VERSION=$MOSQUITTO_VERSION \
             -e TOR_VERSION=$TOR_VERSION \
             -e PROXY_VERSION=$PROXY_VERSION \
             -e NOTIFIER_VERSION=$NOTIFIER_VERSION \
             -e PROXYCRON_VERSION=$PROXYCRON_VERSION \
             -e OTSCLIENT_VERSION=$OTSCLIENT_VERSION \
             -e PYCOIN_VERSION=$PYCOIN_VERSION \
             -e POSTGRES_VERSION=$POSTGRES_VERSION \
             -e BITCOIN_VERSION=$BITCOIN_VERSION \
             -e LIGHTNING_VERSION=$LIGHTNING_VERSION \
             -e CONF_VERSION=$CONF_VERSION \
             -e SETUP_VERSION=$SETUP_VERSION \
             --log-driver=none$pw_env \
             --network none \
             --rm$interactive cyphernode/cyphernodeconf:$CONF_VERSION $user node index.js$recreate
  if [[ -f $cyphernodeconf_filepath/exitStatus.sh ]]; then
    . $cyphernodeconf_filepath/exitStatus.sh
    rm $cyphernodeconf_filepath/exitStatus.sh
  fi

  if [[ ! $EXIT_STATUS == 0 ]]; then
    exit 1
  fi
}

copy_file() {
  local doCopy=0
  local sourceFile=$1
  local targetFile=$2
  local sudo=''
  local createBackup=1

  if [[ $4 == 1 ]]; then
    sudo='sudo '
  fi

  if [[ ! ''$3 == '' ]]; then
    createBackup=$3
  fi

  if [[ ! -f $sourceFile ]]; then
    return 1;
  fi

  if [[ -f $targetFile ]]; then
    ${sudo}cmp --silent $sourceFile $targetFile
    if [[ $? == 1 ]]; then
      # different content
      if [[ $createBackup == 1 ]]; then
        step "   [32mcreate[0m backup of $targetFile "
        try ${sudo}cp $targetFile $targetFile-$(date +"%y-%m-%d-%T")
        next
      fi
      doCopy=1
    else
      echo "[36midentical[0m $sourceFile == $targetFile"
    fi
  else
    doCopy=1
  fi

  if [[ $doCopy == 1 ]]; then
    local basename=$(basename "$sourceFile")
    step "     [32mcopy[0m $sourceFile => $targetFile "
    try ${sudo}cp $sourceFile $targetFile
    next
  fi
}

create_user() {
  #check if user exists
  if [[ ! $RUN_AS_USER == $USER ]]; then
    id -u $RUN_AS_USER > /dev/null 2>&1
    if [[ $? == 1 ]]; then
      step "   [32mcreate[0m user $RUN_AS_USER "
      if [[ $(id -u) == 0 ]]; then
        try useradd $RUN_AS_USER
      else
        try sudo useradd $RUN_AS_USER
      fi
      next
    fi
  fi
}

process_bitcoinconf() {

  local bitcoinconf=$1

  # grep for prune entry and delete all whitespaces
  local pruneEntry=$(sudo_if_required grep -e ^prune $bitcoinconf | tr -d '[:space:]')
  local txindexEntry=$(sudo_if_required grep -e ^txindex $bitcoinconf | tr -d '[:space:]')
  local testnetEntry=$(sudo_if_required grep -e ^testnet $bitcoinconf | tr -d '[:space:]')
  local regtestEntry=$(sudo_if_required grep -e ^regtest $bitcoinconf | tr -d '[:space:]')

  local prune=0
  local txindex=0
  local testnet=0
  local regtest=0

  if [[ $pruneEntry =~ ^prune && ! $pruneEntry == 'prune=0' ]]; then
    prune=1
  fi

  if [[ $txindexEntry =~ ^txindex && ! $txindexEntry == 'txindex=0' ]]; then
    txindex=1
  fi

  if [[ $testnetEntry =~ ^testnet && ! $testnetEntry == 'testnet=0' ]]; then
    testnet=1
  fi

  if [[ $regtestEntry =~ ^regtest && ! $regtestEntry == 'regtest=0' ]]; then
    regtest=1
  fi
  #  prune &  txindex: 3
  # !prune &  txindex: 2
  #  prune & !txindex: 1
  # !prune & !txindex: 0
  echo $(($prune|$txindex<<1|$testnet<<2|$regtest<<3))
}


compare_bitcoinconf() {

  local new_bitcoinconf=$1
  local old_bitcoinconf=$2
  local status

  if [[ ! -f $old_bitcoinconf || ! -f $new_bitcoinconf ]]; then
    return 1
  fi


  local old_config=$(process_bitcoinconf $old_bitcoinconf )
  local new_config=$(process_bitcoinconf $new_bitcoinconf )

  local old_prune=$(($old_config&1))
  local old_txindex=$((($old_config>>1)&1))
  local old_testnet=$((($old_config>>2)&1))
  local old_regtest=$((($old_config>>3)&1))
  local new_prune=$(($new_config&1))
  local new_txindex=$((($new_config>>1)&1))
  local new_testnet=$((($new_config>>2)&1))
  local new_regtest=$((($new_config>>3)&1))


  if [[ $new_prune == 1 && $old_prune == 0 ]]; then
    # warn about data loss
    # ask for user permission
    status='dataloss'
  fi

  if [[ $new_txindex == 1 && $old_txindex == 0 ]]; then
    # warn about reindexing
    status='reindex'
  fi

  echo $status

}

install_docker() {
  if [ ! -d $GATEKEEPER_DATAPATH ]; then
    step "   [32mcreate[0m $GATEKEEPER_DATAPATH"
    sudo_if_required mkdir -p $GATEKEEPER_DATAPATH
    next
  fi

  if [[ ! -f $GATEKEEPER_DATAPATH/installation.json ]]; then
    # prevent mounting installation.json as a directory
    sudo_if_required touch $GATEKEEPER_DATAPATH/installation.json
  fi

  if [[ ! -d $GATEKEEPER_DATAPATH/certs ]]; then
    sudo_if_required mkdir -p $GATEKEEPER_DATAPATH/certs > /dev/null 2>&1
  fi

  if [[ ! -d $GATEKEEPER_DATAPATH/private ]]; then
    sudo_if_required mkdir -p $GATEKEEPER_DATAPATH/private > /dev/null 2>&1
  fi

  copy_file $cyphernodeconf_filepath/gatekeeper/default.conf $GATEKEEPER_DATAPATH/default.conf 1 $SUDO_REQUIRED
  copy_file $cyphernodeconf_filepath/gatekeeper/api.properties $GATEKEEPER_DATAPATH/api.properties 1 $SUDO_REQUIRED
  copy_file $cyphernodeconf_filepath/gatekeeper/keys.properties $GATEKEEPER_DATAPATH/keys.properties 1 $SUDO_REQUIRED
  copy_file $current_path/config.7z $GATEKEEPER_DATAPATH/config.7z 1 $SUDO_REQUIRED
  copy_file $current_path/client.7z $GATEKEEPER_DATAPATH/client.7z 1 $SUDO_REQUIRED
  copy_file $cyphernodeconf_filepath/gatekeeper/cert.pem $GATEKEEPER_DATAPATH/certs/cert.pem 1 $SUDO_REQUIRED
  copy_file $cyphernodeconf_filepath/gatekeeper/key.pem $GATEKEEPER_DATAPATH/private/key.pem 1 $SUDO_REQUIRED
  copy_file $cyphernodeconf_filepath/traefik/htpasswd $GATEKEEPER_DATAPATH/htpasswd 1 $SUDO_REQUIRED


  if [ ! -d $POSTGRES_DATAPATH ]; then
    step "   [32mcreate[0m $POSTGRES_DATAPATH"
    sudo_if_required mkdir -p $POSTGRES_DATAPATH/pgdata
    next
  fi


  if [ ! -d $LOGS_DATAPATH ]; then
    step "   [32mcreate[0m $LOGS_DATAPATH"
    sudo_if_required mkdir -p $LOGS_DATAPATH
    next
  fi


  if [ ! -d $TRAEFIK_DATAPATH ]; then
    step "   [32mcreate[0m $TRAEFIK_DATAPATH"
    sudo_if_required mkdir -p $TRAEFIK_DATAPATH
    next
  fi

  copy_file $cyphernodeconf_filepath/traefik/acme.json $TRAEFIK_DATAPATH/acme.json 1 $SUDO_REQUIRED
  copy_file $cyphernodeconf_filepath/traefik/traefik.toml $TRAEFIK_DATAPATH/traefik.toml 1 $SUDO_REQUIRED
  copy_file $cyphernodeconf_filepath/traefik/htpasswd $TRAEFIK_DATAPATH/htpasswd 1 $SUDO_REQUIRED


  if [[ $FEATURE_TOR == true ]]; then
    if [ ! -d $TOR_DATAPATH ]; then
      step "   [32mcreate[0m $TOR_DATAPATH"
      sudo_if_required mkdir -p $TOR_DATAPATH
      sudo_if_required chmod 700 $TOR_DATAPATH
      next
    fi
    if [[ $TOR_TRAEFIK == true ]]; then
      if [ ! -d $TOR_DATAPATH/traefik ]; then
        step "   [32mcreate[0m $TOR_DATAPATH/traefik"
        sudo_if_required mkdir -p $TOR_DATAPATH/traefik/hidden_service
        sudo_if_required chmod 700 $TOR_DATAPATH/traefik/hidden_service
        next
      fi
    fi
    if [[ $TOR_LIGHTNING == true ]]; then
      if [ ! -d $TOR_DATAPATH/lightning ]; then
        step "   [32mcreate[0m $TOR_DATAPATH/lightning"
        sudo_if_required mkdir -p $TOR_DATAPATH/lightning/hidden_service
        sudo_if_required chmod 700 $TOR_DATAPATH/lightning/hidden_service
        next
      fi
    fi
    if [[ $TOR_BITCOIN == true ]]; then
      if [ ! -d $TOR_DATAPATH/bitcoin ]; then
        step "   [32mcreate[0m $TOR_DATAPATH/bitcoin"
        sudo_if_required mkdir -p $TOR_DATAPATH/bitcoin/hidden_service
        sudo_if_required chmod 700 $TOR_DATAPATH/bitcoin/hidden_service
        next
      fi
    fi

    copy_file $cyphernodeconf_filepath/tor/torrc $TOR_DATAPATH/torrc 1 $SUDO_REQUIRED
    copy_file $cyphernodeconf_filepath/tor/traefik/hidden_service/hs_ed25519_secret_key $TOR_DATAPATH/traefik/hidden_service/hs_ed25519_secret_key 1 $SUDO_REQUIRED
    copy_file $cyphernodeconf_filepath/tor/traefik/hidden_service/hs_ed25519_public_key $TOR_DATAPATH/traefik/hidden_service/hs_ed25519_public_key 1 $SUDO_REQUIRED
    copy_file $cyphernodeconf_filepath/tor/traefik/hidden_service/hostname $TOR_DATAPATH/traefik/hidden_service/hostname 1 $SUDO_REQUIRED

    if [[ $TOR_LIGHTNING == true ]]; then
      copy_file $cyphernodeconf_filepath/tor/lightning/hidden_service/hs_ed25519_secret_key $TOR_DATAPATH/lightning/hidden_service/hs_ed25519_secret_key 1 $SUDO_REQUIRED
      copy_file $cyphernodeconf_filepath/tor/lightning/hidden_service/hs_ed25519_public_key $TOR_DATAPATH/lightning/hidden_service/hs_ed25519_public_key 1 $SUDO_REQUIRED
      copy_file $cyphernodeconf_filepath/tor/lightning/hidden_service/hostname $TOR_DATAPATH/lightning/hidden_service/hostname 1 $SUDO_REQUIRED
    fi
    if [[ $TOR_BITCOIN == true ]]; then
      copy_file $cyphernodeconf_filepath/tor/bitcoin/hidden_service/hs_ed25519_secret_key $TOR_DATAPATH/bitcoin/hidden_service/hs_ed25519_secret_key 1 $SUDO_REQUIRED
      copy_file $cyphernodeconf_filepath/tor/bitcoin/hidden_service/hs_ed25519_public_key $TOR_DATAPATH/bitcoin/hidden_service/hs_ed25519_public_key 1 $SUDO_REQUIRED
      copy_file $cyphernodeconf_filepath/tor/bitcoin/hidden_service/hostname $TOR_DATAPATH/bitcoin/hidden_service/hostname 1 $SUDO_REQUIRED
    fi
  fi


  if [ ! -d $PROXY_DATAPATH ]; then
    step "   [32mcreate[0m $PROXY_DATAPATH"
    sudo_if_required mkdir -p $PROXY_DATAPATH
    next
  fi

  if [ ! -d $current_path/.env ]; then
    step "   [32mcreate[0m ${current_path}/.env"
    sudo_if_required mkdir -p ${current_path}/.env
    next
  fi

  copy_file $cyphernodeconf_filepath/installer/config.sh $PROXY_DATAPATH/config.sh 1 $SUDO_REQUIRED
  copy_file $cyphernodeconf_filepath/cyphernode/info.json $PROXY_DATAPATH/info.json 1 $SUDO_REQUIRED
  copy_file $cyphernodeconf_filepath/postgres/pgpass $PROXY_DATAPATH/pgpass 1 $SUDO_REQUIRED
  sudo_if_required chmod 0600 $PROXY_DATAPATH/pgpass
  copy_file $cyphernodeconf_filepath/proxycron/proxycron.env ${current_path}/.env/proxycron.env 1 $SUDO_REQUIRED

  if [[ $BITCOIN_INTERNAL == true ]]; then
    if [ ! -d $BITCOIN_DATAPATH ]; then
      step "   [32mcreate[0m $BITCOIN_DATAPATH"
      sudo_if_required mkdir -p $BITCOIN_DATAPATH
      next
    fi
    if [ -d $BITCOIN_DATAPATH ]; then

      local cmpStatus=$(compare_bitcoinconf $cyphernodeconf_filepath/bitcoin/bitcoin.conf $BITCOIN_DATAPATH/bitcoin.conf)

      if [[ $cmpStatus == 'dataloss' ]]; then
        if [[ $ALWAYSYES == 1 ]]; then
          copy_file $cyphernodeconf_filepath/bitcoin/bitcoin.conf $BITCOIN_DATAPATH/bitcoin.conf 1 $SUDO_REQUIRED
          copy_file $cyphernodeconf_filepath/bitcoin/bitcoin-client.conf $BITCOIN_DATAPATH/bitcoin-client.conf 1 $SUDO_REQUIRED
        else
          while true; do
            echo "          [31mReally copy bitcoin.conf with pruning option?[0m"
            read -p "          [31mThis will discard some blockchain data. (yn)[0m " yn
            case $yn in
              [Yy]* ) copy_file $cyphernodeconf_filepath/bitcoin/bitcoin.conf $BITCOIN_DATAPATH/bitcoin.conf 1 $SUDO_REQUIRED
                      copy_file $cyphernodeconf_filepath/bitcoin/bitcoin-client.conf $BITCOIN_DATAPATH/bitcoin-client.conf 1 $SUDO_REQUIRED
                      break;;
              [Nn]* ) copy_file $cyphernodeconf_filepath/bitcoin/bitcoin.conf $BITCOIN_DATAPATH/bitcoin.conf.cyphernode 0 $SUDO_REQUIRED
                      copy_file $cyphernodeconf_filepath/bitcoin/bitcoin-client.conf $BITCOIN_DATAPATH/bitcoin-client.conf.cyphernode 0 $SUDO_REQUIRED
                      echo "          [31mYour cyphernode installation is most likely broken.[0m"
                      echo "          [31mPlease check bitcoin.conf.cyphernode on how to repair it manually.[0m";
                      break;;
              * ) echo "Please answer yes or no.";;
            esac
          done
        fi
      else
        if [[ $cmpStatus == 'reindex' ]]; then
          echo "  [33mWarning[0m Reindexing will take some time."
        fi
        copy_file $cyphernodeconf_filepath/bitcoin/bitcoin.conf $BITCOIN_DATAPATH/bitcoin.conf 1 $SUDO_REQUIRED
        copy_file $cyphernodeconf_filepath/bitcoin/bitcoin-client.conf $BITCOIN_DATAPATH/bitcoin-client.conf 1 $SUDO_REQUIRED
      fi
    fi

    copy_file $cyphernodeconf_filepath/bitcoin/entrypoint.sh $BITCOIN_DATAPATH/entrypoint.sh 1 $SUDO_REQUIRED
    copy_file $cyphernodeconf_filepath/bitcoin/createWallets.sh $BITCOIN_DATAPATH/createWallets.sh 1 $SUDO_REQUIRED

    if [[ ! -x $BITCOIN_DATAPATH/entrypoint.sh ]]; then
      step "     [32mmake[0m entrypoint.sh executable"
      sudo_if_required chmod +x $BITCOIN_DATAPATH/entrypoint.sh
      next
    fi
    if [[ ! -x $BITCOIN_DATAPATH/createWallets.sh ]]; then
      step "     [32mmake[0m createWallets.sh executable"
      sudo_if_required chmod +x $BITCOIN_DATAPATH/createWallets.sh
      next
    fi
  fi

  if [[ $FEATURE_LIGHTNING == true ]]; then
    if [[ $LIGHTNING_IMPLEMENTATION == "c-lightning" ]]; then
      if [ ! -d $LIGHTNING_DATAPATH/bitcoin ]; then
        step "   [32mcreate[0m $LIGHTNING_DATAPATH"
        sudo_if_required mkdir -p $LIGHTNING_DATAPATH/bitcoin
        next
      fi

      copy_file $cyphernodeconf_filepath/lightning/c-lightning/config $LIGHTNING_DATAPATH/config 1 $SUDO_REQUIRED
      copy_file $cyphernodeconf_filepath/lightning/c-lightning/entrypoint.sh $LIGHTNING_DATAPATH/bitcoin/entrypoint.sh 1 $SUDO_REQUIRED

      if [[ ! -x $LIGHTNING_DATAPATH/bitcoin/entrypoint.sh ]]; then
        step "     [32mmake[0m entrypoint.sh executable"
        sudo_if_required chmod +x $LIGHTNING_DATAPATH/bitcoin/entrypoint.sh
        next
      fi
    fi
  fi

  if [[ $FEATURE_OTSCLIENT == true ]]; then
    if [ ! -d $OTSCLIENT_DATAPATH ]; then
      step "   [32mcreate[0m $OTSCLIENT_DATAPATH"
      sudo_if_required mkdir -p $OTSCLIENT_DATAPATH
      next
    fi
  fi

  docker swarm join-token worker > /dev/null 2>&1
  local noSwarm=$?;

  if [[ $DOCKER_MODE == 'swarm' ]]; then
    if [[ $noSwarm == 1 ]]; then
      step "     [32minit[0m docker swarm"
      try docker swarm init --task-history-limit 1 > /dev/null 2>&1
      next
    fi

    local localnodeid
    localnodeid=$(docker info -f '{{.Swarm.NodeID}}')

    # we only support swarm in single host mode, so all labels needed to spawn containers in the swarm
    # are given to the host setup is run on. Setup must be run on any manager, if swarm mode is enabled
    # and a swarm was already initialised
    if [[ $(docker node inspect ${localnodeid} --format '{{ index .Spec.Labels "io.cyphernode" }}') != "true" ]]; then
      step "      [32madd[0m docker node label io.cyphernode"
      try docker node update --label-add io.cyphernode=true ${localnodeid} > /dev/null 2>&1
      next
    fi
  fi

  local net_entry=$(docker network ls | grep cyphernodenet);

  if [[ $net_entry =~ 'cyphernodenet' ]]; then
    if [[ $net_entry =~ 'local' && $DOCKER_MODE == 'swarm' ]]; then
      step " [32mrecreate[0m cyphernode network"
      try docker network rm cyphernodenet > /dev/null 2>&1
      try docker network create -d overlay --attachable --opt encrypted cyphernodenet > /dev/null 2>&1
      next
    elif [[ $net_entry =~ 'swarm' && $DOCKER_MODE == 'compose' ]]; then
      step " [32mrecreate[0m cyphernode network"
      try docker network rm cyphernodenet > /dev/null 2>&1
      try docker network create cyphernodenet > /dev/null 2>&1
      next
    fi
  else
    if [[ $DOCKER_MODE == 'swarm' ]]; then
      step "   [32mcreate[0m cyphernode network"
      try docker network create -d overlay --attachable --opt encrypted cyphernodenet > /dev/null 2>&1
      next
    elif [[ $DOCKER_MODE == 'compose' ]]; then
      step "   [32mcreate[0m cyphernode network"
      try docker network create cyphernodenet > /dev/null 2>&1
      next
    fi
  fi

  local appsnet_entry=$(docker network ls | grep cyphernodeappsnet);

  if [[ $appsnet_entry =~ 'cyphernodeappsnet' ]]; then
    if [[ $appsnet_entry =~ 'local' && $DOCKER_MODE == 'swarm' ]]; then
      step " [32mrecreate[0m cyphernode apps network"
      try docker network rm cyphernodeappsnet > /dev/null 2>&1
      try docker network create -d overlay --attachable --opt encrypted cyphernodeappsnet > /dev/null 2>&1
      next
    elif [[ $appsnet_entry =~ 'swarm' && $DOCKER_MODE == 'compose' ]]; then
      step " [32mrecreate[0m cyphernode apps network"
      try docker network rm cyphernodeappsnet > /dev/null 2>&1
      try docker network create cyphernodeappsnet > /dev/null 2>&1
      next
    fi
  else
    if [[ $DOCKER_MODE == 'swarm' ]]; then
      step "   [32mcreate[0m cyphernode apps network"
      try docker network create -d overlay --attachable --opt encrypted cyphernodeappsnet > /dev/null 2>&1
      next
    elif [[ $DOCKER_MODE == 'compose' ]]; then
      step "   [32mcreate[0m cyphernode apps network"
      try docker network create cyphernodeappsnet > /dev/null 2>&1
      next
    fi
  fi

  copy_file $cyphernodeconf_filepath/installer/docker/docker-compose.yaml $current_path/docker-compose.yaml
  copy_file $cyphernodeconf_filepath/installer/testfeatures.sh $current_path/testfeatures.sh 0
  copy_file $cyphernodeconf_filepath/installer/start.sh $current_path/start.sh 0
  copy_file $cyphernodeconf_filepath/installer/stop.sh $current_path/stop.sh 0
  copy_file $cyphernodeconf_filepath/installer/testdeployment.sh $current_path/testdeployment.sh 0

   if ${sudo} [ ! -x $current_path/start.sh ]; then
    step "     [32mmake[0m start.sh executable"
    sudo_if_required chown -R $USER $current_path/start.sh
    sudo_if_required chmod +x $current_path/start.sh
    next
  fi

  if ${sudo} [ ! -x $current_path/stop.sh ]; then
    step "     [32mmake[0m stop.sh executable"
    sudo_if_required chown -R $USER $current_path/stop.sh
    sudo_if_required chmod +x $current_path/stop.sh
    next
  fi

  if ${sudo} [ ! -x $current_path/testfeatures.sh ]; then
    step "     [32mmake[0m testfeatures.sh executable"
    sudo_if_required chown -R $USER $current_path/testfeatures.sh
    sudo_if_required chmod +x $current_path/testfeatures.sh
    next
  fi

  if ${sudo} [ ! -x $current_path/testdeployment.sh ]; then
    step "     [32mmake[0m testdeployment.sh executable"
    sudo_if_required chown -R $USER $current_path/testdeployment.sh
    sudo_if_required chmod +x $current_path/testdeployment.sh
    next
  fi
}

check_directory_owner() {
  # if one directory does not have access rights for $RUN_AS_USER, we echo 1, else we echo 0
  local directories=("${current_path}/.env" "$BITCOIN_DATAPATH" "$LIGHTNING_DATAPATH" "$PROXY_DATAPATH" "$GATEKEEPER_DATAPATH" "$POSTGRES_DATAPATH" "$LOGS_DATAPATH" "$TRAEFIK_DATAPATH" "$TOR_DATAPATH")
  local status=0
  for d in "${directories[@]}"
  do
    if [[ ''$d == '' ]]; then
      continue
    fi
    d=$(realpath $d)
    if [[ -e $d ]]; then
      # is it mine and does it have rw ?
      # don't care about group rights
      if [[ ! -r $d || ! -w $d ]]; then
        status=1
        break;
      fi
    else
      # does parent exist and do we have rw on that?
      local parentDir=$(dirname $d)
      while [[ ! $parentDir == '/' && ! -e $parentDir ]]; do
        parentDir=$(dirname $parentDir)
      done
      if [[ ! -r $parentDir || ! -w $parentDir ]]; then
        status=1
      fi
    fi
  done
  echo $status
}

check_bitcoind() {
  echo 0
}

realpath() {
  [[ $1 = /* ]] && echo "$1" || echo "$PWD/${1#./}"
}


check_docker() {
  if ! [ -x "$(command -v docker)" ]; then
    echo "          [31mdocker is not installed on your system. Please check https://www.docker.com/get-started.[0m"
    exit
  fi
}

check_docker_compose() {
  if ! [ -x "$(command -v docker-compose)" ]; then
    echo "          [31mdocker-compose is not installed on your system. Please check https://docs.docker.com/compose/install/.[0m"
    exit
  fi
}

sanity_checks_pre_config() {
  echo "    [32mcheck[0m requirements for configuration step."
  check_docker
}

sanity_checks_pre_install() {

  echo "    [32mcheck[0m requirements for installation step."

  check_docker
  if [[ $DOCKER_MODE == 'compose' ]]; then
    check_docker_compose
  fi

  local OS=$(uname -s)

  if [[ ''$RUN_AS_USER == '' ]]; then
    RUN_AS_USER=$USER
  elif [[ $OS == 'Darwin' ]]; then
    echo "          Run as user option is not supported on OSX.[0m"
    echo "          [33mPlease run start.sh later as the user you are running this setup utility under.[0m"
    RUN_AS_USER=$USER
  fi

  local sudo=0
  local sudo_reason

  if [[ ! ''$RUN_AS_USER == ''$USER ]]; then
    sudo=1
    sudo_reason='user'
  fi

  if [[ $sudo == 0 ]]; then
    # we still don't need sudo. Let's check access to directories
    sudo=$(check_directory_owner)
    sudo_reason='directories'
  fi

  if [[ $sudo == 1 ]]; then
    echo "    [32mcheck[0m Cyphernode installer has determined that it needs sudo to continue."
    echo "          Let's verify that you have sudo rights..."
    sudo echo "     [32mYes![0m You have what it takes to run cyphernode."

    if [[ $? == 1 ]]; then
      echo "   [31mAARGH![0m Mein Leben..."
      echo "          [31mTo fix this, either ask your administrator to add you to the sudo group[0m"
      if [[ $sudo_reason == 'user' ]]; then
        echo "          [31mor do not use the 'run as different user' option.[0m"
      fi
      if [[ $sudo_reason == 'directories' ]]; then
        echo "          [31mor check your data volumes if they have the right owner.[0m"
        echo "          [31mThe owner of the following folders should be '$RUN_AS_USER':[0m"
        local directories=("$BITCOIN_DATAPATH" "$LIGHTNING_DATAPATH" "$PROXY_DATAPATH" "$GATEKEEPER_DATAPATH" "$POSTGRES_DATAPATH" "$LOGS_DATAPATH" "$TRAEFIK_DATAPATH" "$TOR_DATAPATH")
          local status=0
          for d in "${directories[@]}"
          do
            if [[ -e $d ]]; then
              echo "          [31m$d[0m"
            fi
          done
      fi

      exit
    else
      SUDO_REQUIRED=1
    fi
  else
    echo "    [32mnice![0m everything seems to be ok."
  fi
}

install_apps() {
  if [ ! -d "$current_path/apps" ]; then
    local user=$(id -u $RUN_AS_USER):$(id -g $RUN_AS_USER)
    local apps_repo="https://github.com/SatoshiPortal/cypherapps.git"
    echo "   [32mclone[0m $apps_repo into apps"
    docker run --rm -v "$current_path":/git --entrypoint sh cyphernode/cyphernodeconf:$CONF_VERSION -c "git clone --single-branch -b ${CYPHERAPPS_VERSION} \"$apps_repo\" /git/apps > /dev/null 2>&1 ; chown -R $user /git/apps"
  fi

  if [[ $FEATURE_LIGHTNING == true ]]; then
    if [ -d "$current_path/apps/sparkwallet" ]; then
      step "   [32mdelete[0m ignoreThisApp for enabled Sparkwallet"
      sudo_if_required rm -f $current_path/apps/sparkwallet/ignoreThisApp
      next
    fi
  else
    if [ -d "$current_path/apps/sparkwallet" ]; then
      step "   [32mcreate[0m ignoreThisApp for disabled Sparkwallet"
      sudo_if_required touch $current_path/apps/sparkwallet/ignoreThisApp
      next
    fi
  fi

  if [[ $FEATURE_BATCHER == true ]]; then
    if [ -d "$current_path/apps/batcher" ]; then
      step "   [32mdelete[0m ignoreThisApp for enabled Batcher"
      sudo_if_required rm -f $current_path/apps/batcher/ignoreThisApp
      next
    fi
  else
    if [ -d "$current_path/apps/batcher" ]; then
      step "   [32mcreate[0m ignoreThisApp for disabled Batcher"
      sudo_if_required touch $current_path/apps/batcher/ignoreThisApp
      next
    fi
  fi

  if [[ $FEATURE_SPECTER == true ]]; then
    if [ -d "$current_path/apps/specter" ]; then
      step "   [32mdelete[0m ignoreThisApp for enabled Specter"
      sudo_if_required rm -f $current_path/apps/specter/ignoreThisApp
      next
    fi
  else
    if [ -d "$current_path/apps/specter" ]; then
      step "   [32mcreate[0m ignoreThisApp for disabled Specter"
      sudo_if_required touch $current_path/apps/specter/ignoreThisApp
      next
    fi
  fi
}

install() {
  if [[ ''$INSTALLER_MODE == 'none' ]]; then
    echo "Skipping installation phase"
  elif [[ ''$INSTALLER_MODE == 'docker' ]]; then
    install_docker
  fi
}

CONFIGURE=0
INSTALL=0
RECREATE=0
TRACING=1
ALWAYSYES=0
SUDO_REQUIRED=0
AUTOSTART=0

# CYPHERNODE VERSION "v0.8.1"
SETUP_VERSION="v0.8.1"
CONF_VERSION="v0.8.1"
GATEKEEPER_VERSION="v0.8.1"
TOR_VERSION="v0.8.1"
PROXY_VERSION="v0.8.1"
NOTIFIER_VERSION="v0.8.1"
PROXYCRON_VERSION="v0.8.1"
OTSCLIENT_VERSION="v0.8.1"
PYCOIN_VERSION="v0.8.1"
CYPHERAPPS_VERSION="v0.8.1"
BITCOIN_VERSION="v22.0"
LIGHTNING_VERSION="v0.10.2"
TRAEFIK_VERSION="v1.7.9-alpine"
MOSQUITTO_VERSION="1.6-openssl"
POSTGRES_VERSION="14.0-bullseye"

SETUP_DIR=$(dirname $(realpath $0))

# trap ctrl-c and call ctrl_c()
trap ctrl_c INT

function ctrl_c() {
  echo "          [31mCanceling installation process.[0m"
  exit
}

export current_path="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"
export cyphernodeconf_filepath="$current_path/.cyphernodeconf"

while getopts ":cirhys" opt; do
  case $opt in
    r)
      RECREATE=1
      ;;
    c)
      CONFIGURE=1
      ;;
    i)
      INSTALL=1
      ;;
    y)
      ALWAYSYES=1
      ;;
    s)
      AUTOSTART=1
      ;;
    h)
      echo "-c configure" >&2
      echo "-r recreate" >&2
      echo "-i install" >&2
      echo "-y assume yes to all questions" >&2
      echo "-s autostart" >&2
      exit
      ;;
    \?)
      echo "Invalid option: -$OPTARG. Use -c to configure and -i to install or -r to recreate from config.json." >&2
      ;;
  esac
done

nbbuiltimgs=$(docker images --filter=reference='cyphernode/*:*-local' | wc -l)
if [[ $nbbuiltimgs -gt 1 ]]; then
  read -p "Locally built Cyphernode images found!  Do you want to use them?  [yn] " -n 1 -r

  if [[ $REPLY =~ ^[Yy]$ ]]; then
    CONF_VERSION="$CONF_VERSION-local"
    GATEKEEPER_VERSION="$GATEKEEPER_VERSION-local"
    TOR_VERSION="$TOR_VERSION-local"
    PROXY_VERSION="$PROXY_VERSION-local"
    NOTIFIER_VERSION="$NOTIFIER_VERSION-local"
    PROXYCRON_VERSION="$PROXYCRON_VERSION-local"
    OTSCLIENT_VERSION="$OTSCLIENT_VERSION-local"
    PYCOIN_VERSION="$PYCOIN_VERSION-local"
  fi
fi

if [[  $CONFIGURE == 0 && $INSTALL == 0 && $RECREATE == 0 ]]; then
  CONFIGURE=1
  INSTALL=1
fi

if [[ $CONFIGURE == 1 ]]; then
  sanity_checks_pre_config
  configure $RECREATE
fi

if [[ -f "$cyphernodeconf_filepath/installer/config.sh" ]]; then
  . "$cyphernodeconf_filepath/installer/config.sh"
fi

if [[ $CLEANUP == 'true' && $(docker image ls | grep cyphernodeconf) =~ cyphernodeconf ]]; then
  step "    [32mclean[0m cyphernodeconf image"
  try docker image rm cyphernodeconf > /dev/null 2>&1
  next
fi

if [[ $INSTALL == 1 ]]; then
  sanity_checks_pre_install
  create_user
  install
  install_apps
  modify_owner
  modify_permissions
  if [[ ! $AUTOSTART == 1 ]]; then
    cowsay
  fi

fi

if [[ $AUTOSTART == 1 ]]; then
  exec $current_path/start.sh
fi
