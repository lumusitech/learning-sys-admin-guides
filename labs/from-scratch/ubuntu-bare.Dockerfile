FROM ubuntu:22.04

# Contenedor mínimo para practicar aprovisionamiento desde cero
# Solo tiene SSH y herramientas base de red
# NADA instalado: sin nginx, sin MySQL, sin firewall configurado

RUN apt update && apt install -y \
    openssh-server \
    sudo \
    curl \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /run/sshd && \
    useradd -m -s /bin/bash -G sudo practica && \
    echo "practica:practica123" | chpasswd

RUN sed -i 's/#PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config && \
    sed -i 's/#PasswordAuthentication.*/PasswordAuthentication yes/' /etc/ssh/sshd_config

EXPOSE 22

CMD ["/usr/sbin/sshd", "-D"]
