# Documentación para wp-clean.sh

<img src="https://cdn.kiuve.com/img/kiuve-blanco.svg" alt="Kiüve Agency Logo" width="200" />
---

## Descripción

El script `wp-clean.sh` ha sido desarrollado por **Kiüve Agency** para limpiar el directorio de uploads en sitios WordPress. Este script detecta de forma automática los directorios organizados por año (por ejemplo, `2021`, `2022`, etc.) y elimina aquellos archivos de imágenes y videos que no están referenciados en el contenido de las publicaciones. Además, si se encuentra un registro de attachment en la base de datos asociado a un archivo eliminado, el script lo elimina también mediante WP-CLI.

El propósito es liberar espacio en disco y mantener el sitio organizado, eliminando archivos huérfanos que ya no se utilizan.

---

## Requisitos Previos

Antes de ejecutar el script, asegúrate de cumplir con los siguientes requisitos:

- **WP-CLI instalado**: El script utiliza WP-CLI para consultar la base de datos y eliminar registros. Puedes personalizar la ruta a WP-CLI mediante la variable de entorno `WP_CLI` (por defecto se asume que está en el PATH).
- **Acceso y permisos**:  
  - El usuario que ejecuta el script debe tener permisos para eliminar archivos del directorio de uploads.  
  - El usuario debe tener acceso para ejecutar comandos de WP-CLI y modificar la base de datos de WordPress.
- **Backup**: **¡IMPORTANTE!** Realiza una copia de seguridad completa de la base de datos y de los archivos del sitio antes de ejecutar el script, ya que eliminará archivos y registros de forma permanente.
- **Ruta del directorio de uploads**:  
  El script está configurado para apuntar a un directorio de uploads. En la versión de prueba, se utiliza una ruta genérica:
  ```bash
  UPLOADS_DIR="/var/www/html/wp-content/uploads"
  ```
  Asegúrate de actualizar esta ruta en el script según la ubicación real de tus archivos de uploads si es necesario.

---

## Cómo Ejecutar el Script

1. **Ubicación del Script**:  
   Coloca el archivo `wp-clean.sh` en la raíz del sitio (o en el directorio deseado).

2. **Dar permisos de ejecución**:  
   Antes de ejecutar el script, asegúrate de que tenga permisos de ejecución:
   ```bash
   chmod +x wp-clean.sh
   ```

3. **Ejecutar el Script**:  
   Para ejecutar el script, simplemente ejecuta:
   ```bash
   ./wp-clean.sh
   ```
   o, si no estás en el directorio donde se encuentra el script:
   ```bash
   /ruta/al/script/wp-clean.sh
   ```

4. **Monitoreo en tiempo real**:  
   Durante la ejecución, el script muestra en la última línea del terminal el total de espacio liberado en MB y registra en la salida cuáles archivos se están eliminando.

---

## Funcionamiento del Script

El script realiza las siguientes acciones:

1. **Precarga de contenido**:  
   - Obtiene el contenido de las publicaciones (excluyendo attachments) de la base de datos usando WP-CLI.
   - Obtiene los datos (guid e ID) de los attachments registrados.

2. **Detección de directorios por año**:  
   - Utiliza el comando `find` para identificar directorios en el directorio de uploads cuyo nombre coincide con un formato de 4 dígitos (e.g., `2021`, `2022`, etc.).

3. **Procesamiento y validación de archivos**:  
   - Recorre cada archivo dentro de los directorios detectados.
   - Filtra solo aquellos archivos que tengan extensiones de imagen y video (según la lista blanca definida en el script).
   - Para cada archivo, se obtiene la ruta relativa respecto al directorio de uploads y se verifica si ese nombre aparece en el contenido precargado.
   - Si el archivo **no** se encuentra referenciado en el contenido, se procede a eliminarlo y se suma su tamaño a un contador total de bytes eliminados.
   - Adicionalmente, si se encuentra un registro de attachment asociado al archivo eliminado, el script lo elimina de la base de datos usando WP-CLI.

4. **Actualización en tiempo real**:  
   - El script actualiza en la última línea del terminal el total de espacio liberado (en MB) a medida que se eliminan archivos.

---

## Puntos a Mejorar

- **Optimización del rendimiento**:  
  La búsqueda de referencias en el contenido se realiza en memoria con `grep`, lo que podría optimizarse para sitios con gran cantidad de datos.
  
- **Manejo de errores**:  
  Se podría mejorar la gestión de errores para asegurarse de que fallos en la eliminación de un archivo o registro no detengan la ejecución global del script.
  
- **Registro de acciones**:  
  Considerar la implementación de un log detallado que permita revisar posteriormente qué archivos fueron eliminados y cuáles quedaron intactos.
  
- **Compatibilidad y pruebas**:  
  Realizar pruebas en entornos de desarrollo antes de su uso en producción para asegurar que no se eliminen archivos en uso.

---

## Contexto y Contacto

Este script fue implementado por **Kiüve Agency** en respuesta a la necesidad de optimizar y limpiar los directorios de medios en sitios WordPress, liberando espacio y manteniendo la base de datos libre de archivos huérfanos.

Para más información, consulta [www.kiuve.com](https://www.kiuve.com) o contacta a **contacto@kiuve.com**.

**Creado por Kiüve Agency**