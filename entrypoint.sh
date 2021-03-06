#!/bin/bash

LOGGING="--log-level $LOG_LEVEL"

DAEMON_OPTIONS="--daemon-host $DAEMON_HOST --daemon-port $DAEMON_PORT"

# rpc login options
if [ -n "$RPC_USER" -a -n "$RPC_PASSWD" ]; then
  RPC_LOGIN="--rpc-login $RPC_USER:$RPC_PASSWD"
fi

if [ -n "$WALLET_PASSWD" ]; then
  WALLET_ACCESS="--password $WALLET_PASSWD"
fi

# used for monerod and monero-wallet-rpc
RPC_OPTIONS="$LOGGING $RPC_LOGIN --confirm-external-bind --rpc-bind-ip $RPC_BIND_IP --rpc-bind-port $RPC_BIND_PORT"
# used for monerod
TRITOND_OPTIONS="--p2p-bind-ip $P2P_BIND_IP --p2p-bind-port $P2P_BIND_PORT"

TRITOND="tritond $@ $RPC_OPTIONS $TRITOND_OPTIONS --check-updates disabled"

# COMMAND="$@"

if [[ "${1:0:1}" = '-' ]]  || [[ -z "$@" ]]; then
  set -- $TRITOND
elif [[ "$1" = triton-wallet-rpc* ]]; then
  set -- "$@ $WALLET_ACCESS $DAEMON_OPTIONS $RPC_OPTIONS"
elif [[ "$1" = triton-wallet-cli* ]]; then
  set -- "$@ $WALLET_ACCESS $DAEMON_OPTIONS $LOGGING"
fi

if [ "$USE_TOR" == "YES" ]; then
  chown -R debian-tor /var/lib/tor
  # run as daemon
  tor -f /etc/tor/torrc
fi

if [ "$USE_TORSOCKS" == "YES" ]; then
  set -- "torsocks $@"
fi

# allow the container to be started with `--user
if [ "$(id -u)" = 0 ]; then
  # USER_ID defaults to 1000 (Dockerfile)
  adduser --system --group --uid "$USER_ID" --shell /bin/false triton &> /dev/null
  exec su-exec triton $@
fi

exec $@
