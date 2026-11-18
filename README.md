# HPOS — punto de venta para hookah

Sistema de punto de venta para lounges, clubes y terrazas con servicio de hookah: ventas por mesa con notas, control de hookahs (arriba / abajo), recargas, cortesías con aprobación, almacén con recetas y costos, impresión térmica (comandas, facturas y cierre del día), varios equipos trabajando juntos con respaldo automático y app para teléfonos.

Aquí están los **instaladores listos** de cada versión y la guía en PDF. HPOS viene **neutro**: cada local pone su logo, nombre, colores y el encabezado de sus tickets en *Administración › Diseño*.

## Instalar con un solo comando

**Windows 10 / 11 (64 bits)** — abre *PowerShell* y pega:
```powershell
irm https://raw.githubusercontent.com/hugo860/HPOS/main/instalar/windows.ps1 | iex
```

**Linux** (Debian 11/12, Ubuntu o Lubuntu 20.04+, antiX 22/23; 64 bits) — abre la terminal y pega:
```sh
curl -fsSL https://raw.githubusercontent.com/hugo860/HPOS/main/instalar/linux.sh | sudo sh
```

**Android** — abre este enlace en el teléfono e instala:
https://github.com/hugo860/HPOS/releases/latest/download/HPOS-android.apk
(o escanea el código QR en *Administración › Red y QR*).

**iPhone / iPad** — abre la dirección del servidor en Safari y toca *Compartir › Agregar a pantalla de inicio*.

**Equipo dedicado (HPOS OS, desde USB)** — baja `HPOS-OS-amd64.iso` de la [última versión que la incluya](https://github.com/hugo860/HPOS/releases), grábala en una USB de 2 GB o más con Rufus (modo DD) o balenaEtcher, arranca la PC desde la USB y toca **Instalar**. Trae HPOS en su propia ventana (sin navegador), el modo nodo y el soporte remoto ya listos; funciona en PCs de 2 GB de RAM y sin internet.

## Se actualiza solo
Cada 2 horas el equipo revisa si hay versión nueva y la instala **solo cuando no hay un turno abierto**. Se puede apagar en *Administración › Ajustes › Actualizar solo*. Los datos del negocio nunca se tocan.

Para actualizar en el momento: vuelve a pegar el comando de instalación (Windows) o corre `oasis-hookah actualizar` (Linux).

## Primeros pasos
1. Abre `http://localhost:3000` en el equipo principal. Usuario inicial: **Admin, PIN 1234** (cámbialo en *Administración › Usuarios*).
2. *Administración › Ajustes*: datos del local (salen en los tickets).
3. *Administración › Diseño*: logo, nombre, estilo de la pantalla y encabezado de los tickets.
4. *Administración › Impresoras*: toca **Buscar** y elige cada impresora.
5. Crea hookeros y supervisores, registra las hookahs y pon el costo de cada caja en *Almacén*.

La guía completa está en [`HPOS-Guia.pdf`](HPOS-Guia.pdf).

## Licencia
HPOS funciona **14 días de prueba** con todo. Después necesita una licencia por equipo, que emite el autor. El código fuente no es público.

| Archivo de cada versión | Para |
|---|---|
| `HPOS-windows-x64.msi` | Windows 10/11 (equipo principal) |
| `hpos-linux-amd64.deb` | Linux (principal o nodo de respaldo) |
| `HPOS-android.apk` | Teléfonos y tablets Android |
| `HPOS-OS-amd64.iso` | USB para dejar una PC dedicada a HPOS |
| `HPOS-Guia.pdf` | Guía de instalación y uso |
| `latest.json` | Lo usa el actualizador automático |

© 2026 Hugo Miguel Marte Lora - Todos los derechos reservados.
