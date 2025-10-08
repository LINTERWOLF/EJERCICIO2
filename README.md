--------------------------------------------------------------------------
Suite de pruebas Karate para los servicios de autenticacion de Demoblaze
--------------------------------------------------------------------------

1. Requisitos
   - Windows 10 o superior
   - Java 17 (JDK)
   - Apache Maven 3.9.1 (configurado en el PATH)
   - Si Windows alerta con "Editor desconocido" al ejecutar `mvn.cmd`, abre PowerShell y ejecuta
     `Get-ChildItem 'C:\Apache\apache-maven-3.9.11\bin\*.cmd' | Unblock-File` (ajusta la ruta segun tu instalacion) para quitar la marca de archivo descargado.

2. Instalacion rapida de dependencias (PowerShell con privilegios de administrador)
   - Java 17 (Temurin): `winget install --id EclipseAdoptium.Temurin.17.JDK -e`
   - Maven 3.9.x: `winget install --id Apache.Maven -e`
   - Verificacion de versiones: `java -version` y `mvn -version`
   - Alternativa con Chocolatey (si ya lo tienes instalado):
     - `choco install temurin17`
     - `choco install maven`

3. Comandos basicos
   - `mvn clean install`
   - `mvn test`

4. Como ejecutar las pruebas
   - Descarga el proyecto y abrelo en tu IDE preferido (por ejemplo IntelliJ IDEA).
   - Ejecuta los comandos anteriores desde la terminal del IDE o desde una consola en la raiz del proyecto `karate-EJERCICIO2`.

5. Escenarios cubiertos
   - Creacion de usuario dinamico en `https://api.demoblaze.com/signup`.
   - Intento de creacion duplicada del mismo usuario dinamico.
   - Inicio de sesion exitoso con el usuario creado.
   - Inicio de sesion con password incorrecta.

6. Reportes
   - Revisa `target/karate-reports/DemoblazeAuth.html` despues de ejecutar `mvn test`.
