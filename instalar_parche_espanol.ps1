<#
.SYNOPSIS
    Installs the Spanish message overlay into a Pokemon Infinite Fusion install.
.NOTES
    Maintainer note: console output is user-facing Spanish; code comments are English.
    No external dependencies. Called by INSTALAR_PARCHE_ESPANOL.bat with UTF-8 console.
#>
param(
    [string]$Juego
)

$ErrorActionPreference = 'Stop'

# ------------------------------------------------------------------ helpers

function Write-Paso  { param([string]$Mensaje) Write-Host ('[*] ' + $Mensaje) }
function Write-Ok    { param([string]$Mensaje) Write-Host ('[OK] ' + $Mensaje) }
function Write-Aviso { param([string]$Mensaje) Write-Host ('[!] ' + $Mensaje) }

# Returns objects with the exact original terminator so line endings survive.
function Split-LinesPreservingEndings {
    param([string]$Text)

    $result = New-Object 'System.Collections.Generic.List[object]'
    $start = 0
    for ($i = 0; $i -lt $Text.Length; $i++) {
        if ($Text[$i] -eq "`n") {
            if ($i -gt $start -and $Text[$i - 1] -eq "`r") {
                $content = $Text.Substring($start, $i - 1 - $start)
                $ending = "`r`n"
            }
            else {
                $content = $Text.Substring($start, $i - $start)
                $ending = "`n"
            }
            $result.Add([pscustomobject]@{ Text = $content; Ending = $ending })
            $start = $i + 1
        }
    }
    if ($start -lt $Text.Length) {
        $result.Add([pscustomobject]@{ Text = $Text.Substring($start); Ending = '' })
    }
    return $result.ToArray()
}

function Get-BlockEnd {
    param($Lines, [int]$Start)

    for ($j = $Start + 1; $j -lt $Lines.Count; $j++) {
        if ($Lines[$j].Text -match '^\s*\]\s*,?\s*$') { return $j }
    }
    return -1
}

function Get-BlockPlan {
    param($Lines, [int]$Start, [int]$End)

    $plan = [pscustomobject]@{ French = -1; Active = -1; Commented = -1 }
    for ($k = $Start + 1; $k -lt $End; $k++) {
        $t = $Lines[$k].Text
        if ($plan.French -lt 0 -and $t -match '\["Fran[^"]*ais"\s*,\s*"french\.dat"\]') { $plan.French = $k }
        if ($plan.Active -lt 0 -and $t -match '^\s*\["Espa[^"]*ol"\s*,\s*"spanish\.dat"\]') { $plan.Active = $k }
        if ($plan.Commented -lt 0 -and $t -match '^\s*#\s*\["Espa[^"]*ol"\s*,\s*"spanish\.dat"\]') { $plan.Commented = $k }
    }
    return $plan
}

# ------------------------------------------------------------------- main

