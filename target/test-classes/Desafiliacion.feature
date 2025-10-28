@desafiliacion
Feature: Desafiliacion de cuentas PANAPAY

  Background:
    # Obtiene el token solo una vez para toda la suite y arma cabeceras comunes.
    * def tokenContext = callonce read('classpath:helpers/generate-token.feature')
    * def tokenData = tokenContext.tokenInfo
    * def baseUrl = affiliationBaseUrl
    * url baseUrl
    * def authHeaders = { 'Content-Type': 'application/json' }
    * set authHeaders.Authorization = 'Bearer ' + tokenData.auth_tokencb
    * configure headers = authHeaders
    * def generators = call read('classpath:helpers/affiliation-data.js')
    * def LocalDateTime = Java.type('java.time.LocalDateTime')
    * def DateTimeFormatter = Java.type('java.time.format.DateTimeFormatter')
    * def timestampFormatter = DateTimeFormatter.ofPattern("yyyy-MM-dd'T'HH:mm:ss")
    * def desafiliacionData = read('classpath:helpers/desafiliacion-data.json')
    # Construye el payload ISO 20022 reutilizando datos parametrizados del dataset.
    * def buildPayload =
    """
    function(caseData, actionOverride) {
      var timestamp = LocalDateTime.now().format(timestampFormatter);
      var msgId = tokenData.coop_codecb + tokenData.currentDate + generators.randomDigits(11);
      var action = actionOverride ? actionOverride : caseData.action;
      return {
        GrpHdr: {
          msgId: msgId,
          creDtTm: timestamp,
          NbOfTxs: "1",
          SttlmInf: { SttlmMtd: "INGA" },
          InstgAgt: { finInstnId: tokenData.coop_codecb },
          InstdAgt: { FinInstnId: "0000" },
          Mge: { Type: "acmt.998.311.01" },
          ChnlId: "APP"
        },
        BlkUser: {
          Acct: {
            AcctId: caseData.accountId,
            acctTp: String(caseData.accountType)
          },
          CtrlInf: {
            ActnTp: action
          }
        }
      };
    }
    """
    # Valida elementos clave de la respuesta sin perder visibilidad del cuerpo completo.
    * def assertResponse =
    """
    function(caseData, body) {
      if (!body || !body.AcctEnroll) {
        karate.log('Response without AcctEnroll section', body);
        return;
      }
      var txStatus = (body.AcctEnroll.TxSts || '').toUpperCase();
      var reasonCode = body.AcctEnroll.Rsn ? String(body.AcctEnroll.Rsn.RsnCd) : null;
      if (caseData.expectedTxStatus) {
        karate.match(txStatus, caseData.expectedTxStatus.toUpperCase());
      }
      if (caseData.expectedReasonCode) {
        karate.match(reasonCode, caseData.expectedReasonCode);
      }
    }
    """
    # Traduce el codigo numerico de cuenta al enumerado que espera el generador de payload.
    * def resolveAccountType =
    """
    function(code) {
      return code === '20' ? 'CTA_CORRIENTE' : 'CTA_AHORROS';
    }
    """
    # Ejecuta una afiliacion previa cuando el escenario lo requiere (p. ej., bloqueos).
    * def performAffiliation =
    """
    function(caseData) {
      if (!caseData.preAffiliation) {
        return;
      }
      var accountTypeName = resolveAccountType(String(caseData.accountType));
      var payload = generators.generateAffiliationPayload({
        instgAgtFinInstnId: tokenData.coop_codecb,
        docType: caseData.docType,
        docId: caseData.docId,
        accountType: accountTypeName,
        accountTypeCode: caseData.accountType,
        acctId: caseData.accountId
      });
      var expectedConfig = caseData.preAffiliationExpectedStatus;
      var expected = expectedConfig != null ? expectedConfig : 200;
      var callResult = karate.call('classpath:helpers/perform-affiliation.feature', {
        baseUrl: baseUrl,
        headers: authHeaders,
        payload: payload,
        expectedStatus: expected
      });
      var actualStatus = callResult && callResult.result ? callResult.result.status : null;
      if (expectedConfig === 'ANY') {
        return callResult;
      }
      if (expected != null && actualStatus != null) {
        karate.match(actualStatus, expected);
      }
      return callResult;
    }
    """
    # Aplica acciones adicionales antes del escenario (bloqueo previo para luego desbloquear).
    * def performPreActions =
    """
    function(caseData) {
      if (!caseData.preActions) {
        return;
      }
      caseData.preActions.forEach(function(preAction) {
        var payload = buildPayload(caseData, preAction.action);
        var expectedConfig = preAction.expectedStatus;
        var expected = expectedConfig != null ? expectedConfig : 200;
        var callResult = karate.call('classpath:helpers/perform-desafiliacion.feature', {
          baseUrl: baseUrl,
          headers: authHeaders,
          payload: payload,
          expectedStatus: expected
        });
        var actualStatus = callResult && callResult.result ? callResult.result.status : null;
        if (expectedConfig === 'ANY') {
          return;
        }
        if (expected != null && actualStatus != null) {
          karate.match(actualStatus, expected);
        }
      });
    }
    """

  Scenario: Desafiliacion cedula y cuenta de ahorros
    * def caseData = desafiliacionData.cedula_ahorro_desafiliacion
    * eval performAffiliation(caseData)
    * eval performPreActions(caseData)
    * def payload = buildPayload(caseData)
    * def expectedStatus = caseData.expectedStatus
    # Se fuerza a que las suites fallen si el servicio no devuelve 200.
    * match expectedStatus == 200
    Given path 'desafiliacion'
    And request payload
    When method post
    Then match responseStatus == expectedStatus
    * eval assertResponse(caseData, response)

  Scenario: Desafiliacion cedula y cuenta de ahorros no asociada
    * def caseData = desafiliacionData.cedula_ahorro_no_asociada
    * eval performAffiliation(caseData)
    * eval performPreActions(caseData)
    * def payload = buildPayload(caseData)
    * def expectedStatus = caseData.expectedStatus
    * match expectedStatus == 200
    Given path 'desafiliacion'
    And request payload
    When method post
    Then match responseStatus == expectedStatus
    * eval assertResponse(caseData, response)

  Scenario: Desafiliacion cedula y cuenta de ahorros no valida
    * def caseData = desafiliacionData.cedula_ahorro_no_valida
    * eval performAffiliation(caseData)
    * eval performPreActions(caseData)
    * def payload = buildPayload(caseData)
    * def expectedStatus = caseData.expectedStatus
    * match expectedStatus == 200
    Given path 'desafiliacion'
    And request payload
    When method post
    Then match responseStatus == expectedStatus
    * eval assertResponse(caseData, response)

  Scenario: Bloqueo cedula y cuenta de ahorros
    * def caseData = desafiliacionData.cedula_ahorro_bloqueo
    * eval performAffiliation(caseData)
    * eval performPreActions(caseData)
    * def payload = buildPayload(caseData)
    * def expectedStatus = caseData.expectedStatus
    * match expectedStatus == 200
    Given path 'desafiliacion'
    And request payload
    When method post
    Then match responseStatus == expectedStatus
    * eval assertResponse(caseData, response)

  Scenario: Desbloqueo cedula y cuenta de ahorros
    * def caseData = desafiliacionData.cedula_ahorro_desbloqueo
    * eval performAffiliation(caseData)
    * eval performPreActions(caseData)
    * def payload = buildPayload(caseData)
    * def expectedStatus = caseData.expectedStatus
    * match expectedStatus == 200
    Given path 'desafiliacion'
    And request payload
    When method post
    Then match responseStatus == expectedStatus
    * eval assertResponse(caseData, response)

  Scenario: Desafiliacion pasaporte y cuenta de ahorros
    * def caseData = desafiliacionData.pasaporte_ahorro_desafiliacion
    * eval performAffiliation(caseData)
    * eval performPreActions(caseData)
    * def payload = buildPayload(caseData)
    * def expectedStatus = caseData.expectedStatus
    * match expectedStatus == 200
    Given path 'desafiliacion'
    And request payload
    When method post
    Then match responseStatus == expectedStatus
    * eval assertResponse(caseData, response)

  Scenario: Bloqueo pasaporte y cuenta de ahorros
    * def caseData = desafiliacionData.pasaporte_ahorro_bloqueo
    * eval performAffiliation(caseData)
    * eval performPreActions(caseData)
    * def payload = buildPayload(caseData)
    * def expectedStatus = caseData.expectedStatus
    * match expectedStatus == 200
    Given path 'desafiliacion'
    And request payload
    When method post
    Then match responseStatus == expectedStatus
    * eval assertResponse(caseData, response)

  Scenario: Desbloqueo pasaporte y cuenta de ahorros
    * def caseData = desafiliacionData.pasaporte_ahorro_desbloqueo
    * eval performAffiliation(caseData)
    * eval performPreActions(caseData)
    * def payload = buildPayload(caseData)
    * def expectedStatus = caseData.expectedStatus
    * match expectedStatus == 200
    Given path 'desafiliacion'
    And request payload
    When method post
    Then match responseStatus == expectedStatus
    * eval assertResponse(caseData, response)

  Scenario: Desafiliacion RUC y cuenta de ahorros
    * def caseData = desafiliacionData.ruc_ahorro_desafiliacion
    * eval performAffiliation(caseData)
    * eval performPreActions(caseData)
    * def payload = buildPayload(caseData)
    * def expectedStatus = caseData.expectedStatus
    * match expectedStatus == 200
    Given path 'desafiliacion'
    And request payload
    When method post
    Then match responseStatus == expectedStatus
    * eval assertResponse(caseData, response)

  Scenario: Bloqueo RUC y cuenta de ahorros
    * def caseData = desafiliacionData.ruc_ahorro_bloqueo
    * eval performAffiliation(caseData)
    * eval performPreActions(caseData)
    * def payload = buildPayload(caseData)
    * def expectedStatus = caseData.expectedStatus
    * match expectedStatus == 200
    Given path 'desafiliacion'
    And request payload
    When method post
    Then match responseStatus == expectedStatus
    * eval assertResponse(caseData, response)

  Scenario: Desbloqueo RUC y cuenta de ahorros
    * def caseData = desafiliacionData.ruc_ahorro_desbloqueo
    * eval performAffiliation(caseData)
    * eval performPreActions(caseData)
    * def payload = buildPayload(caseData)
    * def expectedStatus = caseData.expectedStatus
    * match expectedStatus == 200
    Given path 'desafiliacion'
    And request payload
    When method post
    Then match responseStatus == expectedStatus
    * eval assertResponse(caseData, response)

  Scenario: Desafiliacion cedula y cuenta corriente
    * def caseData = desafiliacionData.cedula_corriente_desafiliacion
    * eval performAffiliation(caseData)
    * eval performPreActions(caseData)
    * def payload = buildPayload(caseData)
    * def expectedStatus = caseData.expectedStatus
    * match expectedStatus == 200
    Given path 'desafiliacion'
    And request payload
    When method post
    Then match responseStatus == expectedStatus
    * eval assertResponse(caseData, response)

  Scenario: Desafiliacion pasaporte y cuenta corriente
    * def caseData = desafiliacionData.pasaporte_corriente_desafiliacion
    * eval performAffiliation(caseData)
    * eval performPreActions(caseData)
    * def payload = buildPayload(caseData)
    * def expectedStatus = caseData.expectedStatus
    * match expectedStatus == 200
    Given path 'desafiliacion'
    And request payload
    When method post
    Then match responseStatus == expectedStatus
    * eval assertResponse(caseData, response)

  Scenario: Desafiliacion RUC y cuenta corriente
    * def caseData = desafiliacionData.ruc_corriente_desafiliacion
    * eval performAffiliation(caseData)
    * eval performPreActions(caseData)
    * def payload = buildPayload(caseData)
    * def expectedStatus = caseData.expectedStatus
    * match expectedStatus == 200
    Given path 'desafiliacion'
    And request payload
    When method post
    Then match responseStatus == expectedStatus
    * eval assertResponse(caseData, response)
