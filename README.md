# Parche de español para Pokémon Infinite Fusion

Este parche añade los textos del juego en español mediante un archivo de datos nativo (`Data/spanish.dat`). No requiere instalar ningún programa: basta con copiar el archivo, registrar el idioma en la configuración y elegir **Español** dentro del juego. Los textos todavía no traducidos se muestran en inglés de forma intencional.

## 1. Qué es y qué hace

- `Data/spanish.dat`: capa de traducción (overlay) que se aplica sobre los mensajes del juego.
- `Data/Scripts/001_Settings.rb`: registro del idioma Español en la lista `LANGUAGES`.
- Instalador automático (`INSTALAR_PARCHE_ESPANOL.bat`) y esta guía.

El juego lee la capa directamente; no hay que ejecutar nada mientras se juega. Cuando un texto no está en la capa, se usa el original en inglés.

## 2. Requisitos

- Windows.
- Una instalación de Pokémon Infinite Fusion en su versión inglesa/internacional que contenga `Data\messages.dat`.
- El parche está preparado para los datos de mensajes de esta versión concreta del juego (6.8.2). Si `Data\messages.dat` cambia tras una actualización, la capa debe recompilarse (véase la sección 8).

## 3. Descarga

Descarga el archivo `parche_espanol.zip` desde la raíz de este repositorio: https://github.com/Manstor21/infinitefusion-parche-espanol/blob/main/parche_espanol.zip . Si el enlace directo no abre, entra al repositorio y descarga el archivo desde la lista de archivos.

## 4. Instalación rápida (instalador automático)

1. Extrae todo el contenido de `parche_espanol.zip` en la carpeta del juego (la que contiene `Game.ini`).
2. Ejecuta `INSTALAR_PARCHE_ESPANOL.bat` con doble clic. Si Windows muestra una advertencia de PowerShell, confirma la ejecución.
3. Inicia el juego y elige **Español** en el selector de idioma (o en el icono del globo si ya tienes partida).

Si habías personalizado `Data\Scripts\001_Settings.rb`, extrae el ZIP en una carpeta aparte y ejecuta el instalador indicando la ruta del juego para conservar tu archivo original:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File ".\instalar_parche_espanol.ps1" -Juego "C:\Ruta\Al\Juego"
```

## 5. Instalación manual (alternativa)

1. Copia `Data\spanish.dat` del ZIP en `<juego>\Data\spanish.dat`.
2. Haz una copia de seguridad de `<juego>\Data\Scripts\001_Settings.rb` antes de editarlo.
3. Abre ese archivo con un editor de texto. Si la línea `["Español", "spanish.dat"],` ya existe en el bloque `:IF_KANTO => [`, no hagas nada más.
4. Si no existe, añádela justo después de la línea de `Français` dentro de ese bloque:

Antes:

```ruby
    :IF_KANTO => [
      ["English", "english.dat"],
      ["Français", "french.dat"],
    ],
```

Después:

```ruby
    :IF_KANTO => [
      ["English", "english.dat"],
      ["Français", "french.dat"],
      ["Español", "spanish.dat"],
    ],
```

La línea equivalente en el bloque `:IF_HOENN => [` es opcional; esta compilación utiliza `:IF_KANTO`.

## 6. Activar el idioma dentro del juego

**Partida nueva (sin guardado):** al iniciar aparece el selector de idioma. Elige **Español** (tercera opción, después de English y Français). La elección se conserva al guardar la partida.

**Partida existente:** en la pantalla de título/carga hay un icono de globo terráqueo. Haz clic en él y elige **Español**.

> **Importante:** al elegir el idioma desde el globo, el juego reescribe el archivo de guardado de inmediato (`Marshal.dump` en la ruta de guardado) y vuelve al título. Haz una copia de tus guardados antes si quieres conservar el original. No existe un menú de "Language" dentro de la partida ya cargada.

Para volver al inglés, usa el mismo icono del globo y elige **English**.

## 7. Desinstalar o volver al inglés

1. Usa el icono del globo → **English**.
2. Opcional: elimina `<juego>\Data\spanish.dat`.
3. Opcional: restaura `<juego>\Data\Scripts\001_Settings.rb` desde `001_Settings.rb.respaldo`, o quita la línea `["Español", "spanish.dat"],`.

## 8. Después de actualizaciones

Vuelve a aplicar el parche después de cada actualización del juego. En particular, `INSTALL_OR_UPDATE.bat` ejecuta `git reset --hard origin/releases` en la línea 28, lo que descarta la línea añadida a `001_Settings.rb`.

1. Vuelve a ejecutar `INSTALAR_PARCHE_ESPANOL.bat` (o repite la instalación manual).
2. Inicia el juego y comprueba el idioma; si hace falta, selecciónalo de nuevo con el globo.

Si la actualización modifica `Data\messages.dat`, este paquete debe recompilarse; la nota final para mantenedores indica cómo.

## 9. Verificación

- Tamaño esperado de `Data\spanish.dat`: `2,826,117` bytes.
- SHA256 esperado: `3806F3982FC461FCC84AC2E46E781B453164B9FBE6897564B5762945AE238DD8`.

Desde la carpeta del juego, en PowerShell:

```powershell
Get-FileHash .\Data\spanish.dat -Algorithm SHA256
```

Textos que deberían aparecer en español: `Idioma`, `Nuevo Juego`, `Continuar`, `Opciones del Sistema`, `Salir del Juego`, `PS`, `Poción`, `Placaje`.

## 10. Limitaciones conocidas

- Los nombres propios y los nombres personalizados de fusiones no se traducen.
- Aproximadamente el 8 % de los espacios (2.897 de 31.441) permanecen en inglés a propósito: nombres, IDs de MT/MO, cadenas de depuración, rutas y plantillas de formato.
- Texto que añadan actualizaciones futuras puede no estar traducido.
- Terminología utilizada: Placaje, Ascuas, Poción, Ciudad Celeste, Ciudad Azulona, Pueblo Paleta, MT/MO, PS.

## 11. Preguntas frecuentes

**No aparece la opción Español.** Falta la línea en `001_Settings.rb` o una actualización la sobrescribió. Vuelve a ejecutar el instalador.

**El juego sigue en inglés.** El idioma no se ha seleccionado o estás abriendo otra carpeta del juego. Revisa la ruta y vuelve a elegir Español en el selector o en el globo.

**El juego se cierra al iniciar.** Elimina `Data\spanish.dat` para volver al inglés y comprueba que `Data\messages.dat` no haya cambiado.

---

## MAINTAINER ONLY — not part of the user-facing steps

- Built from HEAD `7d4f2488ed49baddf86170e95760acb34aa7e93e`. `Data/messages.dat` baseline: 31,059,341 bytes, SHA256 `AD5FD4CF837909F619360F49C546241EFAE79FA6B63864D391116063065777D6`.
- The overlay targets 47 sections / 31,441 slots (28,544 translated, 90.79%). If `messages.dat` changes, rebuild with `python translation_tools/compile.py` and check with `python translation_tools/verify.py`, then rebuild `parche_espanol.zip`.
- This package is hosted in this private repository at https://github.com/Manstor21/infinitefusion-parche-espanol . Access must be granted to each intended downloader individually. No upload beyond this push was performed.
