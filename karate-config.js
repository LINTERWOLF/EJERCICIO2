function fn() {
  var config = {};

  // Carga el certificado cliente para entornos QA y habilita confianza en todos los hosts.
  // Configuracion SSL con certificado cliente para el host PANAPAY QA.
  var sslOptions = {
    keyStore: 'classpath:certificado/clientcert.cbiblian.internal 1.pfx',
    keyStorePassword: 'Pass.cbiblian2025#',
    keyStoreType: 'pkcs12',
    trustAll: true
  };
  try {
    // Primer intento: usar la ruta relativa dentro del classpath del proyecto.
    karate.configure('ssl', sslOptions);
  } catch (e) {
    karate.log('Fallo al cargar certificado desde classpath, usando ruta absoluta:', e.message);
    // Fallback para ejecuciones fuera de Maven/IDE donde el classpath no expone el certificado.
    sslOptions.keyStore = karate.toAbsolutePath('certificado/clientcert.cbiblian.internal 1.pfx');
    karate.configure('ssl', sslOptions);
  }

  // La base URL se puede sobrescribir con -Daffiliation.baseUrl al ejecutar las pruebas.
  config.affiliationBaseUrl = karate.properties['affiliation.baseUrl'] || 'https://apipanapayqa.coonecta.com.ec/api/switchcentral/admin';

  return config;
}
