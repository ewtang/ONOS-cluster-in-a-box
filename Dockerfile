#FROM adoptopenjdk/openjdk11:x86_64-ubuntu-jdk-11.0.1.13-slim
FROM ubuntu:18.04
MAINTAINER Eric Tang <qcorba at gmail.com>

RUN apt-get update 
RUN DEBIAN_FRONTEND=noninteractive apt-get -y install \
    --no-install-recommends \
    openjdk-11-jre \
    python-setuptools \
    python-pip \
    openssh-server \
    supervisor \
    vim-tiny \
    net-tools \
    iputils-ping \
    sudo

# Update pip
RUN pip install --upgrade pip

RUN set -eux; \
    groupadd -r sdn; \
    useradd -m -r -s /bin/bash -g sdn sdn; \
    echo sdn:sdn | chpasswd; \
    echo 'sdn ALL=(ALL:ALL) NOPASSWD:ALL' > /etc/sudoers.d/sdn

USER sdn
RUN mkdir /home/sdn/.ssh
RUN ssh-keygen -t rsa -N "" -f /home/sdn/.ssh/id_rsa

USER root
COPY --chown=sdn:sdn id_rsa.pub /home/sdn/.ssh/authorized_keys
RUN chmod 600 /home/sdn/.ssh/authorized_keys

# Install gosu
#RUN set -eux; \
#   apt-get update; \
#   apt-get install -y gosu; \
#   rm -rf /var/lib/apt/lists/*; \
# verify that the binary works
#   gosu nobody true

# Install supervisor
RUN set -eux; \
#   pip install supervisor; \
    mv /etc/supervisor/supervisord.conf /etc/supervisor/supervisord-orig.conf; \
    mkdir -p /var/log/supervisor; \
    mkdir -p /var/run/sshd; \
    chmod 700 /var/run/sshd; \
    mkdir -p /var/run/onos; \
    chmod 700 /var/run/onos
COPY supervisord.conf /etc/supervisor/
COPY supervisord-sshd.conf /etc/supervisor/conf.d/sshd.conf
COPY supervisord-onos.conf /etc/supervisor/conf.d/onos.conf

# Install ONOS
COPY onos.tar.gz /tmp/
RUN set -eux; \
    mkdir /opt/onos; \
    tar zxmf /tmp/onos.tar.gz -C /opt/onos --strip-components=1; \
    ln -s /opt/onos/apache-karaf-* /opt/onos/karaf; \
    ln -s /opt/onos/karaf/data/log /opt/onos/log; \
    mkdir /opt/onos/var; \
    mkdir /opt/onos/config; \
    # Install the configuration file(s)
    #cp /opt/onos/init/onos.conf /etc/init/onos.conf; \
    cp /opt/onos/init/onos.initd /etc/init.d/onos; \
    cp /opt/onos/init/onos.service /etc/systemd/system/onos.service; \
    # Set up options for debugging
    echo 'export ONOS_OPTS=debug' > /opt/onos/options; \
    # Set up correct user to run onos-service
    echo 'export ONOS_USER=sdn' >> /opt/onos/options; \
    # Configure ONOS to log to stdout
    sed -ibak '/log4j.rootLogger=/s/$/, stdout/' $(ls -d /opt/onos/apache-karaf-*)/etc/org.ops4j.pax.logging.cfg; \
    chown -R sdn:sdn /opt/onos

LABEL org.label-schema.name="ONOS" \
      org.label-schema.description="SDN Controller" \
      org.label-schema.usage="http://wiki.onosproject.org" \
      org.label-schema.url="http://onosproject.org" \
      org.label-scheme.vendor="Open Networking Foundation" \
      org.label-schema.schema-version="1.0"

# Ports
# 22 - sshd
# 80 - supervisord
# 5678 - Atomix REST API
# 5679 - Atomix intra-cluster communication
# 6633 - OpenFlow legacy
# 6640 - OVSDB
# 6653 - OpenFlow IANA assigned
# 8101 - ONOS CLI
# 8181 - ONOS GUI
# 9876 - ONOS intra-cluster communication
EXPOSE 22 5678 5679 6633 6640 6653 8101 8181 9876
#EXPOSE 80 
#EXPOSE 6379

CMD ["/usr/bin/supervisord", "-n"]
