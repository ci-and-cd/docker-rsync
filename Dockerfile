
FROM debian:jessie
ENV DEBIAN_FRONTEND noninteractive
ENV LANG C.UTF-8

RUN set -ex \
  && apt-get -q -y update \
  && apt-get install -q -y openssh-server rsync \
  && apt-get -y clean \
  && rm -rf /var/lib/apt/lists/* /var/cache/apt/*.bin /tmp/* /var/tmp/*

# Setup SSH
# https://docs.docker.com/engine/examples/running_ssh_service/
RUN set -ex \
  && mkdir /var/run/sshd \
  && sed -i 's/PermitRootLogin without-password/PermitRootLogin yes/' /etc/ssh/sshd_config \
  && sed 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' -i /etc/pam.d/sshd \
  && echo "export VISIBLE=now" >> /etc/profile
ENV NOTVISIBLE "in users profile"
EXPOSE 22


# Setup rsync
EXPOSE 873


COPY --chown=root:root docker /
RUN chmod 744 /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
CMD ["rsync_server"]
