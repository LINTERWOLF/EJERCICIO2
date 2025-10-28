@consultacredencial
Feature: Consulta de credenciales PANAPAY

  Background:
    * def tokenContext = callonce read('classpath:helpers/generate-token.feature')
    * def tokenData = tokenContext.tokenInfo
    * def baseUrl = affiliationBaseUrl
    * url baseUrl
    * def authHeaders = { 'Content-Type': 'application/json' }
    * set authHeaders.Authorization = 'Bearer ' + tokenData.auth_tokencb
    * configure headers = authHeaders
    * def buildPayload =
    """
    function(caseData) {
      var token = karate.get('tokenData');
      var LocalDateTime = Java.type('java.time.LocalDateTime');
      var DateTimeFormatter = Java.type('java.time.format.DateTimeFormatter');
      var timestamp = LocalDateTime.now().format(DateTimeFormatter.ofPattern("yyyy-MM-dd'T'HH:mm:ss"));
      var randomDigits = function(length) {
        var digits = '';
        for (var i = 0; i < length; i++) {
          digits += Math.floor(Math.random() * 10);
        }
        return digits;
      };
      return {
        GrpHdr: {
          msgId: token.coop_codecb + token.currentDate + randomDigits(13),
          creDtTm: timestamp,
          NbOfTxs: 1,
          SttlmInf: { SttlmMtd: "INGA" },
          InstgAgt: { finInstnId: token.coop_codecb },
          InstdAgt: { FinInstnId: "0000" },
          Mge: { Type: "acmt.998.441.01" },
          ChnlId: "WEB"
        },
        QryAccByCred: {
          Cred: {
            Id: caseData.credId,
            Value: caseData.credValue
          }
        }
      };
    }
    """
    * def assertResponse =
    """
    function(caseData, body) {
      var qry = body.QryAccByCred || body.qryAccByCred;
      if (!qry) {
        karate.fail('Respuesta invalida para consulta de credencial: ' + karate.pretty(body));
      }
      if (caseData.expectedTxStatus) {
        karate.match(qry.TxSts || qry.txSts, caseData.expectedTxStatus);
      }
    }
    """
    * def verifyHttpStatus =
    """
    function(caseData) {
      var expected = caseData.expectedStatus;
      if (expected === null || typeof expected === 'undefined') {
        karate.log('HTTP status no validado para este caso de prueba');
        return;
      }
      var actual = karate.get('responseStatus');
      if (actual != expected) {
        karate.fail('Estado HTTP esperado ' + expected + ' pero fue ' + actual);
      }
    }
    """

  Scenario: Validacion Consulta Credencial Celular de un usuario afiliado con cedula y con cuenta de ahorro
    * def caseData = { credId: 'CEL', credValue: '0966581609', expectedStatus: 200, expectedTxStatus: 'OK' }
    * def payload = buildPayload(caseData)
    Given path 'consulta_credencial'
    And request payload
    When method post
    Then eval verifyHttpStatus(caseData)
    * eval assertResponse(caseData, response)

  Scenario: Validacion Consulta Credencial Email de un usuario afiliado con cedula y con cuenta de ahorro
    * def caseData = { credId: 'EMA', credValue: 'carla.guzman59@qa-affiliations.com', expectedStatus: 200, expectedTxStatus: 'OK' }
    * def payload = buildPayload(caseData)
    Given path 'consulta_credencial'
    And request payload
    When method post
    Then eval verifyHttpStatus(caseData)
    * eval assertResponse(caseData, response)

  Scenario: Validacion Consulta Credencial QR de un usuario afiliado con cedula y con cuenta de ahorro
    * def caseData = { credId: 'CQR', credValue: 'Vhdo8ld9EAooslM70cOMRPGASTkdGBND0UABmFcATNg=', expectedStatus: 200, expectedTxStatus: 'ERR' }
    * def payload = buildPayload(caseData)
    Given path 'consulta_credencial'
    And request payload
    When method post
    Then eval verifyHttpStatus(caseData)
    * eval assertResponse(caseData, response)

  Scenario: Validacion Consulta Credencial Celular de un usuario afiliado con cedula y  con cuenta corriente
    * def caseData = { credId: 'CEL', credValue: '0929976374', expectedStatus: 200, expectedTxStatus: 'OK' }
    * def payload = buildPayload(caseData)
    Given path 'consulta_credencial'
    And request payload
    When method post
    Then eval verifyHttpStatus(caseData)
    * eval assertResponse(caseData, response)

  Scenario: Validacion Consulta Credencial Celular, usuario desafiliado
    * def caseData = { credId: 'CEL', credValue: '0987440101', expectedStatus: 200, expectedTxStatus: 'OK' }
    * def payload = buildPayload(caseData)
    Given path 'consulta_credencial'
    And request payload
    When method post
    Then eval verifyHttpStatus(caseData)
    * eval assertResponse(caseData, response)

  Scenario: Validacion Consulta Credencial QR no existe
    * def caseData = { credId: 'CQR', credValue: 'rz1C3ZeDREbLgDK1G1/g32fVW0iD4fe8RjbFMM13mmo=', expectedStatus: 200, expectedTxStatus: 'ERR' }
    * def payload = buildPayload(caseData)
    Given path 'consulta_credencial'
    And request payload
    When method post
    Then eval verifyHttpStatus(caseData)
    * eval assertResponse(caseData, response)

  Scenario: Validacion Consulta Credencial con tipo de credencial incorrecta
    * def caseData = { credId: '1', credValue: '0966581609', expectedStatus: 200, expectedTxStatus: 'ERR' }
    * def payload = buildPayload(caseData)
    Given path 'consulta_credencial'
    And request payload
    When method post
    Then eval verifyHttpStatus(caseData)
    * eval assertResponse(caseData, response)

  @case_0984392496
  Scenario: Validacion Consulta Credencial Celular 0984392496
    * def caseData = { credId: 'CEL', credValue: '0984392496', expectedStatus: 200, expectedTxStatus: 'OK' }
    * def payload = buildPayload(caseData)
    Given path 'consulta_credencial'
    And request payload
    When method post
    Then eval verifyHttpStatus(caseData)
    * print 'HTTP status:', responseStatus, 'TxSts:', response.QryAccByCred ? response.QryAccByCred.TxSts : null
    * eval assertResponse(caseData, response)

  @negative @cel_formato_invalido
  Scenario: Validacion error consulta credencial celular con formato invalido
    * def caseData = { credId: 'CEL', credValue: 'ABC123', expectedStatus: 200, expectedTxStatus: 'ERR' }
    * def payload = buildPayload(caseData)
    Given path 'consulta_credencial'
    And request payload
    When method post
    Then eval verifyHttpStatus(caseData)
    * eval assertResponse(caseData, response)
    * match response.QryAccByCred.Rsn.RsnCd == '1001'
    * match karate.lowerCase(response.QryAccByCred.Rsn.AddtlInf) contains 'no se ha encontrado un cliente'

  @negative @email_formato_invalido
  Scenario: Validacion error consulta credencial email con formato invalido
    * def caseData = { credId: 'EMA', credValue: 'correo-sin-dominio', expectedStatus: 200, expectedTxStatus: 'ERR' }
    * def payload = buildPayload(caseData)
    Given path 'consulta_credencial'
    And request payload
    When method post
    Then eval verifyHttpStatus(caseData)
    * eval assertResponse(caseData, response)
    * match response.QryAccByCred.Rsn.RsnCd == '1001'
    * match karate.lowerCase(response.QryAccByCred.Rsn.AddtlInf) contains 'credenciales utilizadas'

  @negative @credencial_sin_valor
  Scenario: Validacion error consulta credencial sin valor
    * def caseData = { credId: 'CEL', credValue: '', expectedStatus: 200, expectedTxStatus: 'ERR' }
    * def payload = buildPayload(caseData)
    * remove payload.QryAccByCred.Cred.Value
    Given path 'consulta_credencial'
    And request payload
    When method post
    Then eval verifyHttpStatus(caseData)
    * eval assertResponse(caseData, response)
    * match response.QryAccByCred.Rsn.RsnCd == '9000'
    * match response.QryAccByCred.Rsn.AddtlInf contains 'Value) es requerido'

  @negative @credencial_sin_tipo
  Scenario: Validacion error consulta credencial sin tipo
    * def caseData = { credId: '', credValue: '0966581609', expectedStatus: 200, expectedTxStatus: 'ERR' }
    * def payload = buildPayload(caseData)
    * remove payload.QryAccByCred.Cred.Id
    Given path 'consulta_credencial'
    And request payload
    When method post
    Then eval verifyHttpStatus(caseData)
    * eval assertResponse(caseData, response)
    * match response.QryAccByCred.Rsn.RsnCd == '9000'
    * match response.QryAccByCred.Rsn.AddtlInf contains 'Id) es requerido'

  @negative @qr_formato_invalido
  Scenario: Validacion error consulta credencial QR con formato invalido
    * def caseData = { credId: 'CQR', credValue: 'QR#INVALID', expectedStatus: 200, expectedTxStatus: 'ERR' }
    * def payload = buildPayload(caseData)
    Given path 'consulta_credencial'
    And request payload
    When method post
    Then eval verifyHttpStatus(caseData)
    * eval assertResponse(caseData, response)
    * match response.QryAccByCred.Rsn.RsnCd == '0001'
    * match karate.lowerCase(response.QryAccByCred.Rsn.AddtlInf) contains 'correct format'

  @negative @credencial_sin_objeto
  Scenario: Validacion error consulta credencial sin objeto credencial
    * def caseData = { credId: null, credValue: null, expectedStatus: 200, expectedTxStatus: 'ERR' }
    * def payload = buildPayload(caseData)
    * remove payload.QryAccByCred.Cred
    Given path 'consulta_credencial'
    And request payload
    When method post
    Then eval verifyHttpStatus(caseData)
    * eval assertResponse(caseData, response)
    * match response.QryAccByCred.Rsn.RsnCd == '9000'
    * match karate.lowerCase(response.QryAccByCred.Rsn.AddtlInf) contains 'cliente es requerida'

  @negative @credencial_valor_largo
  Scenario: Validacion error consulta credencial con valor muy largo
    * def longValue = '9'.repeat(160)
    * def caseData = { credId: 'CEL', credValue: longValue, expectedStatus: 200, expectedTxStatus: 'ERR' }
    * def payload = buildPayload(caseData)
    Given path 'consulta_credencial'
    And request payload
    When method post
    Then eval verifyHttpStatus(caseData)
    * eval assertResponse(caseData, response)
    * match response.QryAccByCred.Rsn.RsnCd == '1001'
    * match karate.lowerCase(response.QryAccByCred.Rsn.AddtlInf) contains 'credenciales utilizadas'
