# Lab AUR: imagen Arch con yay compilado desde AUR y un paquete AUR instalado
# Se construye UNA vez (capa cacheadia); el arranque posterior es rápido.

FROM archlinux:latest

# Dependencias de build + usuario no-root (makepkg no corre como root)
RUN pacman -Syu --noconfirm --needed git base-devel go \
    && useradd -m builder \
    && echo "builder ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/builder \
    && chmod 440 /etc/sudoers.d/builder

# Compilar e instalar yay desde su PKGBUILD de AUR
RUN git clone https://aur.archlinux.org/yay.git /tmp/yay \
    && chown -R builder:builder /tmp/yay \
    && cd /tmp/yay \
    && su builder -c "makepkg -si --noconfirm" \
    && rm -rf /tmp/yay

# Instalar un paquete AUR real y chico (script único, sin dependencias de build)
RUN su builder -c "yay -S --noconfirm pipes.sh"

CMD ["sleep", "infinity"]