@afiliacion
Feature: Afiliacion de clientes PANAPAY (Validacion por escenarios)

  Background:
    * def tokenContext = callonce read('classpath:helpers/generate-token.feature')
    * def tokenData = tokenContext.tokenInfo
    * def baseUrl = affiliationBaseUrl
    * url baseUrl
    * def authHeaders = { 'Content-Type': 'application/json' }
    * set authHeaders.Authorization = 'Bearer ' + tokenData.auth_tokencb
    * configure headers = authHeaders
    * def generators = call read('classpath:helpers/affiliation-data.js')
    * def inactiveEntities = ['IFI-900', 'IFI-901']
    * def registeredAccounts = ['31000000000000000000']
    * def registeredMobiles = ['0999999999']
    * def registeredMsgIds = ['MSG-USED-001']
    * def projectDir = karate.properties['karate.project.dir'] ? karate.properties['karate.project.dir'] : java.lang.System.getProperty('user.dir')
    * def logFilePath = projectDir + java.io.File.separator + 'target' + java.io.File.separator + 'afiliacion-datos.txt'
    * def initLog =
    """
    function(path){
      var Paths = Java.type('java.nio.file.Paths');
      var Files = Java.type('java.nio.file.Files');
      var p = Paths.get(path);
      var parent = p.getParent();
      if (parent) {
        Files.createDirectories(parent);
      }
      if (Files.exists(p)) {
        Files.delete(p);
      }
    }
    """
    * eval
    """
    var initialized = karate.get('logFileInitialized');
    if (!initialized) {
      initLog(logFilePath);
      karate.set('logFileInitialized', true);
    }
    """
    * def logScenario =
    """
    function(name, payload, status){
      var Paths = Java.type('java.nio.file.Paths');
      var Files = Java.type('java.nio.file.Files');
      var StandardCharsets = Java.type('java.nio.charset.StandardCharsets');
      var StandardOpenOption = Java.type('java.nio.file.StandardOpenOption');
      var p = Paths.get(logFilePath);
      Files.createDirectories(p.getParent());
      var pretty = karate.pretty(payload);
      var entry = '--- ' + name + ' ---\\nstatusEsperado=200\\nstatusReal=' + status + '\\n' + pretty + '\\n\\n';
      Files.write(p, entry.getBytes(StandardCharsets.UTF_8), StandardOpenOption.CREATE, StandardOpenOption.APPEND);
    }
    """

  Scenario: Afiliación en el directorio electrónico de un usuario con cédula válida, celular válido y cuenta de ahorros válida
    * def payload = generators.generateAffiliationPayload({ instgAgtFinInstnId: tokenData.coop_codecb })
    Given path 'afiliacion'
    And request payload
    When method post
    * eval logScenario('Cédula válida, celular válido, ahorro válido', payload, responseStatus)
    Then status 200

  Scenario: Afiliación en el directorio electrónico de un usuario con cédula no válida (más de 10 dígitos) y celular válido
    * def payload = generators.generateAffiliationPayload({ instgAgtFinInstnId: tokenData.coop_codecb, docType: 'CDI' })
    * set payload.acctEnroll.acct.docId = payload.acctEnroll.acct.docId + '99'
    Given path 'afiliacion'
    And request payload
    When method post
    * eval logScenario('Cédula con más de 10 dígitos', payload, responseStatus)
    Then status 200

  Scenario: Afiliación en el directorio electrónico de un usuario con cédula no válida (menos de 10 dígitos) y celular válido
    * def payload = generators.generateAffiliationPayload({ instgAgtFinInstnId: tokenData.coop_codecb, docType: 'CDI' })
    * set payload.acctEnroll.acct.docId = generators.randomDigits(8)
    Given path 'afiliacion'
    And request payload
    When method post
    * eval logScenario('Cédula con menos de 10 dígitos', payload, responseStatus)
    Then status 200

  Scenario: Afiliación en el directorio electrónico de un usuario con cédula válida y celular no válido
    * def payload = generators.generateAffiliationPayload({ instgAgtFinInstnId: tokenData.coop_codecb })
    * set payload.acctEnroll.othr.cred[0].value = '081234567'
    Given path 'afiliacion'
    And request payload
    When method post
    * eval logScenario('Celular inválido', payload, responseStatus)
    Then status 200

  Scenario: Afiliación en el directorio electrónico de un usuario con cédula válida y cuenta de ahorro no válida (No existe en el Core)
    * def payload = generators.generateAffiliationPayload({ instgAgtFinInstnId: tokenData.coop_codecb })
    * set payload.acctEnroll.acct.acctId = generators.randomDigits(15)
    Given path 'afiliacion'
    And request payload
    When method post
    * eval logScenario('Cuenta de ahorro inexistente', payload, responseStatus)
    Then status 200

  Scenario: Afiliación en el directorio electrónico de un usuario con pasaporte válido, celular válido y cuenta de ahorros válida
    * def payload = generators.generateAffiliationPayload({ instgAgtFinInstnId: tokenData.coop_codecb, docType: 'PAS' })
    Given path 'afiliacion'
    And request payload
    When method post
    * eval logScenario('Pasaporte válido, ahorro válido', payload, responseStatus)
    Then status 200

  Scenario: Afiliación en el directorio electrónico de un usuario con RUC válido, celular válido y cuenta de ahorros válida
    * def payload = generators.generateAffiliationPayload({ instgAgtFinInstnId: tokenData.coop_codecb, docType: 'RUC' })
    Given path 'afiliacion'
    And request payload
    When method post
    * eval logScenario('RUC válido, ahorro válido', payload, responseStatus)
    Then status 200

  Scenario: Afiliación en el directorio electrónico de un usuario con cédula válida y cuenta de ahorro bloqueada por transacciones operativas
    * def payload = generators.generateAffiliationPayload({ instgAgtFinInstnId: tokenData.coop_codecb, acctStatus: 'BLOCKED_OPERATIONS' })
    Given path 'afiliacion'
    And request payload
    When method post
    * eval logScenario('Cuenta ahorro bloqueada', payload, responseStatus)
    Then status 200

  Scenario: Afiliación en el directorio electrónico de un usuario con cédula válida y cuenta de ahorro inactiva o cerrada
    * def payload = generators.generateAffiliationPayload({ instgAgtFinInstnId: tokenData.coop_codecb, acctStatus: 'INACTIVE' })
    Given path 'afiliacion'
    And request payload
    When method post
    * eval logScenario('Cuenta ahorro inactiva', payload, responseStatus)
    Then status 200

  Scenario: Afiliación en el directorio electrónico de un usuario con cédula válida, celular válido y cuenta corriente válida
    * def payload = generators.generateAffiliationPayload({ instgAgtFinInstnId: tokenData.coop_codecb, accountType: 'CTA_CORRIENTE' })
    Given path 'afiliacion'
    And request payload
    When method post
    * eval logScenario('Cuenta corriente válida', payload, responseStatus)
    Then status 200

  Scenario: Afiliación en el directorio electrónico de un usuario con cédula válida y cuenta corriente no válida (No existe en el Core)
    * def payload = generators.generateAffiliationPayload({ instgAgtFinInstnId: tokenData.coop_codecb, accountType: 'CTA_CORRIENTE' })
    * set payload.acctEnroll.acct.acctId = generators.randomDigits(12)
    Given path 'afiliacion'
    And request payload
    When method post
    * eval logScenario('Cuenta corriente inexistente', payload, responseStatus)
    Then status 200

  Scenario: Afiliación en el directorio electrónico de un usuario con pasaporte válido, celular válido y cuenta corriente válida
    * def payload = generators.generateAffiliationPayload({ instgAgtFinInstnId: tokenData.coop_codecb, docType: 'PAS', accountType: 'CTA_CORRIENTE' })
    Given path 'afiliacion'
    And request payload
    When method post
    * eval logScenario('Pasaporte válido, cuenta corriente', payload, responseStatus)
    Then status 200

  Scenario: Afiliación en el directorio electrónico de un usuario con RUC válido, celular válido y cuenta corriente válida
    * def payload = generators.generateAffiliationPayload({ instgAgtFinInstnId: tokenData.coop_codecb, docType: 'RUC', accountType: 'CTA_CORRIENTE' })
    Given path 'afiliacion'
    And request payload
    When method post
    * eval logScenario('RUC válido, cuenta corriente', payload, responseStatus)
    Then status 200

  Scenario: Afiliación en el directorio electrónico de un usuario con cédula válida, celular válido y correo válido
    * def payload = generators.generateAffiliationPayload({ instgAgtFinInstnId: tokenData.coop_codecb })
    Given path 'afiliacion'
    And request payload
    When method post
    * eval logScenario('Correo válido', payload, responseStatus)
    Then status 200

  Scenario: Afiliación en el directorio electrónico de un usuario con una cuenta ya registrada en el directorio
    * def payload = generators.generateAffiliationPayload({ instgAgtFinInstnId: tokenData.coop_codecb })
    * set payload.acctEnroll.acct.acctId = registeredAccounts[0]
    Given path 'afiliacion'
    And request payload
    When method post
    * eval logScenario('Cuenta duplicada', payload, responseStatus)
    Then status 200

  Scenario: Afiliación en el directorio electrónico de un usuario con un número celular asociado a otro usuario de la misma entidad
    * def payload = generators.generateAffiliationPayload({ instgAgtFinInstnId: tokenData.coop_codecb })
    * set payload.acctEnroll.othr.cred[0].value = registeredMobiles[0]
    Given path 'afiliacion'
    And request payload
    When method post
    * eval logScenario('Celular duplicado', payload, responseStatus)
    Then status 200

  Scenario: Afiliación en el directorio electrónico de un usuario que dispone de dos cuentas en la misma IFI
    * def secondaryAccount = { acctTp: '10', acctId: generators.generateAccountId('CTA_AHORROS') }
    * def payload = generators.generateAffiliationPayload({ instgAgtFinInstnId: tokenData.coop_codecb, secondaryAccounts: [secondaryAccount] })
    Given path 'afiliacion'
    And request payload
    When method post
    * eval logScenario('Dos cuentas misma IFI', payload, responseStatus)
    Then status 200

  Scenario: Afiliación en el directorio electrónico de un mismo usuario en dos entidades
    * def payload = generators.generateAffiliationPayload({ instgAgtFinInstnId: tokenData.coop_codecb, beneficiaryEntity: 'IFI-003' })
    Given path 'afiliacion'
    And request payload
    When method post
    * eval logScenario('Usuario en dos entidades', payload, responseStatus)
    Then status 200

  Scenario: Afiliación en el directorio electrónico de un usuario que la entidad no sea la misma IFI receptora-Token
    * def payload = generators.generateAffiliationPayload({ instgAgtFinInstnId: '9999' })
    Given path 'afiliacion'
    And request payload
    When method post
    * eval logScenario('Entidad diferente al token', payload, responseStatus)
    Then status 200

  Scenario: Afiliación en el directorio electrónico con un token caducado
    * def payload = generators.generateAffiliationPayload({ instgAgtFinInstnId: tokenData.coop_codecb })
    * configure headers = { 'Content-Type': 'application/json', Authorization: 'Bearer expired-token' }
    Given path 'afiliacion'
    And request payload
    When method post
    * eval logScenario('Token caducado', payload, responseStatus)
    * configure headers = authHeaders
    Then status 200

  Scenario: Afiliación en el directorio electrónico de un usuario donde la entidad Ordenante se encuentra inactiva
    * def payload = generators.generateAffiliationPayload({ instgAgtFinInstnId: tokenData.coop_codecb, orderingEntity: inactiveEntities[0] })
    Given path 'afiliacion'
    And request payload
    When method post
    * eval logScenario('Entidad ordenante inactiva', payload, responseStatus)
    Then status 200

  Scenario: Afiliación en el directorio electrónico de un usuario donde la entidad Beneficiaria se encuentra inactiva
    * def payload = generators.generateAffiliationPayload({ instgAgtFinInstnId: tokenData.coop_codecb, beneficiaryEntity: inactiveEntities[1] })
    Given path 'afiliacion'
    And request payload
    When method post
    * eval logScenario('Entidad beneficiaria inactiva', payload, responseStatus)
    Then status 200

  Scenario: Afiliación en el directorio electrónico de un usuario donde la fecha transacción se encuentra fuera del rango
    * def payload = generators.generateAffiliationPayload({ instgAgtFinInstnId: tokenData.coop_codecb, transactionDate: '2020-01-01T00:00:00' })
    * set payload.grpHdr.creDtTm = '2020-01-01T00:00:00'
    Given path 'afiliacion'
    And request payload
    When method post
    * eval logScenario('Fecha de transacción fuera de rango', payload, responseStatus)
    Then status 200

  Scenario: Afiliación en el directorio electrónico de un usuario donde se envió un MsgId ya utilizado
    * def payload = generators.generateAffiliationPayload({ instgAgtFinInstnId: tokenData.coop_codecb, msgId: registeredMsgIds[0] })
    Given path 'afiliacion'
    And request payload
    When method post
    * eval logScenario('MsgId duplicado', payload, responseStatus)
    Then status 200

  Scenario: Actualización de un usuario con credencial cédula en el directorio electrónico datos de nombre y credencial (celular)
    * def payload = generators.generateAffiliationPayload({ instgAgtFinInstnId: tokenData.coop_codecb })
    * set payload.acctEnroll.operationType = 'UPDT'
    * set payload.acctEnroll.acct.nm = 'Actualizado ' + payload.acctEnroll.acct.nm
    * set payload.acctEnroll.othr.cred[0].value = generators.generateMobile()
    Given path 'afiliacion'
    And request payload
    When method post
    * eval logScenario('Actualización con nuevos datos', payload, responseStatus)
    Then status 200

  Scenario: Actualización de un usuario con la credencial celular perteneciente a otro usuario
    * def payload = generators.generateAffiliationPayload({ instgAgtFinInstnId: tokenData.coop_codecb })
    * set payload.acctEnroll.operationType = 'UPDT'
    * set payload.acctEnroll.othr.cred[0].value = registeredMobiles[0]
    Given path 'afiliacion'
    And request payload
    When method post
    * eval logScenario('Actualización con celular duplicado', payload, responseStatus)
    Then status 200