try {
    if ($PSScriptRoot) { $scriptDir = $PSScriptRoot }
    else { $scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path }
    if ([string]::IsNullOrEmpty($scriptDir)) { $scriptDir = (Get-Location).Path }

    # 1. Resolve the game folder.
    if (-not [string]::IsNullOrWhiteSpace($Juego)) {
        $juegoDir = $Juego
    }
    elseif (Test-Path -LiteralPath (Join-Path $scriptDir 'Game.ini') -PathType Leaf) {
        $juegoDir = $scriptDir
    }
    elseif (Test-Path -LiteralPath (Join-Path (Get-Location).Path 'Game.ini') -PathType Leaf) {
        $juegoDir = (Get-Location).Path
    }
    else {
        throw 'No se pudo determinar la carpeta del juego. Extrae el ZIP dentro de la carpeta del juego o indica la ruta con -Juego "C:\Ruta\Al\Juego".'
    }
    $juegoDir = [System.IO.Path]::GetFullPath($juegoDir)
    Write-Paso ('Carpeta del juego: ' + $juegoDir)

    # 2. Verify prerequisites.
    $messages = Join-Path $juegoDir 'Data\messages.dat'
    if (-not (Test-Path -LiteralPath $messages -PathType Leaf)) {
        throw ("No se encontró '$messages'. Comprueba que la ruta señale una instalación de Pokémon Infinite Fusion.")
    }

    $settings = Join-Path $juegoDir 'Data\Scripts\001_Settings.rb'
    if (-not (Test-Path -LiteralPath $settings -PathType Leaf)) {
        throw ("No se encontró '$settings'. Comprueba la estructura de la carpeta del juego.")
    }

    $srcSpanish = Join-Path $scriptDir 'Data\spanish.dat'
    if (-not (Test-Path -LiteralPath $srcSpanish -PathType Leaf)) {
        throw ("No se encontró el archivo del parche '$srcSpanish'. Extrae todo el ZIP antes de ejecutar este instalador.")
    }

    # 3. Install the overlay. One backup only; never overwrite an existing backup.
    $destSpanish = Join-Path $juegoDir 'Data\spanish.dat'
    $backupSpanish = $destSpanish + '.respaldo'
    $copiado = $false

    if (Test-Path -LiteralPath $destSpanish -PathType Leaf) {
        if (-not (Test-Path -LiteralPath $backupSpanish)) {
            Copy-Item -LiteralPath $destSpanish -Destination $backupSpanish -Force
            Write-Paso ('Se creó la copia de seguridad: ' + $backupSpanish)
        }
        else {
            Write-Aviso ('Ya existe la copia de seguridad; no se sobrescribirá: ' + $backupSpanish)
        }
    }

    $srcFull = [System.IO.Path]::GetFullPath($srcSpanish)
    $destFull = [System.IO.Path]::GetFullPath($destSpanish)
    if ($srcFull -ieq $destFull) {
        Write-Ok 'Data\spanish.dat ya está en la carpeta del juego.'
        $copiado = $true
    }
    else {
        Copy-Item -LiteralPath $srcSpanish -Destination $destSpanish -Force
        Write-Ok ('Se copió Data\spanish.dat en ' + $destSpanish)
        $copiado = $true
    }

    # 4. Patch 001_Settings.rb line by line, preserving encoding and endings.
    $bytes = [System.IO.File]::ReadAllBytes($settings)
    $hasBom = ($bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF)
    $offset = if ($hasBom) { 3 } else { 0 }
    $utf8 = New-Object System.Text.UTF8Encoding($false, $true)
    try {
        $text = $utf8.GetString($bytes, $offset, $bytes.Length - $offset)
    }
    catch {
        throw ("No se pudo leer '$settings' como UTF-8: " + $_.Exception.Message)
    }

    $lines = Split-LinesPreservingEndings -Text $text

    $kantoStart = -1
    $hoennStart = -1
    for ($i = 0; $i -lt $lines.Count; $i++) {
        $t = $lines[$i].Text
        if ($kantoStart -lt 0 -and $t -match '^\s*:IF_KANTO\s*=>\s*\[') { $kantoStart = $i }
        if ($hoennStart -lt 0 -and $t -match '^\s*:IF_HOENN\s*=>\s*\[') { $hoennStart = $i }
    }
    if ($kantoStart -lt 0) {
        throw ("No se encontró el bloque ':IF_KANTO => [' en '$settings'. Revisa el archivo manualmente.")
    }

    $kantoEnd = Get-BlockEnd -Lines $lines -Start $kantoStart
    if ($kantoEnd -lt 0) {
        throw ("No se encontró el final del bloque :IF_KANTO en '$settings'.")
    }

    $insertAfter = @{}
    $replaceAt = @{}

    # Required block: :IF_KANTO
    $plan = Get-BlockPlan -Lines $lines -Start $kantoStart -End $kantoEnd
    if ($plan.Active -ge 0) {
        Write-Ok 'El bloque :IF_KANTO ya contiene la línea de Español.'
    }
    elseif ($plan.Commented -ge 0) {
        $idx = $plan.Commented
        $newText = $lines[$idx].Text -replace '^(\s*)#\s*', '$1'
        $replaceAt[$idx] = [pscustomobject]@{ Text = $newText; Ending = $lines[$idx].Ending }
    }
    elseif ($plan.French -ge 0) {
        $idx = $plan.French
        $indent = ''
        if ($lines[$idx].Text -match '^(\s*)') { $indent = $Matches[1] }
        $insertEnding = $lines[$idx].Ending
        if ([string]::IsNullOrEmpty($insertEnding)) {
            $newline = if (($lines | Where-Object { $_.Ending -eq "`r`n" }).Count -gt 0) { "`r`n" } else { "`n" }
            $replaceAt[$idx] = [pscustomobject]@{ Text = $lines[$idx].Text; Ending = $newline }
            $insertEnding = ''
        }
        $insertAfter[$idx] = [pscustomobject]@{ Text = ($indent + '["Español", "spanish.dat"],'); Ending = $insertEnding }
    }
    else {
        throw ("No se encontró la línea de Français en el bloque :IF_KANTO de '$settings'.")
    }

    # Optional block: :IF_HOENN
    if ($hoennStart -lt 0) {
        Write-Aviso 'No se encontró el bloque :IF_HOENN; se omite (opcional para esta versión).'
    }
    else {
        $hoennEnd = Get-BlockEnd -Lines $lines -Start $hoennStart
        if ($hoennEnd -lt 0) {
            Write-Aviso 'No se encontró el final del bloque :IF_HOENN; se omite (opcional).'
        }
        else {
            $planH = Get-BlockPlan -Lines $lines -Start $hoennStart -End $hoennEnd
            if ($planH.Active -ge 0) {
                Write-Ok 'El bloque :IF_HOENN ya contiene la línea de Español.'
            }
            elseif ($planH.Commented -ge 0) {
                $idx = $planH.Commented
                $newText = $lines[$idx].Text -replace '^(\s*)#\s*', '$1'
                $replaceAt[$idx] = [pscustomobject]@{ Text = $newText; Ending = $lines[$idx].Ending }
            }
            elseif ($planH.French -ge 0) {
                $idx = $planH.French
                $indent = ''
                if ($lines[$idx].Text -match '^(\s*)') { $indent = $Matches[1] }
                $insertEnding = $lines[$idx].Ending
                if ([string]::IsNullOrEmpty($insertEnding)) {
                    $newline = if (($lines | Where-Object { $_.Ending -eq "`r`n" }).Count -gt 0) { "`r`n" } else { "`n" }
                    $replaceAt[$idx] = [pscustomobject]@{ Text = $lines[$idx].Text; Ending = $newline }
                    $insertEnding = ''
                }
                $insertAfter[$idx] = [pscustomobject]@{ Text = ($indent + '["Español", "spanish.dat"],'); Ending = $insertEnding }
            }
            else {
                Write-Aviso 'No se encontró la línea de Français en :IF_HOENN; se omite (opcional).'
            }
        }
    }

    $cambios = ($insertAfter.Count + $replaceAt.Count)
    if ($cambios -gt 0) {
        $backupSettings = $settings + '.respaldo'
        if (-not (Test-Path -LiteralPath $backupSettings)) {
            Copy-Item -LiteralPath $settings -Destination $backupSettings -Force
            Write-Paso ('Se creó la copia de seguridad: ' + $backupSettings)
        }
        else {
            Write-Aviso ('Ya existe la copia de seguridad; no se sobrescribirá: ' + $backupSettings)
        }

        $sb = New-Object System.Text.StringBuilder
        for ($i = 0; $i -lt $lines.Count; $i++) {
            $ln = $lines[$i]
            if ($replaceAt.ContainsKey($i)) { $ln = $replaceAt[$i] }
            [void]$sb.Append($ln.Text)
            [void]$sb.Append($ln.Ending)
            if ($insertAfter.ContainsKey($i)) {
                $added = $insertAfter[$i]
                [void]$sb.Append($added.Text)
                [void]$sb.Append($added.Ending)
            }
        }

        $newBytes = $utf8.GetBytes($sb.ToString())
        if ($hasBom) {
            $finalBytes = New-Object byte[] ($newBytes.Length + 3)
            $finalBytes[0] = 0xEF
            $finalBytes[1] = 0xBB
            $finalBytes[2] = 0xBF
            [Array]::Copy($newBytes, 0, $finalBytes, 3, $newBytes.Length)
        }
        else {
            $finalBytes = $newBytes
        }
        [System.IO.File]::WriteAllBytes($settings, $finalBytes)
        Write-Ok ('Se actualizó 001_Settings.rb (' + $cambios + ' cambio(s)).')
    }
    else {
        Write-Ok '001_Settings.rb ya estaba configurado; no se modificó.'
    }

    # 5. Final summary.
    Write-Host ''
    Write-Ok 'Instalación finalizada.'
    Write-Paso 'Resumen:'
    Write-Host ('  - Datos del idioma: ' + $(if ($copiado) { 'Data\spanish.dat disponible' } else { 'sin cambios' }))
    Write-Host ('  - Configuración: ' + $(if ($cambios -gt 0) { '001_Settings.rb actualizado' } else { '001_Settings.rb ya era correcto' }))
    Write-Host ''
    Write-Paso 'Siguiente paso: inicia el juego y elige Español en el selector de idioma.'
    Write-Paso 'Si ya tienes una partida guardada, pulsa el icono del globo en la pantalla de título/carga y elige Español.'
    Write-Aviso 'Ese cambio reescribe el archivo de guardado y vuelve al título; haz una copia antes si quieres conservarlo.'
    exit 0
}
catch {
    Write-Host ''
    Write-Host ('[ERROR] ' + $_.Exception.Message) -ForegroundColor Red
    Write-Host '[ERROR] No se completó la instalación.' -ForegroundColor Red
    exit 1
}
