
# kubectl — Guía completa de diagnóstico

**Nivel:** 🟡 Intermedio
**Archivos de práctica:** `labs/docker-compose.k8s.yml`
**Ver escenarios relacionados:** _próximamente_

---

## ⚡ Quick command

`kubectl get nodes`

> ⚠️ Requiere un cluster Kubernetes y `kubectl` configurado con un kubeconfig válido.

---

## ⚡ Quick run

```bash
kubectl get nodes -o wide && kubectl get pods --all-namespaces
```

---

## 📑 Índice

1. [¿Qué es kubectl?](#qué-es-kubectl)
2. [Modelo mental](#modelo-mental)
3. [Sintaxis básica](#sintaxis-básica)
4. [Salida clave](#salida-clave)
5. [Opciones principales](#opciones-principales)
6. [Patrones de uso](#patrones-de-uso)
7. [Uso en troubleshooting](#uso-en-troubleshooting)
8. [Combinación con otras herramientas](#combinación-con-otras-herramientas)
9. [Uno-liners imprescindibles](#uno-liners-imprescindibles)
10. [Errores comunes](#errores-comunes)
11. [Buenas prácticas](#buenas-prácticas)
12. [Referencias internas](#referencias-internas)

---

## 🧠 ¿Qué es kubectl?

kubectl es la herramienta de línea de comandos para interactuar con clusters Kubernetes. Es la interfaz principal del sysadmin para diagnosticar el estado del cluster, los nodos, los pods y los servicios.

### ¿Para qué sirve en diagnóstico?

- **Health check**: estado de nodos, pods, servicios, endpoints
- **Logs**: capturar logs de pods en fallo
- **Eventos**: identificar qué está fallando y por qué
- **Recursos**: consumo de CPU/memoria por pod y nodo
- **Red**: conectividad entre servicios, DNS interno, ingresses

### ¿Cuándo NO usarlo?

- Para desarrollo de aplicaciones (eso es manifiestos YAML, SDKs)
- Para modificar el cluster persistentemente (usar GitOps: ArgoCD, Flux)
- Para gestionar el plano de control (eso es `kubeadm`, `kubectl` solo consulta)

---

## 🧠 Modelo mental

kubectl es el **visor de instrumentos del cluster**.

Pensá en kubectl como `systemctl` pero para un cluster distribuido:

- `kubectl get nodes` = `systemctl status` de todos los servidores
- `kubectl get pods` = `ps aux` de todos los contenedores
- `kubectl logs` = `journalctl -u` de un servicio
- `kubectl describe` = `systemctl show` + `journalctl -x`
- `kubectl top` = `top` pero repartido entre nodos

No necesitás saber cómo funciona Kubernetes entero para diagnosticar: necesitás saber qué mirar según el síntoma.

---

## 📝 Sintaxis básica

```text
kubectl [comando] [tipo] [nombre] [flags]
```

| Componente | Ejemplo |
|------------|---------|
| comando | `get`, `describe`, `logs`, `delete`, `exec` |
| tipo | `nodes`, `pods`, `services`, `deployments`, `events` |
| nombre | nombre específico del recurso (opcional) |
| flags | `-n`, `--all-namespaces`, `-o wide`, `--field-selector` |

### Namespaces

Los recursos pueden estar aislados en namespaces:

```bash
kubectl get pods                         # namespace por defecto
kubectl get pods -n kube-system          # namespace específico
kubectl get pods --all-namespaces        # todos los namespaces
```

---

## 🔑 Salida clave

### `kubectl get nodes`

```text
NAME           STATUS   ROLES    AGE   VERSION
k8s-master     Ready    master   45d   v1.30.2
k8s-worker-1   Ready    worker   45d   v1.30.2
k8s-worker-2   NotReady worker   45d   v1.30.2
```

| Columna | Significado |
|---------|-------------|
| STATUS | `Ready`, `NotReady`, `SchedulingDisabled` |
| ROLES | `master` (control plane), `worker` (carga) |
| VERSION | Versión de kubelet |

### `kubectl get pods`

```text
NAME                     READY   STATUS    RESTARTS   AGE
api-7d8f9c5d6-abc12      1/1     Running   0          12h
web-6b7f8c9d0-xyz34      0/1     CrashLoopBackOff   3          5m
db-1a2b3c4d5-def56       1/1     Running   1          48h
```

| Columna | Significado |
|---------|-------------|
| READY | contenedores listos / total en el pod |
| STATUS | `Running`, `Pending`, `CrashLoopBackOff`, `ImagePullBackOff`, `ErrImagePull`, `OOMKilled`, `Evicted` |
| RESTARTS | número de reinicios — alto es síntoma de problema |

### `kubectl get events --sort-by=.lastTimestamp`

```text
LAST SEEN   TYPE      REASON      OBJECT                      MESSAGE
5m          Warning   BackOff     pod/web-6b7f8c9d0-xyz34     Back-off restarting failed container
2m          Normal    Pulling     pod/web-6b7f8c9d0-xyz34     Pulling image "nginx:latest"
2m          Normal    Pulled      pod/web-6b7f8c9d0-xyz34     Successfully pulled image
1m          Warning   CrashLoopBackOff  pod/web-6b7f8c9d0-xyz34  Back-off 2m40s restarting
```

Los eventos son la fuente de verdad para entender **por qué** algo falla.

---

## 🎛️ Opciones principales

### Formato de salida (`-o`)

| Flag | Descripción | Ejemplo |
|------|-------------|---------|
| `-o wide` | Columnas extra (IP, nodo, puertos) | `kubectl get pods -o wide` |
| `-o yaml` | Recurso completo en YAML | `kubectl get pod web -o yaml` |
| `-o json` | Recurso completo en JSON | `kubectl get pod web -o json` |
| `-o jsonpath='{...}'` | Campo específico con jsonpath | `kubectl get pod web -o jsonpath='{.status.phase}'` |
| `--output=json` | Similar a `-o json` | |
| `--watch` | Seguir cambios en tiempo real | `kubectl get pods --watch` |

### Filtros

| Flag | Descripción | Ejemplo |
|------|-------------|---------|
| `-n <ns>` | Filtrar por namespace | `-n production` |
| `--all-namespaces` | Todos los namespaces | `-A` (abreviatura) |
| `-l <label>` | Filtrar por label | `-l app=nginx,env=prod` |
| `--field-selector` | Filtrar por campo | `--field-selector=status.phase=Running` |
| `--sort-by=<jsonpath>` | Ordenar salida | `--sort-by=.status.startTime` |

### Comandos de acción

| Comando | Descripción | Ejemplo típico |
|---------|-------------|---------------|
| `get` | Listar recursos | `get pods`, `get nodes` |
| `describe` | Detalle de un recurso | `describe pod/web` |
| `logs` | Logs de un contenedor | `logs -f pod/web --tail=50` |
| `exec` | Ejecutar comando en un contenedor | `exec -it pod/web -- sh` |
| `top` | Métricas de CPU/memoria | `top pods`, `top nodes` |
| `delete` | Eliminar recurso | `delete pod/web --force` |

---

## 📋 Patrones de uso

### 1. Diagnóstico de nodo no saludable

```bash
kubectl describe node k8s-worker-2
```

Buscar en la salida:

- `Conditions` → si `Ready` es `Unknown` o `False`
- `Allocatable` vs `Capacity` → recursos disponibles
- `Conditions` con `DiskPressure`, `MemoryPressure`, `PIDPressure`

### 2. Diagnóstico de pod en CrashLoopBackOff

```bash
kubectl describe pod web-6b7f8c9d0-xyz34
kubectl logs web-6b7f8c9d0-xyz34 --previous
kubectl logs web-6b7f8c9d0-xyz34 --tail=50
```

- `describe` muestra eventos, labels, montajes, condiciones
- `logs --previous` muestra logs del contenedor antes del crash
- `--tail=50` evita saturar la terminal con logs viejos

### 3. Pod en ImagePullBackOff

```bash
kubectl describe pod web-6b7f8c9d0-xyz34 | grep -A5 "Failed to pull image"
```

Causas comunes:

- La imagen no existe en el registry
- Credenciales incorrectas (`imagePullSecrets`)
- Rate limiting del registry (Docker Hub limita pulls anónimos)

### 4. Pod en estado Pending

```bash
kubectl describe pod web-6b7f8c9d0-xyz34 | grep -i "events"
```

Causas comunes:

- Falta de CPU/memoria en nodos (Events muestran `Insufficient memory`)
- PVC no disponible (PersistentVolumeClaim no bound)
- Node selector / taints / tolerations que no matchan

### 5. Pod OOMKilled

```bash
kubectl get pods --field-selector=status.phase=Running -o wide
kubectl top pods
kubectl describe pod web-6b7f8c9d0-xyz34 | grep -i "memory"
```

Verificar:

- Límite de memoria en el contenedor (`resources.limits.memory`)
- Consumo real vs límite
- Pod con `OOMKilled` en `lastState.terminated.reason`

### 6. Service sin endpoints

```bash
kubectl get endpoints web-service
kubectl get pods -l app=web
```

- Si `ENDPOINTS` está vacío, ningún pod matchea el selector del service
- Verificar labels del pod vs selector del service

### 7. CoreDNS no resuelve

```bash
kubectl get pods -n kube-system -l k8s-app=kube-dns
kubectl logs -n kube-system -l k8s-app=kube-dns --tail=50
kubectl get svc -n kube-system kube-dns
```

---

## 🔍 Uso en troubleshooting

### Árbol de decisión

```text
¿El cluster responde?
│
├── No → kubectl get nodes → ¿Nodos NotReady?
│       ├── Sí → kubectl describe node <name> → buscar conditions
│       └── No → revisar kubeconfig, contexto, conectividad
│
└── Sí → kubectl get pods --all-namespaces
        │
        ├── ¿Pods en Pending?
        │   └── kubectl describe pod <name> → buscar eventos
        │
        ├── ¿Pods en CrashLoopBackOff?
        │   └── kubectl logs <name> --previous
        │
        ├── ¿Pods en ImagePullBackOff?
        │   └── kubectl describe pod <name> | grep "Failed"
        │
        ├── ¿Pods en OOMKilled?
        │   └── kubectl top pods → kubectl describe pod <name>
        │
        └── ¿Servicios no responden?
            └── kubectl get endpoints → kubectl get pods -l <selector>
```

### Correlación temporal

```bash
kubectl get events --sort-by=.lastTimestamp --all-namespaces | tail -30
```

Los eventos tienen timestamp. Si varios recursos fallan al mismo tiempo, probablemente hay una causa común (nodo caído, red, upgrade).

---

## 🛠️ Combinación con otras herramientas

### `kubectl` + `jq`

```bash
kubectl get pods -o json | jq '.items[] | {name: .metadata.name, status: .status.phase}'
```

### `kubectl` + `grep` / `awk`

```bash
kubectl get pods -o wide | awk '/CrashLoopBackOff/ {print $1, $6}'
kubectl get nodes | grep -v Ready
kubectl get events --all-namespaces | grep -i error
```

### `kubectl` + `watch`

```bash
watch -n 2 kubectl get pods -o wide
watch -n 5 kubectl top nodes
```

### `kubectl` + `curl`

Diagnóstico de servicio interno:

```bash
kubectl run tmp-shell --rm -it --image=busybox -- sh
# dentro del contenedor temporal:
wget -O- http://web-service:8080/health
```

---

## 💡 Uno-liners imprescindibles

```bash
# Salud general del cluster
kubectl get nodes && kubectl get pods --all-namespaces | grep -v Running

# Todos los pods con problemas
kubectl get pods --all-namespaces --field-selector=status.phase!=Running

# Logs de un pod en fallo (última ejecución)
kubectl logs <pod> --previous --tail=50

# Eventos recientes, ordenados
kubectl get events --sort-by=.lastTimestamp --all-namespaces | tail -20

# Consumo de recursos
kubectl top pods --all-namespaces --sort-by=cpu | head -10
kubectl top pods --all-namespaces --sort-by=memory | head -10

# Pods en un nodo específico
kubectl get pods --all-namespaces -o wide | grep <node-name>

# Cuántos pods por nodo
kubectl get pods --all-namespaces -o wide | awk '{print $8}' | sort | uniq -c | sort -rn

# Service sin endpoints
kubectl get endpoints --all-namespaces | awk '{if ($2 == "<none>") print $1, $2, $3}'

# Contenedores con restart count alto
kubectl get pods --all-namespaces | awk '$5 > 5 {print $1, $2, $5}'

# Ejecutar comando en contenedor temporal
kubectl run debug --rm -it --image=nicolaka/netshoot -- sh
```

---

## ⚠️ Errores comunes

| Error | Causa | Solución |
|-------|-------|----------|
| `The connection to the server <host> was refused` | API server no responde | Verificar cluster, kubeconfig, firewall |
| `error: You must be logged in to the server` | Token expirado o inválido | `kubectl config view`, renovar token |
| `Error from server (NotFound): pods not found` | Namespace incorrecto | `-n <namespace>` o `--all-namespaces` |
| `Error: container not found` | Pod multi-contenedor sin especificar | `-c <container-name>` en logs/exec |
| `CrashLoopBackOff` | Contenedor arranca y crashea | `logs --previous` para ver error antes del crash |
| `ImagePullBackOff` | No se puede descargar la imagen | Verificar nombre, registry, credenciales |
| `Evicted` | Nodo sin recursos | `describe node`, `top nodes` |
| `Init:Error` | Init container falló | `logs <pod> -c <init-container>` |
| `Unknown` | Kubelet no reporta estado | Nodo probablemente caído |
| Context no configurado | `~/.kube/config` no existe o está mal | `kubectl config use-context <name>` |

---

## ✅ Buenas prácticas

1. **Siempre especificar namespace**: `-n <namespace>` o configura contexto por defecto con `kubectl config set-context --namespace <ns>`
2. **Usar `--all-namespaces` para diagnóstico global**: no asumas que todo está en `default`
3. **`describe` antes que `logs`**: `describe` te da eventos, condiciones, montajes — contexto completo antes de los detalles
4. **Logs del contenedor anterior**: si el pod se reinició, los logs activos pueden estar vacíos. Usar `--previous`
5. **No editar pods directamente**: eliminalos y deja que el ReplicaSet los recreé
6. **Usar `watch` para cambios en tiempo real**: `watch -n 2 kubectl get pods`
7. **Tener un pod de diagnóstico**: `nicolaka/netshoot` o `busybox` para debug de red desde dentro del cluster
8. **Versionar manifiestos**: no aplicar YAML directamente desde `kubectl apply -f` en producción sin Git
9. **Conocer tu contexto**: `kubectl config current-context` antes de ejecutar comandos destructivos
10. **`--dry-run=client`**: validar comandos antes de ejecutarlos

---

## 🔗 Referencias internas

- [`docker`](docker.md) — contenedores a nivel de host
- [`systemd`](systemd.md) — init system y gestión de servicios
- [`systemd_journalctl`](systemd_journalctl.md) — logs del sistema
- [`awk`](awk.md) — procesamiento de columnas en pipelines kubectl
- [`curl`](curl.md) — diagnóstico HTTP desde dentro del cluster
- [`scenario`](../scenarios/system/14-docker-troubleshooting.md) — troubleshooting de contenedores
- [`concept`](../concepts/sre-fundamentals.md) — SLI/SLO para monitoreo de clusters
