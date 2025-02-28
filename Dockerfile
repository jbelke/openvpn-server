# Start from Alpine base image
FROM alpine:latest
LABEL maintainer="JBelke <jbelke@gmail.com>"
LABEL version="0.1.0"

# Build arguments with defaults
ARG OPENVPN_PORT=1194
ARG OPENVPN_PROTOCOL=udp

# Environment variables
ENV OPENVPN_PORT=${OPENVPN_PORT}
ENV OPENVPN_PROTOCOL=${OPENVPN_PROTOCOL}

# Set the working directory to /opt/app
WORKDIR /opt/app

RUN apk --no-cache --no-progress upgrade && apk --no-cache --no-progress add \
    bash \
    bind-tools \
    curl \
    easy-rsa \
    ip6tables \
    iptables \
    oath-toolkit-oathtool \
    openvpn

#Install Latest RasyRSA Version
RUN chmod 755 /usr/share/easy-rsa/*

# Copy all files in the current directory to the /opt/app directory in the container
COPY bin /opt/app/bin
COPY docker-entrypoint.sh /opt/app/docker-entrypoint.sh
RUN mkdir -p /opt/app/clients \
    /opt/app/db \
    /opt/app/log \
    /opt/app/pki \
    /opt/app/staticclients \
    /opt/app/config

# Add the openssl-easyrsa.cnf file to the easy-rsa directory
COPY openssl-easyrsa.cnf /opt/app/easy-rsa/

# Make all files in the bin directory executable
RUN chmod +x bin/*; chmod +x docker-entrypoint.sh

# Expose the OpenVPN port
EXPOSE ${OPENVPN_PORT}/${OPENVPN_PROTOCOL}

# Set the entrypoint to the docker-entrypoint.sh script
ENTRYPOINT ["./docker-entrypoint.sh"]