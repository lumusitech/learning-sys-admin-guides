FROM rockylinux:9

RUN dnf install -y \
    openssh-server \
    sudo \
    curl \
    && dnf clean all

RUN ssh-keygen -A && \
    useradd -m -G wheel practica && \
    echo "practica:practica123" | chpasswd && \
    sed -i 's/#PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config

EXPOSE 22

CMD ["/usr/sbin/sshd", "-D"]
