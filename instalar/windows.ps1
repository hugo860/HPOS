# (c) 2026 Hugo Miguel Marte Lora - Todos los derechos reservados.
# (Solo caracteres ASCII a proposito: Windows PowerShell 5.1 lee los scripts sin BOM como ANSI.)
# HPOS para Windows 10/11: instala (o pone al dia) con un solo comando y deja la actualizacion automatica.
#
#   Abre PowerShell y pega:   irm https://raw.githubusercontent.com/hugo860/HPOS/main/instalar/windows.ps1 | iex
#
# La tarea programada "HPOS - Actualizar" revisa cada 2 horas y al iniciar sesion. Instala la version nueva
# solo si NO hay turno abierto y si el administrador no lo apago (Administracion > Ajustes > Actualizar solo).
# Los datos del negocio (C:\ProgramData\OasisHookah) nunca se tocan.
$ErrorActionPreference = 'Stop'; $ProgressPreference = 'SilentlyContinue'
try { [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12 } catch { }
$HPOS_Canal = if ($env:HPOS_CANAL) { $env:HPOS_CANAL.TrimEnd('/') } else { 'https://github.com/hugo860/HPOS/releases' }
$HPOS_Script = if ($env:HPOS_SCRIPT) { $env:HPOS_SCRIPT } else { 'https://raw.githubusercontent.com/hugo860/HPOS/main/instalar/windows.ps1' }
$HPOS_Data = Join-Path $env:ProgramData 'OasisHookah'
$HPOS_Tarea = 'HPOS - Actualizar'

function HPOS-Log($t) { try { New-Item -ItemType Directory -Force (Join-Path $HPOS_Data 'logs') | Out-Null; Add-Content (Join-Path $HPOS_Data 'logs\actualizar.log') ("{0:yyyy-MM-dd HH:mm:ss} {1}" -f (Get-Date), $t) } catch { } }
function HPOS-Estado($state, $msg, $cur, $new) {
  $o = [ordered]@{ checked_at = [DateTimeOffset]::UtcNow.ToUnixTimeSeconds(); state = $state; msg = $msg; installed = "$cur"; latest = "$new" }
  try { New-Item -ItemType Directory -Force $HPOS_Data | Out-Null; [IO.File]::WriteAllText((Join-Path $HPOS_Data 'update.json'), ($o | ConvertTo-Json -Compress), (New-Object Text.UTF8Encoding $false)) } catch { }
  HPOS-Log "${state}: $msg"
}
function HPOS-Instalada {
  $k = Get-ItemProperty 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*' -ErrorAction SilentlyContinue | Where-Object { $_.DisplayName -eq 'Oasis Hookah' } | Select-Object -First 1
  if ($k) { return [string]$k.DisplayVersion } else { return '' }
}
function HPOS-Exe { $p = Join-Path $env:ProgramFiles 'Oasis Hookah\oasis-server.exe'; if (Test-Path $p) { return $p } else { return $null } }
function HPOS-Puerto {
  try { $c = Get-Content (Join-Path $HPOS_Data 'config\settings.json') -Raw | ConvertFrom-Json; if ($c.port) { return [int]$c.port } } catch { }
  return 3000
}
function HPOS-Listo {
  # Pregunta al servidor de este equipo. Si no esta abierto, no hay ventas en curso.
  if (-not (Get-Process oasis-server -ErrorAction SilentlyContinue)) { return @{ ready = $true; abierto = $false } }
  try { $r = Invoke-RestMethod -UseBasicParsing -TimeoutSec 5 ("http://127.0.0.1:{0}/api/update/ready" -f (HPOS-Puerto)); return @{ ready = [bool]$r.ready; turno = [bool]$r.shift_open; auto = [bool]$r.auto_update; abierto = $true } }
  catch { return @{ ready = $true; abierto = $true } }
}
function HPOS-Mayor($a, $b) { if (-not $b) { return $true }; try { return ([version]$a -gt [version]$b) } catch { return ($a -ne $b) } }
function HPOS-Ultima { return Invoke-RestMethod -UseBasicParsing -TimeoutSec 60 "$HPOS_Canal/latest/download/latest.json" }

function HPOS-InstalarMsi($l, $cur) {
  $msi = Join-Path $env:TEMP ("HPOS-{0}.msi" -f $l.version)
  Invoke-WebRequest -UseBasicParsing -TimeoutSec 900 ("{0}/download/{1}/{2}" -f $HPOS_Canal, $l.tag, $l.windows_file) -OutFile $msi
  if ($l.windows_sha256 -and ((Get-FileHash $msi -Algorithm SHA256).Hash.ToLower() -ne $l.windows_sha256.ToLower())) { Remove-Item $msi -Force; throw "la descarga de v$($l.version) llego danada" }
  $estaba = [bool](Get-Process oasis-server -ErrorAction SilentlyContinue)
  if ($estaba) { Get-Process oasis-server -ErrorAction SilentlyContinue | Stop-Process -Force; Start-Sleep 2 }
  $log = Join-Path $env:TEMP ("HPOS-{0}-instalacion.log" -f $l.version)
  $p = Start-Process msiexec.exe -ArgumentList "/i `"$msi`" /qn /norestart /l*v `"$log`"" -Wait -PassThru
  Remove-Item $msi -Force -ErrorAction SilentlyContinue
  if ($p.ExitCode -ne 0 -and $p.ExitCode -ne 3010) { throw "el instalador termino con codigo $($p.ExitCode) (registro: $log)" }
  return $estaba
}
function HPOS-Abrir([switch]$Bandeja) {
  # Despues de actualizar solo, HPOS vuelve a abrir junto al reloj (sin tapar la pantalla); el acceso directo lo trae al frente.
  $e = HPOS-Exe
  if ($e -and -not (Get-Process oasis-server -ErrorAction SilentlyContinue)) {
    if ($Bandeja) { Start-Process $e -WorkingDirectory (Split-Path $e) -ArgumentList '--bandeja' } else { Start-Process $e -WorkingDirectory (Split-Path $e) }
  }
}

function HPOS-Tarea {
  # Copia del actualizador en los datos de HPOS y tarea programada del usuario que instala (con permisos de administrador).
  $dst = Join-Path $HPOS_Data 'actualizar.ps1'
  if ($PSCommandPath -and (Test-Path $PSCommandPath)) { if ($PSCommandPath -ne $dst) { Copy-Item $PSCommandPath $dst -Force } }
  else { Invoke-WebRequest -UseBasicParsing $HPOS_Script -OutFile $dst }
  $arg = "-NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File `"$dst`" -Actualizar"
  $act = New-ScheduledTaskAction -Execute 'powershell.exe' -Argument $arg
  $t1 = New-ScheduledTaskTrigger -AtLogOn -User "$env:USERDOMAIN\$env:USERNAME"
  $t2 = New-ScheduledTaskTrigger -Once -At ((Get-Date).AddMinutes(10)) -RepetitionInterval (New-TimeSpan -Hours 2) -RepetitionDuration (New-TimeSpan -Days 3650)
  $pr = New-ScheduledTaskPrincipal -UserId "$env:USERDOMAIN\$env:USERNAME" -LogonType Interactive -RunLevel Highest
  $st = New-ScheduledTaskSettingsSet -StartWhenAvailable -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -ExecutionTimeLimit (New-TimeSpan -Hours 1) -Hidden
  Register-ScheduledTask -TaskName $HPOS_Tarea -Action $act -Trigger @($t1, $t2) -Principal $pr -Settings $st -Description 'HPOS: instala la version nueva cuando no hay turno abierto.' -Force | Out-Null
}

function HPOS-Actualizar([bool]$ya) {
  $cur = HPOS-Instalada
  try { $l = HPOS-Ultima } catch { HPOS-Estado 'sin_internet' 'No se pudo revisar (sin internet)' $cur ''; return }
  if (-not (HPOS-Mayor $l.version $cur)) { HPOS-Estado 'al_dia' "Al dia (v$cur)" $cur $l.version; return }
  $s = HPOS-Listo
  if (-not $ya -and $s.abierto -and $s.ContainsKey('auto') -and -not $s.auto) { HPOS-Estado 'apagado' "Actualizacion automatica apagada en Ajustes (hay v$($l.version))" $cur $l.version; return }
  if (-not $ya -and -not $s.ready) { HPOS-Estado 'esperando' "v$($l.version) lista; se instala cuando no haya turno abierto" $cur $l.version; return }
  try { $estaba = HPOS-InstalarMsi $l $cur } catch { HPOS-Estado 'error' "No se pudo actualizar a v$($l.version): $($_.Exception.Message)" $cur $l.version; return }
  if ($estaba) { HPOS-Abrir -Bandeja }
  HPOS-Estado 'actualizado' ("Actualizado a v{0}" -f (HPOS-Instalada)) (HPOS-Instalada) $l.version
}

function HPOS-Principal {
  $admin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
  if (-not $admin) {
    Write-Host 'HPOS necesita permisos de administrador: acepta la ventana de Windows.' -ForegroundColor Yellow
    Start-Process powershell.exe -Verb RunAs -ArgumentList "-NoProfile -ExecutionPolicy Bypass -Command `"irm '$HPOS_Script' | iex`""
    return
  }
  Write-Host ''; Write-Host '  HPOS - instalacion para Windows' -ForegroundColor Cyan
  $cur = HPOS-Instalada
  Write-Host '  Buscando la ultima version...'
  $l = HPOS-Ultima
  if (HPOS-Mayor $l.version $cur) {
    $s = HPOS-Listo
    if (-not $s.ready -and -not $env:HPOS_YA) { Write-Host "  Hay un turno abierto. Cierralo y vuelve a pegar el comando (o se instalara solo despues)." -ForegroundColor Yellow }
    else {
      if ($cur) { Write-Host "  Actualizando v$cur -> v$($l.version)..." } else { Write-Host "  Instalando HPOS v$($l.version)..." }
      [void](HPOS-InstalarMsi $l $cur)
      HPOS-Estado 'actualizado' ("Instalado v{0}" -f (HPOS-Instalada)) (HPOS-Instalada) $l.version
    }
  } else { Write-Host "  Ya tienes la ultima version (v$cur)." }
  HPOS-Tarea
  Write-Host '  Actualizacion automatica: activada (cada 2 horas, solo sin turno abierto).'
  HPOS-Abrir
  Write-Host ''
  Write-Host '  Listo. Abre http://localhost:3000 - Usuario inicial: Admin, PIN 1234 (cambialo).' -ForegroundColor Green
  Write-Host ''
}

if ($args -contains '-Actualizar') { HPOS-Actualizar ($args -contains '-Ya') } else { HPOS-Principal }
