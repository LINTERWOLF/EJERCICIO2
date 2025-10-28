---------------------------------------------------------------------------
Automatizacion de pruebas PANAPAY con Karate
---------------------------------------------------------------------------

# 1. Objetivo del repositorio
Conjunto de pruebas automatizadas (Karate + JUnit5) que validan los procesos PANAPAY:
- Generacion de token OAuth2 (Keycloak QA)
- Afiliacion y desafiliacion de cuentas
- Consultas de credenciales y cuentas
- Transferencias financieras

Todo se ejecuta sobre Windows y usa un certificado cliente PKCS#12 para firmar las llamadas HTTPS del entorno QA.

# 2. Requisitos para Windows
Instalar y validar estas dependencias en todos los equipos:
- Windows 10 u 11 (64 bits) con PowerShell 5.1 o PowerShell 7
- Java 17 JDK (Temurin recomendado)
- Apache Maven 3.9.x
- Python 3.10 o superior (solo si se usara el script opcional de exportacion)
- Paquetes Python: `beautifulsoup4`, `openpyxl` (instalar con `pip install`)
- Certificado cliente PKCS#12: `certificado/clientcert.cbiblian.internal 1.pfx`

## 2.1 Instalacion rapida con winget (PowerShell como Administrador)
```
winget install --id EclipseAdoptium.Temurin.17.JDK -e
winget install --id Apache.Maven -e
winget install --id Python.Python.3.12 -e
```

## 2.2 Alternativa con Chocolatey
```
choco install temurin17
choco install maven
choco install python --version=3.12.5
```

## 2.3 Verificacion de versiones
```
java -version
mvn -version
python --version
```
Todas las salidas deben mostrar las versiones instaladas sin errores.

# 3. Configuracion local
1. Clonar o descargar este repositorio en una ruta sin caracteres especiales (OneDrive es soportado).
2. Confirmar que el certificado `clientcert.cbiblian.internal 1.pfx` exista en:
   - `certificado/`
   - `src/test/resources/certificado/`
3. Validar que la clave del certificado sea `Pass.cbiblian2025#`. Si cambia, ajustar `karate-config.js`.
4. Abrir una consola nueva (PowerShell) para que los cambios de PATH de Java/Maven/Python se apliquen.

# 4. Ejecucion de pruebas
## 4.1 Suite completa
```
mvn clean test
```
`TestRunner.java` ejecuta por defecto:
- `TokenGeneration.feature`
- `Transferencia.feature`

Descomentar las lineas necesarias en `src/test/java/com/ejercicio2/TestRunner.java` para incluir:
- `Afiliacion.feature`
- `Desafiliacion.feature`
- `ConsultaCredencial.feature`
- `ConsultaCuenta.feature`

## 4.2 Ejecutar un feature o tag especifico
```
mvn test -Dkarate.options="classpath:Afiliacion.feature"
mvn test -Dkarate.options="--tags @transferencia"
```

## 4.3 Parametrizacion de URLs
`karate-config.js` expone valores sobreescribibles desde Maven:
- `affiliation.baseUrl` -> `mvn test -Daffiliation.baseUrl=https://...`
- `transfer.baseUrl`   -> `mvn test -Dtransfer.baseUrl=https://...`

# 5. Arquitectura del codigo
- `pom.xml`: dependencia unica `com.intuit.karate:karate-junit5:1.4.0`.
- `karate-config.js`: carga el certificado PKCS#12, activa `trustAll: true` y publica `affiliationBaseUrl`.
- `src/test/java/com/ejercicio2/TestRunner.java`: punto de entrada JUnit5 para las suites Karate.
- `src/test/resources/*.feature`: definicion de escenarios (token, afiliacion, desafiliacion, consultas, transferencias).
- `src/test/resources/helpers/`: helpers compartidos (datos dinamicos, generacion de token, wrappers de afiliacion/desafiliacion).
- `scripts/export_afiliacion_data.py`: convierte el reporte HTML de afiliacion en JSON y Excel (requiere Python + paquetes listados).

# 6. Artefactos de ejecucion
Se generan en `target/` despues de correr las pruebas:
- `token.txt`, `token-data.json`, `token-response.json`: token OAuth y metadatos persistidos.
- `karate-reports/`: reportes HTML por feature y `karate-summary.html`.
- `surefire-reports/TEST-com.ejercicio2.TestRunner.xml`: resultados JUnit.
- `afiliacion-datos.txt`: log consolidado de escenarios de afiliacion (si se ejecuta esa suite).
- `Afiliacion.html`: base para el script Python de exportacion.

# 7. Uso del script de exportacion (opcional)
1. Ejecutar `Afiliacion.feature` para generar `target/karate-reports/Afiliacion.html`.
2. Instalar dependencias Python:
   ```
   pip install beautifulsoup4 openpyxl
   ```
3. Ejecutar:
   ```
   python scripts/export_afiliacion_data.py
   ```
   Resultado:
   - `target/afiliacion-casos.json`
   - `target/Afiliacion-casos.xlsx`

# 8. Recomendaciones y solucion de problemas
- Verificar conexion hacia `autenticacionqa.coonecta.com.ec` y `apipanapayqa.coonecta.com.ec`.
- Si aparece error SSL, asegurarse de que el certificado este en ambas rutas y que la clave sea correcta.
- El certificado expira: reemplazar el `.pfx` y actualizar `karate-config.js`.
- Para limpiar ejecuciones previas, eliminar la carpeta `target/` y volver a ejecutar Maven.
- Evitar ejecutar desde una consola sin permisos si OneDrive bloquea archivos en `target/`.

# karate_Coonecta
