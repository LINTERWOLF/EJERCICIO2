Coloca aqui los certificados de confianza que se utilizaran durante la ejecucion.

Actualmente se usa:
- `clientcert.cbiblian.internal 1.pfx`: keystore PKCS#12 para `apipanapayqa.coonecta.com.ec` (password `Pass.cbiblian2025#`). `karate-config.js` intenta cargarlo desde `classpath:certificado/...` y, si no existe, recurre a `karate.toAbsolutePath("certificado/clientcert.cbiblian.internal 1.pfx")`. Tambien se replica en `src/test/resources/certificado/` para que Maven lo empaquete.

Recomendaciones:
- Si actualizas el certificado, conserva el formato `.pfx`/`.p12` o ajusta el tipo en `karate-config.js`.
- Documenta cualquier cambio adicional (por ejemplo, keystores personalizados o scripts de importacion) dentro de esta misma carpeta para futuras referencias.
