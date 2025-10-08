Proyecto: Suite de autenticacion Demoblaze con Karate
====================================================

1. Prerrequisitos
   - Windows 10 o superior (se puede ejecutar en Linux o macOS ajustando los comandos a bash).
   - Java 17 instalado (`java -version` debe mostrar 17.x).
   - Maven 3.9+ instalado (`mvn -version` debe mostrar la ruta correcta).
   - Acceso a Internet para consumir la API publica `https://api.demoblaze.com`.
   - Si Windows muestra la advertencia de seguridad al ejecutar `mvn.cmd`, desbloquea los scripts con `PowerShell`:
     `Get-ChildItem 'C:\Apache\apache-maven-3.9.11\bin\*.cmd' | Unblock-File` (ajusta la ruta según tu instalación).

2. Preparacion del entorno
   1. Clonar o descargar el repositorio en una carpeta local.
   2. Abrir una consola en la carpeta `karate-EJERCICIO2`.
   3. (Opcional) Ejecutar `mvn clean` para iniciar con un directorio `target` vacio.

3. Ejecucion paso a paso
   1. Ejecutar `mvn test`.
    2. El runner `com.ejercicio2.TestRunner` dispara la feature `DemoblazeAuth.feature`, que realiza en orden:
      - Creacion dinamica de un usuario nuevo (signup).
      - Intento de registrar nuevamente el mismo usuario.
      - Login con credenciales correctas.
      - Login con password incorrecta.
   3. Verificar el resultado en consola: debe mostrarse `BUILD SUCCESS`.

4. Reportes generados
    - Reporte HTML: `karate-EJERCICIO2/target/karate-reports/DemoblazeAuth.html`.
    - Resumen HTML: `karate-EJERCICIO2/target/karate-reports/karate-summary.html`.
    - Reporte JUnit: `karate-EJERCICIO2/target/surefire-reports/TEST-com.ejercicio2.TestRunner.xml`.
   Abra los archivos HTML en un navegador para revisar evidencias.

5. Empaquetado final requerido
   1. Ejecutar las pruebas para regenerar los reportes.
   2. Copiar dentro de una carpeta temporal:
      - El directorio `karate-EJERCICIO2` completo (incluye scripts y reportes).
      - Este archivo `readme.txt`.
      - El archivo `conclusiones.txt`.
   3. Comprimir la carpeta en un archivo `.zip`.
   4. Enviar el `.zip` a las direcciones de correo previamente indicadas, adjuntando cualquier instruccion adicional si la organizacion lo solicita.

6. Notas adicionales
   - Las credenciales se generan en tiempo de ejecucion mediante UUID, evitando interferencias entre corridas.
   - Si el login exitoso retorna un token, el flujo lo acepta y lo registra en el log del escenario.
