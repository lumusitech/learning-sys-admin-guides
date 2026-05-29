FROM ubuntu:22.04

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
      openssh-server \
      net-tools \
      procps \
      iproute2 \
      tcpdump \
      curl \
      dnsutils \
    && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /run/sshd && \
    useradd -m -s /bin/bash admin && \
    mkdir -p /home/admin/.ssh && \
    chmod 700 /home/admin/.ssh && \
    chown -R admin:admin /home/admin

COPY monitoring-ssh-setup.sh /usr/local/bin/ssh-setup.sh
RUN chmod +x /usr/local/bin/ssh-setup.sh

EXPOSE 22

CMD ["/usr/local/bin/ssh-setup.sh"]
