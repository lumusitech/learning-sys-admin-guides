FROM debian:bookworm-slim

RUN apt update && apt install -y \
    openssh-server \
    sudo \
    curl \
    && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /run/sshd && \
    useradd -m -s /bin/bash -G sudo practica && \
    echo "practica:practica123" | chpasswd

EXPOSE 22

CMD ["/usr/sbin/sshd", "-D"]
