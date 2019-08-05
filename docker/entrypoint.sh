#!/bin/bash
set -e

RSYNC_USERNAME=${RSYNC_USERNAME:-rsync_user}
RSYNC_PASSWORD=${RSYNC_PASSWORD:-rsync_user_pass}
RSYNC_HOSTS_ALLOW=${RSYNC_HOSTS_ALLOW:-192.168.0.0/16 172.16.0.0/12 127.0.0.1/32}
RSYNC_VOLUME_NAME=${RSYNC_VOLUME_NAME:-volume}
RSYNC_VOLUME_PATH=${RSYNC_VOLUME_PATH:-/data}

if [[ "$1" = 'rsync_server' ]]; then
    chmod u=rwx,g-rwx,o-rwx /root/.ssh
    # If '/root/.ssh' directory is mounted from host, chmod can not change permission on it.
    sed -Ei 's/^[#]?StrictModes[ ]+yes$/StrictModes no/' /etc/ssh/sshd_config

    if [[ -e "/root/.ssh/authorized_keys" ]]; then
        chown root:root /root/.ssh/authorized_keys
        chmod 600 /root/.ssh/authorized_keys
    fi
    echo "root:${RSYNC_PASSWORD}" | chpasswd

    echo "${RSYNC_USERNAME}:${RSYNC_PASSWORD}" > /etc/rsyncd.secrets
    chown root:root /etc/rsyncd.secrets
    chmod 0400 /etc/rsyncd.secrets
    mkdir -p ${RSYNC_VOLUME_PATH}
    chown root:root ${RSYNC_VOLUME_PATH}
    chmod g+rxw,u+rxw ${RSYNC_VOLUME_PATH}

    [[ -f /etc/rsyncd.conf ]] || cat <<EOF > /etc/rsyncd.conf
auth users = ${RSYNC_USERNAME}
gid = root
hosts allow = ${RSYNC_HOSTS_ALLOW}
hosts deny = *
lock file = /var/lock/rsyncd.lock
log file = /dev/stdout
max connections = 10
pid file = /var/run/rsyncd.pid
port = 873
read only = false
secrets file = /etc/rsyncd.secrets
timeout = 300
uid = root
#use chroot = no
[${RSYNC_VOLUME_NAME}]
    comment = ${RSYNC_VOLUME_PATH} directory
    path = ${RSYNC_VOLUME_PATH}
EOF

    if [[ -e "/root/host_dot_ssh/id_rsa.pub" ]]; then
        echo -e '\n' >> /root/.ssh/authorized_keys
        cat /root/host_dot_ssh/id_rsa.pub >> /root/.ssh/authorized_keys
    fi

    exec /usr/sbin/sshd &
    shift
    exec /usr/bin/rsync --no-detach --daemon --config /etc/rsyncd.conf "${@:2}"
else
    exec "$@"
fi
