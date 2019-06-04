## Supported tags and respective `Dockerfile` links
* `latest` ([Dockerfile](https://github.com/TritonNetwork/TritonDocker/blob/master/Dockerfile))
* `most_recent_tag` ([Dockerfile](https://github.com/TritonNetwork/TritonDockerblob/most_recent_tag/Dockerfile))
* `v4.0.3` ([Dockerfile](https://github.com/TritonNetwork/TritonDocker/blob/most_recent_tag/Dockerfile))

---

For running `tritond` or `triton-wallet-rpc` or `triton-wallet-cli` in a docker container.

This daemon is built from source: [triton project](https://github.com/TritonNetwork/TritonProtocol).

* triton stable for `stagenet`/`mainnet`: Use version tags like `v4.0.3`.
* `testnet`: Use the `master` tag.
  - Generally, it is recommended to use `master` branch when working on `testnet`.
  - Of course, `latest` can also be used with `mainnet` and `stagenet`.
* The `latest` docker image is based on `master` branch.
* triton tools can also be used through the Tor network, see **Tor software** below.

## system and binary information

You can find the following information within the docker image:
* `/version.txt` contains output of `tritond --version`
* `/system.txt` contains output of `cat /etc/os-release`
* `/dependencies.txt` contains output of `ldd $(command -v tritond)`
* `/torsocks.txt` contains output of `torsocks --version`
* `/tor.txt` contains output of `tor --version`

## default configuration

* docker container user running `triton`
  - `USER_ID` can be used to set the user who runs `triton`
    + `-e USER_ID=1000`
  - The container can also be started with `--user 1000`
    + No existing user is used then
  - Running `triton` as `root` is not possible (`USER_ID` defaults to 1000).
* `tritond` and `triton-wallet-rpc`
  - `--log-level=$LOG_LEVEL` (**default**: `0`) (also `triton-wallet-cli`)
  - `--confirm-external-bind`
  - `--rpc-bind-ip=$RPC_BIND_IP` (**default**: `0.0.0.0`)
  - `--rpc-bind-port=$RPC_BIND_PORT` (**default**: `28081`)
  - `--rpc-login $RPC_USER:$RPC_PASSWD` (**default RPC_USER**: `""`, **default RPC_PASSWD**: `""`)
    + For **authentication**, please see below.
* only `tritond`
  - `--p2p-bind-ip=$P2P_BIND_IP` (**default**: `0.0.0.0`)
  - `--p2p-bind-port=$P2P_BIND_PORT` (**default**: `28080`)
* only `triton-wallet-rpc` and `triton-wallet-cli`  
  - `--daemon-host=$DAEMON_HOST` (**default**: `127.0.0.1`)
  - `--daemon-port=$DAEMON_PORT` (**default**: `28081`)
  - `--password=$WALLET_PASSWD` (**default**: `""`)
    + For **wallet password**, please see below.
* Adapt default configuration using environment variables:
  - `-e LOG_LEVEL=3`
  - `-e RPC_USER=user`
  - `-e RPC_PASSWD=passwd`
  - `-e RPC_BIND_IP=127.0.0.1`
  - `-e RPC_BIND_PORT=9231`
  - `-e P2P_BIND_IP=0.0.0.0`
  - `-e P2P_BIND_PORT=9230`
  - `-e DAEMON_HOST=localhost` (assuming daemon is running locally)
  - `-e DAEMON_PORT=9231` (assuming daemon listens on port `9231`)
* Using `tritond`, `triton-wallet-rpc` and `triton-wallet-cli` with `torsocks`:
  - `-e USE_TORSOCKS=YES` (**default**: `NO`)
* Running the Tor proxy (`tor`) within the container:
  - `-e USE_TOR=YES` (**default**: `NO`)

### hint:
* The IPs, the daemon or RPC are binding to, need to be `0.0.0.0` instead of `127.0.0.1` within a docker container.
* The path `/triton` in the docker container is a volume and can be mapped to a path on the client.

Check the repository for `docker-compose` templates. They show configuration examples of `tritond` and `triton-wallet-rpc`, respectively.

### authentication

Authentication can be activated for `tritond` and `triton-wallet-rpc`.

If the environment variables `RPC_USER` and `RPC_PASSWD` are set, the container's entrypoint script adds the option `--rpc-login $RPC_USER:$RPC_PASSWD`.

If you don't provide user and password, you have two options:
* Add `--disable-rpc-login` when starting the container to remove authentication.
* Use the default user `triton`, password is a randomly generated string. In this case, the login information is written into a file:
  ```bash
  # log message on starting triton-walet-rpc
  WARN 	wallet.rpc	src/wallet/wallet_rpc_server.cpp:225	RPC username/password is stored in file triton-wallet-rpc.38083.login
  # example output
  triton:6xsMGa/BPkHJJvf0y+fYRg==root@78b746205a4b
  ```
  - You can get the information like this:
  ```bash
  docker exec rpc_user cat /triton/triton-wallet-rpc.38083.login
  ```

Example requesting the rpc:
```
    curl -u user:password --digest http://localhost:9231
```

It is always recommended to use RPC authentication.

### wallet password

The wallet password can be configured for `triton-wallet-cli` and `triton-wallet-rpc`.

If the environment variable `WALLET_PASSWD` is set, the container's entrypoint script adds the option `--password $WALLET_PASSWD`.

If you don't provide a wallet password that way:
* You could set `--password-file wallet.passwd` and add a file containing the wallet password to the mounted voume.

It is always recommended to use a wallet password.

### raw commands

It is also possible to deactivate the entrpoint script.

This way, it is possible to define and configure e.g. the `triton-wallet-rpc` yourself:
```
docker run --rm -d --net host -v <path/to/and/including/wallet_folder>:/triton --entrypoint="" harrisonxtri/triton triton-wallet-rpc --log-level 2 --daemon-host sanfran.xtri.network --daemon-port 9231 --confirm-external-bind --rpc-login user:passwd --rpc-bind-ip 0.0.0.0 --rpc-bind-port 92304 --wallet-file wallet --password-file wallet.passwd
```

## tritond

Without any additional command

`docker run --rm -it harrisonxtri/triton`

`tritond` starts with the above default configuration plus the following option:
* `--check-updates disabled`

Any additional `tritond` parameters can be passed as command:

```
docker run --rm -d -p 9231:9231 -v <path/to/and/including/.triton>:/triton harrisonxtri/triton --data-dir /triton --non-interactive
```

### user
Run `tritond` as different user (`uid != 1000 && uid != 0`). This is useful if deployed to several systems (AWS ec2-user: `uid=500`).

Abbreviated command:

```
docker run --rm -d -p 9231:9231 -e USER_ID=500 -v <host>:<container> harrisonxtri/triton <options>
```

### hint
The path `/triton` is supposed to be used as `--data-dir` configuration for `tritond`. Here the synchronized blockchain data is stored. So when mounted, `/triton` should contain the files from within `.triton`.


## triton-wallet-rpc
When used as `triton-wallet-rpc` the full command is necessary as command to docker run:

Passing the pasword as environment variable:
```
docker run --rm -d --net host -e DAEMON_HOST=sanfran.xtri.network -e DAEMON_PORT=9231 -e RPC_BIND_PORT=9230 -e RPC_USER=user -e RPC_PASSWD=passwd -e WALLET_PASSWD=securePasswd -v <path/to/and/including/wallet_folder>:/triton harrisonxtri/triton triton-wallet-rpc  --wallet-file wallet
```

Using a password file:
```
docker run --rm -d --net host -e DAEMON_HOST=sanfran.xtri.network -e DAEMON_PORT=9231 -e RPC_BIND_PORT=92303 -e RPC_USER=user -e RPC_PASSWD=passwd -v <path/to/and/including/wallet_folder>:/triton harrisonxtri/triton triton-wallet-rpc  --wallet-file wallet --password-file wallet.passwd
```

### user
Run `triton-wallet-rpc` as different user (`uid != 1000 && uid != 0`). This is useful if deployed to several systems (AWS ec2-user: `uid=500`).

Abbreviated command:

```
docker run --rm -d --net host -e DAEMON_HOST=sanfran.xtri.network -e DAEMON_PORT=9231 -e RPC_BIND_PORT=92303 -e USER_ID=500 -v <host>:<container> harrisonxtri/triton triton-wallet-rpc <options>
```

### rpc
`triton-wallet-rpc` starts with the above default configuration plus additional options passed in the actual docker run command, like `-e RPC_BIND_PORT=92303`.


### hint
The path `/triton` is supposed to contain the actual wallet files. So when mounted, `/triton` should contain the files from within e.g. `~/triton/wallets/my_wallet/`.


## triton-wallet-cli

When used as `triton-wallet-cli` the full command is necessary as command to docker run:

```
docker run --rm -it -e DAEMON_HOST=sanfran.xtri.network -e DAEMON_PORT=9231 -v <path/to/and/including/wallet_folder>:/triton --net host harrisonxtri/triton triton-wallet-cli --wallet-file wallet --password-file wallet.passwd
```

Due to `-it` (interactive terminal), you will end up within the container and can use the `triton-wallet-cli` commands.

### user
Run `triton-wallet-cli` as different user (`uid != 1000 && uid != 0`). This is useful if deployed to several systems (AWS ec2-user: `uid=500`).

Abbreviated command:

```
docker run --rm -it --net host -e DAEMON_HOST=sanfran.xtri.network -e DAEMON_PORT=9231 -e USER_ID=500 -v <host>:<container> harrisonxtri/triton triton-wallet-cli <options>
```

### hint
The path `/triton` is supposed to contain the actual wallet files. So when mounted, `/triton` should contain the files from within e.g. `~/triton/wallets/my_wallet/`.
