#!/bin/sh
# © 2026 Hugo Miguel Marte Lora - Todos los derechos reservados.
# HPOS para Linux (Debian 11/12, Ubuntu y Lubuntu 20.04 en adelante, antiX 22/23), PC de 64 bits.
#
#   curl -fsSL https://raw.githubusercontent.com/hugo860/HPOS/main/instalar/linux.sh | sudo sh
#   (sin curl:  wget -qO- https://raw.githubusercontent.com/hugo860/HPOS/main/instalar/linux.sh | sudo sh)
#
# Instala la última versión y deja la actualización automática (cada 2 horas, solo sin turno abierto).
# Los datos del negocio (/var/lib/oasis-hookah) nunca se tocan.
set -eu
CANAL="${HPOS_CANAL:-https://github.com/hugo860/HPOS/releases}"
[ "$(id -u)" = 0 ] || { echo "Falta sudo. Pega:  curl -fsSL https://raw.githubusercontent.com/hugo860/HPOS/main/instalar/linux.sh | sudo sh"; exit 1; }
case "$(dpkg --print-architecture 2>/dev/null)" in amd64) ;; *) echo "HPOS necesita una PC de 64 bits (amd64) con Debian, Ubuntu o antiX."; exit 1 ;; esac
echo ""; echo "  HPOS · instalación para Linux"
export DEBIAN_FRONTEND=noninteractive
if ! command -v curl >/dev/null 2>&1 && ! command -v wget >/dev/null 2>&1; then apt-get update -qq && apt-get install -y -qq curl >/dev/null; fi
get() { if command -v curl >/dev/null 2>&1; then curl -fsSL --retry 2 -o "$2" "$1"; else wget -q -O "$2" "$1"; fi; }
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
echo "  Buscando la última versión…"
get "$CANAL/latest/download/latest.json" "$T/latest.json" || { echo "  No se pudo conectar. Revisa el internet y vuelve a intentar."; exit 1; }
val() { sed -n "s/.*\"$1\": *\"\([^\"]*\)\".*/\1/p" "$T/latest.json" | head -1; }
NEW=$(val version); TAG=$(val tag); FILE=$(val linux_file); SUM=$(val linux_sha256)
CUR=$(dpkg-query -W -f='${Version}' oasis-hookah 2>/dev/null || true)
if [ -n "$CUR" ] && ! dpkg --compare-versions "$NEW" gt "$CUR"; then
  echo "  Ya tienes la última versión (v$CUR)."
else
  if [ -n "$CUR" ] && [ "${HPOS_YA:-0}" != 1 ] && curl -fsS --max-time 5 http://127.0.0.1:3000/api/update/ready 2>/dev/null | grep -q '"shift_open": *true'; then
    echo "  Hay un turno abierto. Ciérralo y vuelve a pegar el comando (o se actualiza solo después)."; exit 0
  fi
  echo "  Bajando HPOS v$NEW…"
  get "$CANAL/download/$TAG/$FILE" "$T/hpos.deb"
  [ -z "$SUM" ] || [ "$(sha256sum "$T/hpos.deb" | cut -d' ' -f1)" = "$SUM" ] || { echo "  La descarga llegó dañada. Vuelve a intentar."; exit 1; }
  chmod 0755 "$T"; chmod 0644 "$T/hpos.deb"
  apt-get install -y --no-install-recommends "$T/hpos.deb" || { apt-get update -qq && apt-get install -y --no-install-recommends "$T/hpos.deb"; }
fi
echo ""
echo "  Listo. Se actualiza solo (cada 2 horas, sin turno abierto). Ver estado: oasis-hookah estado"
echo ""
