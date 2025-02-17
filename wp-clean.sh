#!/bin/bash
# ---------------------------------------------------------
# Configuración:
# - Define la ruta a la carpeta uploads.
# - Permite personalizar la ruta al comando WP-CLI mediante la variable de entorno WP_CLI.
#   Ejemplo: export WP_CLI="/usr/local/bin/wp"
# ---------------------------------------------------------
UPLOADS_DIR="/var/www/html/wp-content/uploads"
WP_CLI=${WP_CLI:-"wp"}

# ---------------------------------------------------------
# Lista blanca de extensiones permitidas (imágenes y videos)
# Imágenes: jpg, jpeg, png, gif, bmp, webp, svg
# Videos: mp4, webm, ogg
# ---------------------------------------------------------
ALLOWED_EXT_REGEX='\.(jpg|jpeg|png|gif|bmp|webp|svg|mp4|webm|ogg)$'

# Activa el modo case-insensitive para las comparaciones con regex
shopt -s nocasematch

# ---------------------------------------------------------
# Variable para llevar el total de bytes eliminados
# ---------------------------------------------------------
TOTAL_BYTES=0

# ---------------------------------------------------------
# Función para actualizar en tiempo real el total eliminado (última línea)
# ---------------------------------------------------------
update_progress() {
    local total_mb
    total_mb=$(echo "scale=2; $TOTAL_BYTES/1024/1024" | bc)
    if [ -t 1 ]; then
        tput sc
        tput cup $(($(tput lines)-1)) 0
        printf "🗑️  Total eliminado: %s MB\033[K" "$total_mb"
        tput rc
    else
        echo "🗑️ Total eliminado: ${total_mb} MB"
    fi
}

echo "🚀 Iniciando limpieza en uploads (solo directorios de año) en:"
echo "    $UPLOADS_DIR"
echo "---------------------------------------------"

# ---------------------------------------------------------
# Paso 1: Precargar en memoria el contenido de posts (excluyendo attachments)
# ---------------------------------------------------------
echo "📥 Obteniendo contenido de posts..."
used_content=$($WP_CLI db query "SELECT post_content FROM wpeu_posts WHERE post_type != 'attachment'" --skip-column-names)

# ---------------------------------------------------------
# Paso 2: Precargar los datos de attachments (guid e ID)
# ---------------------------------------------------------
echo "📥 Obteniendo datos de attachments..."
attachment_data=$($WP_CLI db query "SELECT guid, ID FROM wpeu_posts WHERE post_type = 'attachment'" --skip-column-names)

# ---------------------------------------------------------
# Paso 3: Procesar únicamente directorios que sean años (4 dígitos)
# ---------------------------------------------------------
YEAR_DIRS=$(find "$UPLOADS_DIR" -maxdepth 1 -type d -regextype posix-extended -regex ".*/[0-9]{4}")

for year_dir in $YEAR_DIRS; do
    echo "📁 Procesando: $year_dir"

    # Recorre todos los archivos dentro del directorio del año
    while IFS= read -r file; do
        # Solo procesar archivos que cumplan con la lista blanca (imágenes y videos)
        if [[ ! $file =~ $ALLOWED_EXT_REGEX ]]; then
            continue
        fi

        # Obtiene la ruta relativa respecto a uploads
        REL_PATH=${file#"$UPLOADS_DIR"/}

        # Verifica si el archivo está referenciado en el contenido precargado
        if echo "$used_content" | grep -q "$REL_PATH"; then
            continue
        fi

        # El archivo no se encontró en uso; se obtiene su tamaño en bytes
        if [ -f "$file" ]; then
            file_size=$(stat -c%s "$file")
        else
            file_size=0
        fi

        # Elimina el archivo del sistema
        echo "🗑️ Eliminando: $file"
        rm "$file"
        if [ $? -eq 0 ]; then
            TOTAL_BYTES=$((TOTAL_BYTES + file_size))
            update_progress
        fi

        # Verifica si existe un registro de attachment para este archivo y lo elimina
        attachment_id=$(echo "$attachment_data" | grep -F "$REL_PATH" | awk '{print $2}' | head -n 1)
        if [ -n "$attachment_id" ]; then
            $WP_CLI post delete "$attachment_id" --force
        fi

    done < <(find "$year_dir" -type f)
done

# Muestra la actualización final y resumen
update_progress
echo ""
echo "🎉 Proceso completado. Total eliminado: $(echo "scale=2; $TOTAL_BYTES/1024/1024" | bc) MB"