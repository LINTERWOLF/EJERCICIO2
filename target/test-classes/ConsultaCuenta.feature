@consultacuenta
Feature: Consulta de cuentas PANAPAY

  Background:
    * def tokenContext = callonce read('classpath:helpers/generate-token.feature')
    * def tokenData = tokenContext.tokenInfo
    * def baseUrl = affiliationBaseUrl
    * url baseUrl
    * def authHeaders = { 'Content-Type': 'application/json' }
    * set authHeaders.Authorization = 'Bearer ' + tokenData.auth_tokencb
    * configure headers = authHeaders
    * def LocalDateTime = Java.type('java.time.LocalDateTime')
    * def DateTimeFormatter = Java.type('java.time.format.DateTimeFormatter')
    * def timestampFormatter = DateTimeFormatter.ofPattern("yyyy-MM-dd'T'HH:mm:ss")
    * def makePayload =
    """
    function(acctId, acctTp) {
      var token = karate.get('tokenData');
      var LocalDateTime = Java.type('java.time.LocalDateTime');
      var DateTimeFormatter = Java.type('java.time.format.DateTimeFormatter');
      var timestampFormatter = DateTimeFormatter.ofPattern("yyyy-MM-dd'T'HH:mm:ss");
      var timestamp = LocalDateTime.now().format(timestampFormatter);
      var digits = function(length){
        var value = '';
        for (var i = 0; i < length; i++) {
          value += Math.floor(Math.random() * 10);
        }
        return value;
      };
      var payload = {
        GrpHdr: {
          msgId: token.coop_codecb + token.currentDate + digits(12),
          creDtTm: timestamp,
          NbOfTxs: 1,
          SttlmInf: { SttlmMtd: 'INGA' },
          InstgAgt: { finInstnId: '0205' },
          InstdAgt: { FinInstnId: '0000' },
          Mge: { Type: 'acmt.998.421.01' },
          ChnlId: 'APP'
        },
        QryUsrByAcc: {
          Acct: {
            AcctId: acctId,
            AcctTp: acctTp
          }
        }
      };
      return payload;
    }
    """
    * def assertOk =
    """
    function(body) {
      var qry = body.QryUsrByAcc || body.qryUsrByAcc;
      if (!qry) {
        karate.fail('Respuesta invalida para consulta de cuenta: ' + karate.pretty(body));
      }
      karate.match(qry.TxSts || qry.txSts, 'Ok');
      var rsn = qry.Rsn || qry.rsn;
      if (!rsn) {
        karate.fail('No se recibio nodo de razon para la consulta exitosa: ' + karate.pretty(qry));
      }
      karate.match(rsn.RsnCd || rsn.rsnCd, '0000');
    }
    """

  Scenario: Consulta Cuenta de un usuario afiliado con cuenta de Ahorros y cedula valida
    * def payload = makePayload('020501071109', '10')
    Given path 'consulta_cuenta'
    And request payload
    When method post
    Then status 200
    * eval assertOk(response)

  Scenario: Consulta Cuenta de un usuario afiliado con cuenta de Ahorros y RUC valida
    * def payload = makePayload('31976583360420297586', '10')
    Given path 'consulta_cuenta'
    And request payload
    When method post
    Then status 200
    * eval assertOk(response)

  Scenario: Consulta Cuenta de un usuario afiliado con cuenta de Ahorros y Pasaporte valida
    * def payload = makePayload('31255220011100679496', '10')
    Given path 'consulta_cuenta'
    And request payload
    When method post
    Then status 200
    * eval assertOk(response)

  Scenario: Consulta Cuenta de un usuario afiliado con cuenta Corriente y cedula valida
    * def payload = makePayload('32474249765354367505', '20')
    Given path 'consulta_cuenta'
    And request payload
    When method post
    Then status 200
    * eval assertOk(response)

  Scenario: Consulta Cuenta de un usuario desafiliado
    * def payload = makePayload('01049127100', '10')
    Given path 'consulta_cuenta'
    And request payload
    When method post
    Then status 200
    * eval assertOk(response)

  Scenario: Consulta Cuenta de un usuario Bloqueado
    * def payload = makePayload('21342526022902', '10')
    Given path 'consulta_cuenta'
    And request payload
    When method post
    Then status 200
    * eval assertOk(response)

  Scenario: Consulta Cuenta de un usuario NO afiliado
    * def payload = makePayload('39999999', '10')
    Given path 'consulta_cuenta'
    And request payload
    When method post
    Then status 200
    * eval assertOk(response)
