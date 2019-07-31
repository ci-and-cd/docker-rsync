#!/bin/bash
set -e

RSYNC_USERNAME=${RSYNC_USERNAME:-rsync_user}
RSYNC_PASSWORD=${RSYNC_PASSWORD:-rsync_user_pass}
RSYNC_HOSTS_ALLOW=${RSYNC_HOSTS_ALLOW:-192.168.0.0/16 172.16.0.0/12 127.0.0.1/32}
RSYNC_VOLUME_PATH=${RSYNC_VOLUME_PATH:-/data}

if [ "$1" = 'rsync_server' ]; then
    if [ -e "/root/.ssh/authorized_keys" ]; then
        chmod 400 /root/.ssh/authorized_keys
        chown root:root /root/.ssh/authorized_keys
    fi
    exec /usr/sbin/sshd &

    echo "root:$RSYNC_PASSWORD" | chpasswd

    echo "$RSYNC_USERNAME:$RSYNC_PASSWORD" > /etc/rsyncd.secrets
    chmod 0400 /etc/rsyncd.secrets

    mkdir -p $RSYNC_VOLUME_PATH

    [ -f /etc/rsyncd.conf ] || cat <<EOF > /etc/rsyncd.conf
    pid file = /var/run/rsyncd.pid
    log file = /dev/stdout
    timeout = 300
    max connections = 10
    port = 873
    [volume]
        uid = root
        gid = root
        hosts deny = *
        hosts allow = ${RSYNC_HOSTS_ALLOW}
        read only = false
        path = ${RSYNC_VOLUME_PATH}
        comment = ${RSYNC_VOLUME_PATH} directory
        auth users = ${RSYNC_USERNAME}
        secrets file = /etc/rsyncd.secrets
EOF

    exec /usr/bin/rsync --no-detach --daemon --config /etc/rsyncd.conf "$@"
fi

exec "$@"
