# 🧪 Laboratorio Docker

Entorno Docker para practicar los escenarios de administración sin riesgo.

## Requisitos

```bash
docker --version
docker compose version  # o docker-compose
```

## Inicio rápido

```bash
# Clonar el repo (si no lo has hecho)
git clone git@github.com:lumusitech/learning-sys-admin-guides.git
cd learning-sys-admin-guides/labs

# Iniciar todos los servicios
docker compose up -d

# Ver estado
docker compose ps

# Ver logs
docker compose logs -f
```

## Servicios disponibles

| Servicio | Puerto | Credenciales |
|----------|--------|--------------|
| `ssh-hardened` | 2222 | `admin` + clave pública |
| `ssh-weak` | 2223 | `admin` / `admin123` |
| `ssh-internal` | — | Solo vía bastion |
| `web-nginx` | 8080 | HTTP |
| `web-apache` | 8081 | HTTP |
| `db-mysql` | 3306 | `admin` / `secret` |
| `db-postgres` | 5432 | `admin` / `postgrespass` |
| `monitoring` | — | `admin` + clave pública |

## Conectarse al laboratorio

```bash
# SSH seguro (con tu clave pública)
ssh -p 2222 -o StrictHostKeyChecking=no admin@localhost

# SSH débil (contraseña)
sshpass -p admin123 ssh -p 2223 -o StrictHostKeyChecking=no admin@localhost

# Via bastion hacia servidor interno
ssh -J admin@localhost:2222 -o StrictHostKeyChecking=no admin@ssh-internal

# Probar servidores web
curl localhost:8080
curl localhost:8081

# Conectar a MySQL
mysql -h localhost -P 3306 -u admin -psecret

# Conectar a PostgreSQL
PGPASSWORD=postgrespass psql -h localhost -U admin -d app

# Acceder al contenedor de monitoreo (tiene tcpdump, curl, etc.)
ssh -p 2222 -o StrictHostKeyChecking=no admin@localhost \
  "curl -s web-nginx:80 | head -5"
```

## Prácticas sugeridas

### 1. Fuerza bruta SSH sobre ssh-weak

```bash
# Desde monitoring, atacar ssh-weak
docker exec -it monitoring bash
apt install -y sshpass
for i in $(seq 1 50); do
  sshpass -p "wrong$i" ssh -o StrictHostKeyChecking=no admin@ssh-weak "exit" 2>/dev/null
done

# Ver logs en ssh-weak
docker logs ssh-weak 2>&1 | grep "Failed password"
```

### 2. Port scan desde monitoring

```bash
docker exec -it monitoring bash
apt install -y nmap
nmap -sS -T4 172.17.0.0/24  # Escanear red del laboratorio
```

### 3. Capturar tráfico MySQL

```bash
docker exec -it monitoring tcpdump -i any port 3306 -A
# En otro terminal: conectar a MySQL desde local
```

### 4. Prueba de túneles SSH

```bash
# Túnel MySQL remoto → local
ssh -p 2222 -L 3307:db-mysql:3306 -o StrictHostKeyChecking=no admin@localhost

# En otro terminal
mysql -h localhost -P 3307 -u admin -psecret
```

## Detener el laboratorio

```bash
docker compose down          # Detener (conserva volúmenes)
docker compose down -v       # Detener y eliminar volúmenes
```
