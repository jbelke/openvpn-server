# JBelke/openvpn-server

Faster Docker-Compose container with OpenVPN Server living inside with Start-Stop script and backup scripts and enhanced configuration.
Forked from [d3vilh/openvpn-server](https://github.com/d3vilh/openvpn-server).

[![latest version](https://img.shields.io/github/v/release/JBelke/openvpn-server?color=%2344cc11&label=LATEST%20RELEASE&style=flat-square&logo=Github)](https://github.com/JBelke/openvpn-server/releases/latest) [![Docker Image Version (tag latest semver)](https://img.shields.io/docker/v/JBelke/openvpn-server/latest?style=flat-square&logo=docker&logoColor=white&label=DOCKER%20IMAGE&color=2344cc11)](https://hub.docker.com/r/JBelke/openvpn-server) ![Docker Image Size (tag)](https://img.shields.io/docker/image-size/JBelke/openvpn-server/latest?logo=Docker&color=2344cc11&label=IMAGE%20SIZE&style=flat-square&logoColor=white)

[![latest version](https://img.shields.io/github/v/release/JBelke/openvpn-ui?color=%2344cc11&label=OpenVPN%20UI&style=flat-square&logo=Github)](https://github.com/JBelke/openvpn-ui) [![Docker Image Version (tag latest semver)](https://img.shields.io/docker/v/JBelke/openvpn-ui/latest?logo=docker&label=OpenVPN%20UI%20IMAGE&color=2344cc11&style=flat-square&logoColor=white)](https://hub.docker.com/r/JBelke/openvpn-ui)

## Important changes

### Release `v.0.5.1.1`

- Setup has been changed to default without internet access for pre-internet setup and configuration.
- .env.sample file has been added to the repository to promote security and privacy best practices.
- Environment variables have been added to the docker-compose.yml file.
- Start-stop.sh script has been added to the repository for easy start and stop of the OpenVPN Server with building new image.
- Backup.sh script has been enhanced to support backup and restore of the OpenVPN Server environment.
- Build arguments have been added to the docker-compose.yml file.
- Dockerfile has been enhanced to support building the image from the Dockerfile.
- Default OpenVPN Server configuration file has been moved from `/etc/openvpn/config` to `/etc/openvpn` directory.

### Release `v.0.4`

- Default Cipher for Server and Client configs is changed to `AES-256-GCM`
- **`ncp-ciphers`** option has been depricated and replaced with **`data-ciphers`**
- 2FA support has been added

## Automated installation

Consider to use [openvpn-aws](https://github.com/JBelke/openvpn-aws) as automated installation solution. It will deploy OpenVPN Server on any x86 server or Cloud instance with all the required configuration and OpenVPN UI for easy management.

## Run this image

### Run image using a `docker-compose.yml` file

1. Clone the repo:

```shell
git clone https://github.com/jbelke/openvpn-server
```

> **Note**: Before deploying container check [Deployment Details](https://github.com/jbelke/openvpn-server#container-deployment-details) section for setting all the required variables up. 2. Build the image:

```shell
cd openvpn-server
docker compose up -d
```

3. That's it. It seems you have your own openvpn-server running on your machine.

For easy **OpenVPN Server** management install [**OpenVPN-UI**](https://github.com/jbelke/openvpn-ui).

## Container deployment details

### Docker-compose.yml:

.env.sample file: (rename to .env and set your own values)

```bash
OPENVPN_PORT=1194
OPENVPN_PROTOCOL=udp
TRUST_SUB=10.0.70.0/24
GUEST_SUB=10.0.71.0/24
HOME_SUB=192.168.88.0/24
OPENVPN_ADMIN_USERNAME=admin
OPENVPN_ADMIN_PASSWORD=gagaZush
```

```yaml
---
services:
  openvpn:
    container_name: openvpn
    build: .
    privileged: true
    ports:
      - "${OPENVPN_PORT}:${OPENVPN_PORT}/${OPENVPN_PROTOCOL}" # openvpn port
      - "1194:1194/tcp" # openvpn TCP port
      - "2080:2080/tcp" # management port. uncomment if you would like to share it with the host
    environment:
      TRUST_SUB: ${TRUST_SUB}
      GUEST_SUB: ${GUEST_SUB}
      HOME_SUB: ${HOME_SUB}
      OPENVPN_PORT: ${OPENVPN_PORT}
      OPENVPN_PROTOCOL: ${OPENVPN_PROTOCOL}
      OPENVPN_ADMIN_USERNAME: ${OPENVPN_ADMIN_USERNAME}
      OPENVPN_ADMIN_PASSWORD: ${OPENVPN_ADMIN_PASSWORD}
    volumes:
      - ./pki:/etc/openvpn/pki
      - ./clients:/etc/openvpn/clients
      - ./config:/etc/openvpn/config
      - ./staticclients:/etc/openvpn/staticclients
      - ./log:/var/log/openvpn
      - ./fw-rules.sh:/opt/app/fw-rules.sh
      - ./checkpsw.sh:/opt/app/checkpsw.sh
      - ./server.conf:/etc/openvpn/server.conf
    cap_add:
      - NET_ADMIN
    restart: always
```

**Where:**

- `TRUST_SUB` is Trusted subnet, from which OpenVPN server will assign IPs to trusted clients (default subnet for all clients)
- `GUEST_SUB` is Gusets subnet for clients with internet access only
- `HOME_SUB` is subnet where the VPN server is located, thru which you get internet access to the clients with MASQUERADE
- `fw-rules.sh` is bash file with additional firewall rules you would like to apply during container start
- `checkpsw.sh` is a dummy bash script to use with `auth-user-pass-verify` option in `server.conf` file. It is used to check user credentials against some external passwords DB, like LDAP or oath, or MySQL. If you don't need this option, just leave it as is.

`docker_entrypoint.sh` will apply following Firewall rules:

```shell
IPT MASQ Chains:
MASQUERADE  all  --  ip-10-0-70-0.ec2.internal/24  anywhere
MASQUERADE  all  --  ip-10-0-71-0.ec2.internal/24  anywhere
IPT FWD Chains:
       0        0 DROP       1    --  *      *       10.0.71.0/24         0.0.0.0/0            icmptype 8
       0        0 DROP       1    --  *      *       10.0.71.0/24         0.0.0.0/0            icmptype 0
       0        0 DROP       0    --  *      *       10.0.71.0/24         192.168.88.0/24
```

Here is possible content of `fw-rules.sh` file to apply additional rules:

```shell
~/openvpn-server $ cat fw-rules.sh
iptables -A FORWARD -s 10.0.70.88 -d 10.0.70.77 -j DROP
iptables -A FORWARD -d 10.0.70.77 -s 10.0.70.88 -j DROP
```

<img src="https://github.com/jbelke/raspberry-gateway/raw/master/images/OVPN_VLANs.png" alt="OpenVPN Subnets" width="700" border="1" />

Check attached `docker-compose.yml` file to run openvpn-server withput [OpenVPN UI](https://github.com/jbelke/openvpn-ui) container.

**Default EasyRSA** configuration can be changed in `~/openvpn-server/config/easy-rsa.vars` file:

```shell
set_var EASYRSA_DN           "org"
set_var EASYRSA_REQ_COUNTRY  "US"
set_var EASYRSA_REQ_PROVINCE "NY"
set_var EASYRSA_REQ_CITY     "NYC"
set_var EASYRSA_REQ_ORG      "NewYorkCityCouncil"
set_var EASYRSA_REQ_EMAIL    "nyccouncil@nyc.gov"
set_var EASYRSA_REQ_OU       "DigitalServices"
set_var EASYRSA_REQ_CN       "server"
set_var EASYRSA_KEY_SIZE     2048
set_var EASYRSA_CA_EXPIRE    3650
set_var EASYRSA_CERT_EXPIRE  825
set_var EASYRSA_CERT_RENEW   30
set_var EASYRSA_CRL_DAYS     180
```

In the process of installation these vars will be copied to container volume `/etc/openvpn/pki/vars` and used during all EasyRSA operations.
You can update all these parameters later with OpenVPN UI on `Configuration > EasyRSA vars` page.

### Run with Docker:

```shell
docker run  --interactive --tty --rm \
  --name=openvpn \
  --cap-add=NET_ADMIN \
  -p 1194:1194/udp \
  -e TRUST_SUB=10.0.70.0/24 \
  -e GUEST_SUB=10.0.71.0/24 \
  -e HOME_SUB=192.168.88.0/24 \
  -v ./pki:/etc/openvpn/pki \
  -v ./clients:/etc/openvpn/clients \
  -v ./config:/etc/openvpn/config \
  -v ./staticclients:/etc/openvpn/staticclients \
  -v ./log:/var/log/openvpn \
  -v ./fw-rules.sh:/opt/app/fw-rules.sh \
  -v ./server.conf:/etc/openvpn/server.conf \
  --privileged jbelke/openvpn-server:latest
```

### Run the OpenVPN-UI image

```
docker run \
-v /home/pi/openvpn-server:/etc/openvpn \
-v /home/pi/openvpn-server/db:/opt/openvpn-ui/db \
-v /home/pi/openvpn-server/pki:/usr/share/easy-rsa/pki \
-e OPENVPN_ADMIN_USERNAME='admin' \
-e OPENVPN_ADMIN_PASSWORD='gagaZush' \
-p 8080:8080/tcp \
--privileged jbelke/openvpn-ui:latest
```

### Build image form scratch:

1. Clone the repo:

```shell
git clone https://github.com/jbelke/openvpn-server
```

2. Build the image:

```shell
cd openvpn-server
docker build --force-rm=true -t jbelke/openvpn-server .
```

## Configuration

The volume container will be initialised with included scripts to automatically generate everything you need on the first run:

- Diffie-Hellman parameters
- an EasyRSA CA key and certificate
- a new private key
- a self-certificate matching the private key for the OpenVPN server
- a TLS auth key from HMAC security

This setup use `tun` mode, as the most compatible with wide range of devices, for instance, does not work on MacOS(without special workarounds) and on Android (unless it is rooted).

The topology used is `subnet`, for the same reasons. `p2p`, for instance, does not work on Windows.

The server config [specifies](https://github.com/jbelke/openvpn-aws/blob/master/openvpn/server.conf#L34) `push redirect-gateway def1 bypass-dhcp`, meaning that after establishing the VPN connection, all traffic will go through the VPN. This might cause problems if you use local DNS recursors which are not directly reachable, since you will try to reach them through the VPN and they might not answer to you. If that happens, use public DNS resolvers like those of OpenDNS (`208.67.222.222` and `208.67.220.220`) or Google (`8.8.4.4` and `8.8.8.8`).

### OpenVPN Server Pstree structure

All the Server and Client configuration located in mounted Docker volume and can be easely tuned. Here is the tree structure:

```shell
|-- server.conf  // OpenVPN Server configuration file
|-- clients
|   |-- your_client1.ovpn
|-- config
|   |-- client.conf
|   |-- easy-rsa.vars
|-- db
|   |-- data.db //Optional OpenVPN UI DB
|-- log
|   |-- openvpn.log
|-- pki
|   |-- ca.crt
|   |-- certs_by_serial
|   |   |-- your_client1_serial.pem
|   |-- crl.pem
|   |-- dh.pem
|   |-- index.txt
|   |-- ipp.txt
|   |-- issued
|   |   |-- server.crt
|   |   |-- your_client1.crt
|   |-- openssl-easyrsa.cnf
|   |-- private
|   |   |-- ca.key
|   |   |-- your_client1.key
|   |   |-- server.key
|   |-- renewed
|   |   |-- certs_by_serial
|   |   |-- private_by_serial
|   |   |-- reqs_by_serial
|   |-- reqs
|   |   |-- server.req
|   |   |-- your_client1.req
|   |-- revoked
|   |   |-- certs_by_serial
|   |   |-- private_by_serial
|   |   |-- reqs_by_serial
|   |-- safessl-easyrsa.cnf
|   |-- serial
|   |-- ta.key
|-- staticclients //Directory where stored all the satic clients configuration
```

### OpenVPN client subnets. Guest and Home users

By default this [Openvpn-Server](https://github.com/jbelke/openvpn-server) OpenVPN server uses option `server 10.0.70.0/24` as **"Trusted"** subnet to grab dynamic IPs for all your Clients which, by default will have full access to your **"Private/Home"** subnet, as well as Internet over VPN.
However you can be desired to share internet over VPN with specific, Guest Clients and restrict access to your **"Private/Home"** subnet. For this scenario [Openvpn-Server's](https://github.com/jbelke/openvpn-server) `server.conf` configuration file has special `route 10.0.71.0/24` option, aka **"Guest users"** subnet.

To assign desired subnet policy to the specific client, you have to define static IP address for the client during its profile/Certificate creation.
To do that, just enter `"Static IP (optional)"` field in `"Certificates"` page and press `"Create"` button.

> Keep in mind, by default, all the clients have full access, so you don't need to specifically configure static IP for your own devices, your home devices always will land to **"Trusted"** subnet by default.

### CLI ways to deal with OpenVPN Server configuration

To **generate** new .OVPN profile execute following command. Password as second argument is optional:

```shell
sudo docker exec openvpn bash /opt/app/bin/genclient.sh <name> <IP> <?password?>
```

You can find you .ovpn file under `/openvpn/clients/<name>.ovpn`, make sure to check and modify the `remote ip-address`, `port` and `protocol`. It also will appear in `"Certificates"` menue of OpenVPN UI.

**Revoking** of old .OVPN files can be done via CLI by running following:

```shell
sudo docker exec openvpn bash /opt/app/bin/revoke.sh <clientname>
```

**Removing** of old .OVPN files can be done via CLI by running following:

```shell
sudo docker exec openvpn bash /opt/app/bin/rmcert.sh <clientname>
```

Restart of OpenVPN container can be done via the CLI by running following:

Via Script:

```shell
start-stop.sh start
```

or

Via Docker Compose:

```bash
docker compose down && docker compose up -d
```

or

Docker CLI:

```shell
sudo docker restart openvpn
```

### Define static IP

To define static IP, go to your (install path, ie:)`~/openvpn/staticclients` directory and create text file with the name of your client and insert into this file ifconfig-push option with the desired static IP and mask: `ifconfig-push 10.0.71.2 255.255.255.0`.

For example, if you would like to restrict Home subnet access to your best friend Slava, you should do this:

```shell
jbelke@ubuntu:~/openvpn/staticclients $ pwd
/home/jbelke/openvpn/staticclients
jbelke@ubuntu:~/openvpn/staticclients $ ls -lrt | grep Jbelke
-rw-r--r-- 1 jbelke jbelke 38 Nov  9 20:53 Jbelke
jbelke@ubuntu:~/openvpn/staticclients $ cat Jbelke
ifconfig-push 10.0.71.2 255.255.255.0
```

## Security Notes:

> Keep in mind, by default, all the clients have full access, so you don't need to specifically configure static IP for your own devices, your home devices always will land to **"Trusted"** subnet by default.

## Donate

<a href="https://www.buymeacoffee.com/jbelke" target="_blank"><img src="https://cdn.buymeacoffee.com/buttons/v2/default-yellow.png" alt="Buy Me A Coffee" height="51" width="217"></a>
