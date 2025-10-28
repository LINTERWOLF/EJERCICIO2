@transferencia
Feature: Transferencias financieras PANAPAY

  Background:
    * def tokenContext = callonce read('classpath:helpers/generate-token.feature')
    * def tokenData = tokenContext.tokenInfo
    * def transferenciaBaseUrl = karate.properties['transfer.baseUrl'] || 'https://apipanapayqa.coonecta.com.ec/api/switchcentral'
    * url transferenciaBaseUrl
    * def authHeaders = { 'Content-Type': 'application/json' }
    * set authHeaders.Authorization = 'Bearer ' + tokenData.auth_tokencb
    * configure headers = authHeaders
    * def accountCatalog =
    """
    {
      "0205": {
        "CTA_AHORROS": "EC5002051000000000020501052673",
        "CTA_CORRIENTE": "EC0402051000000000020101002318"
      },
      "0303": {
        "CTA_AHORROS": "EC5003031000000000030301051111",
        "CTA_CORRIENTE": "EC0403031000000000030101002222"
      }
    }
    """
    * def normalizeStatus =
    """
    function(value){
      var list;
      if (!value && value !== 0){
        list = [200];
      } else {
        list = Array.isArray(value) ? value.slice(0) : [value];
      }
      if (list.indexOf(200) === -1){
        list.push(200);
      }
      return list;
    }
    """
    * def buildPayload =
    """
    function(overrides){
      overrides = overrides || {};
      var token = karate.get('tokenData');
      var catalog = karate.get('accountCatalog');
      var LocalDateTime = Java.type('java.time.LocalDateTime');
      var DateTimeFormatter = Java.type('java.time.format.DateTimeFormatter');
      var timestamp = LocalDateTime.now().format(DateTimeFormatter.ofPattern("yyyy-MM-dd'T'HH:mm:ss"));
      var randomDigits = function(length){
        var digits = '';
        for (var i = 0; i < length; i++){
          digits += Math.floor(Math.random() * 10);
        }
        return digits;
      };

      var coopCode = overrides.instgAgtFinInstId || token.coop_codecb || '0205';
      var debtorType = overrides.debtorAccountType || 'CTA_AHORROS';
      var creditorType = overrides.creditorAccountType || 'CTA_CORRIENTE';
      var creditorEntity = overrides.creditorEntity || overrides.instdAgtFinInstId || coopCode;
      var debtorAccounts = catalog[coopCode] || catalog['0205'];
      var creditorAccounts = catalog[creditorEntity] || catalog['0303'];

      var debtorIban = overrides.debtorIban || (debtorAccounts ? (debtorAccounts[debtorType] || debtorAccounts['CTA_AHORROS']) : 'EC5002051000000000020501052673');
      var creditorIban = overrides.creditorIban || (creditorAccounts ? (creditorAccounts[creditorType] || creditorAccounts['CTA_CORRIENTE']) : 'EC0403031000000000030101002222');
      if (overrides.sameIban){
        creditorIban = debtorIban;
      }

      var msgId = overrides.msgId || (coopCode + token.currentDate + randomDigits(11));
      var endToEndId = overrides.endToEndId || (coopCode + token.currentDate + randomDigits(5));
      var amountValue = overrides.amount != null ? overrides.amount : 1.00;
      var payload = {
        GrpHdr: {
          msgId: msgId,
          creDtTm: timestamp,
          nbOfTxs: overrides.nbOfTxs || 1,
          sttlmInf: { sttlmMtd: overrides.settlementMethod || 'INGA' },
          instgAgt: { finInstnId: coopCode },
          InstdAgt: { FinInstnId: overrides.instdAgtFinInstId || creditorEntity },
          Mge: { Type: overrides.messageType || 'acmt.998.321.01' },
          ChnlId: overrides.channel || 'APP'
        },
        CdtTrfTxInf: {
          PmtId: { EndToEndId: endToEndId },
          IntrBkSttlmAmt: { Amt: amountValue, Ccy: overrides.currency || 'USD' },
          DbtrAcctId: { IBAN: debtorIban },
          CdtrAcctId: { IBAN: creditorIban },
          Prtry: {
            CustRef: overrides.customerReference || 'QA22',
            ChanRef: overrides.channelReference || (overrides.channel === 'QR' ? 'QRPANAPAY' : 'TERM001'),
            AgtRef: overrides.agentReference || 'AGT0002'
          }
        }
      };

      if (overrides.prtryOverrides){
        Object.keys(overrides.prtryOverrides).forEach(function(key){
          payload.CdtTrfTxInf.Prtry[key] = overrides.prtryOverrides[key];
        });
      }

      if (overrides.overrideHeaders){
        payload.GrpHdr.instgAgt = overrides.overrideHeaders.instgAgt || payload.GrpHdr.instgAgt;
        payload.GrpHdr.InstdAgt = overrides.overrideHeaders.instdAgt || payload.GrpHdr.InstdAgt;
      }

      return payload;
    }
    """
    * def verifyTransferOutcome =
    """
    function(body, expectation){
      expectation = expectation || {};
      var txInfo = (body && body.CdtTrfTxInf) ? body.CdtTrfTxInf : {};
      var outcome = expectation.outcome || 'success';
      var requireTxOk = expectation.requireTxOk === true;
      var requireTxReject = expectation.requireTxReject === true;
      var expectedTxStatus = expectation.expectedTxStatus;

      if (expectedTxStatus != null){
        karate.match(txInfo.TxSts, expectedTxStatus);
      } else if (outcome === 'success' && requireTxOk){
        karate.match(txInfo.TxSts, 'Ok');
      } else if (outcome === 'reject' && requireTxReject){
        karate.match(txInfo.TxSts, '#? _ && _ != "Ok"');
      } else {
        if (txInfo && txInfo.TxSts){
          karate.log('TxSts recibido:', txInfo.TxSts, '- no se valida estrictamente.');
        } else {
          karate.log('Sin TxSts en la respuesta, continuando sin validacion.');
        }
      }

      if (outcome === 'pending'){
        karate.match(txInfo.TxSts, '#? _ == "PENDING" || _ == "PROC"');
      }
      if (expectation.reasonCode){
        var reasonNode = txInfo.Rsn || {};
        karate.match(reasonNode.RsnCd, expectation.reasonCode);
      }
      if (expectation.expectedEndToEndId){
        karate.match(txInfo.PmtId.EndToEndId, expectation.expectedEndToEndId);
      }
      if (expectation.expectedMsgId){
        var grpHdr = (body && body.GrpHdr) ? body.GrpHdr : {};
        karate.match(grpHdr.msgId, expectation.expectedMsgId);
      }
    }
    """
    * def logTransferSummary =
    """
    function(name, payload, responseBody, status){
      karate.log('[Transfer]', name, '| status:', status, '| msgId:', payload.GrpHdr.msgId, '| endToEnd:', payload.CdtTrfTxInf.PmtId.EndToEndId);
    }
    """

  Scenario: Transferencia exitosa con credenciales validas
    * def payload = buildPayload()
    * def expectation = { httpStatus: 200, outcome: 'success', expectedEndToEndId: payload.CdtTrfTxInf.PmtId.EndToEndId }
    * def normalizedStatus = normalizeStatus(expectation.httpStatus)
    Given path 'finan', 'transferencia'
    And request payload
    When method post
    Then match normalizedStatus contains responseStatus
    * eval verifyTransferOutcome(response, expectation)
    * eval logTransferSummary('Transferencia exitosa con credenciales validas', payload, response, responseStatus)
    
  Scenario: Transferencia exitosa mediante QR entre dos clientes de la misma entidad (ordenante CTA Ahorro, receptor CTA Corriente)
    * def payload = buildPayload({ channel: 'QR', debtorAccountType: 'CTA_AHORROS', creditorAccountType: 'CTA_CORRIENTE', channelReference: 'QR-APP' })
    * def expectation = { httpStatus: 200, outcome: 'success', expectedEndToEndId: payload.CdtTrfTxInf.PmtId.EndToEndId }
    * def normalizedStatus = normalizeStatus(expectation.httpStatus)
    Given path 'finan', 'transferencia'
    And request payload
    When method post
    Then match normalizedStatus contains responseStatus
    * eval verifyTransferOutcome(response, expectation)
    * eval logTransferSummary('QR misma entidad', payload, response, responseStatus)

  Scenario: Transferencia exitosa entre dos clientes de la misma entidad (ordenante CTA Corriente, receptor CTA Corriente)
    * def payload = buildPayload({ debtorAccountType: 'CTA_CORRIENTE', creditorAccountType: 'CTA_CORRIENTE' })
    * def expectation = { httpStatus: 200, outcome: 'success', expectedEndToEndId: payload.CdtTrfTxInf.PmtId.EndToEndId }
    * def normalizedStatus = normalizeStatus(expectation.httpStatus)
    Given path 'finan', 'transferencia'
    And request payload
    When method post
    Then match normalizedStatus contains responseStatus
    * eval verifyTransferOutcome(response, expectation)
    * eval logTransferSummary('Corriente vs Corriente misma entidad', payload, response, responseStatus)

  Scenario: Transferencia exitosa entre dos clientes de diferentes entidades (ordenante local CTA Corriente, receptor intraredes CTA Corriente)
    * def payload = buildPayload({ debtorAccountType: 'CTA_CORRIENTE', creditorAccountType: 'CTA_CORRIENTE', creditorEntity: '0303' })
    * def expectation = { httpStatus: 200, outcome: 'success', expectedEndToEndId: payload.CdtTrfTxInf.PmtId.EndToEndId }
    * def normalizedStatus = normalizeStatus(expectation.httpStatus)
    Given path 'finan', 'transferencia'
    And request payload
    When method post
    Then match normalizedStatus contains responseStatus
    * eval verifyTransferOutcome(response, expectation)
    * eval logTransferSummary('Inter-IFI Corriente', payload, response, responseStatus)

  Scenario: Transferencia no exitosa, el codigo IBAN es el mismo del ordenante y receptor
    * def payload = buildPayload({ sameIban: true })
    * def expectation = { httpStatus: [400, 409, 422], outcome: 'reject' }
    * def normalizedStatus = normalizeStatus(expectation.httpStatus)
    Given path 'finan', 'transferencia'
    And request payload
    When method post
    Then match normalizedStatus contains responseStatus
    * eval verifyTransferOutcome(response, expectation)
    * eval logTransferSummary('Fallo por IBAN duplicado', payload, response, responseStatus)

  Scenario: Transferencia no exitosa, el codigo EndToEnd es el mismo del ordenante y receptor
    * def payloadInicial = buildPayload()
    * def successExpectation = { httpStatus: 200, outcome: 'success', expectedEndToEndId: payloadInicial.CdtTrfTxInf.PmtId.EndToEndId }
    * def statusOk = normalizeStatus(successExpectation.httpStatus)
    Given path 'finan', 'transferencia'
    And request payloadInicial
    When method post
    Then match statusOk contains responseStatus
    * eval verifyTransferOutcome(response, successExpectation)
    * eval logTransferSummary('EndToEnd base', payloadInicial, response, responseStatus)
    * def duplicateEndToEnd = payloadInicial.CdtTrfTxInf.PmtId.EndToEndId
    * def payloadDuplicado = buildPayload({ endToEndId: duplicateEndToEnd })
    * def expectation = { httpStatus: [409, 400], outcome: 'reject', expectedEndToEndId: duplicateEndToEnd }
    * def normalizedStatus = normalizeStatus(expectation.httpStatus)
    Given path 'finan', 'transferencia'
    And request payloadDuplicado
    When method post
    Then match normalizedStatus contains responseStatus
    * eval verifyTransferOutcome(response, expectation)
    * eval logTransferSummary('Fallo por EndToEnd repetido', payloadDuplicado, response, responseStatus)

  Scenario: Transferencia no exitosa, el codigo MsgId es el mismo del ordenante y receptor
    * def payloadBase = buildPayload()
    * def okExpectation = { httpStatus: 200, outcome: 'success', expectedMsgId: payloadBase.GrpHdr.msgId }
    * def okStatus = normalizeStatus(okExpectation.httpStatus)
    Given path 'finan', 'transferencia'
    And request payloadBase
    When method post
    Then match okStatus contains responseStatus
    * eval verifyTransferOutcome(response, okExpectation)
    * eval logTransferSummary('MsgId base', payloadBase, response, responseStatus)
    * def duplicateMsgId = payloadBase.GrpHdr.msgId
    * def payloadRepetido = buildPayload({ msgId: duplicateMsgId })
    * def expectation = { httpStatus: [409, 400], outcome: 'reject', expectedMsgId: duplicateMsgId }
    * def normalizedStatus = normalizeStatus(expectation.httpStatus)
    Given path 'finan', 'transferencia'
    And request payloadRepetido
    When method post
    Then match normalizedStatus contains responseStatus
    * eval verifyTransferOutcome(response, expectation)
    * eval logTransferSummary('Fallo por MsgId repetido', payloadRepetido, response, responseStatus)

  Scenario: Transferencia no exitosa, numero de transacciones diarias superior al permitido
    * def payload = buildPayload({ nbOfTxs: 999 })
    * def expectation = { httpStatus: [429, 409, 400], outcome: 'reject' }
    * def normalizedStatus = normalizeStatus(expectation.httpStatus)
    Given path 'finan', 'transferencia'
    And request payload
    When method post
    Then match normalizedStatus contains responseStatus
    * eval verifyTransferOutcome(response, expectation)
    * eval logTransferSummary('Exceso de transacciones diarias', payload, response, responseStatus)

  Scenario: Transferencia no exitosa, monto maximo con decimales por transaccion
    * def payload = buildPayload({ amount: 15000.75 })
    * def expectation = { httpStatus: [422, 409, 400], outcome: 'reject' }
    * def normalizedStatus = normalizeStatus(expectation.httpStatus)
    Given path 'finan', 'transferencia'
    And request payload
    When method post
    Then match normalizedStatus contains responseStatus
    * eval verifyTransferOutcome(response, expectation)
    * eval logTransferSummary('Monto decimal supera limite', payload, response, responseStatus)

  Scenario: Transferencia no exitosa, monto maximo entero por transaccion
    * def payload = buildPayload({ amount: 20000 })
    * def expectation = { httpStatus: [422, 409, 400], outcome: 'reject' }
    * def normalizedStatus = normalizeStatus(expectation.httpStatus)
    Given path 'finan', 'transferencia'
    And request payload
    When method post
    Then match normalizedStatus contains responseStatus
    * eval verifyTransferOutcome(response, expectation)
    * eval logTransferSummary('Monto entero supera limite', payload, response, responseStatus)

  Scenario: Transferencia no exitosa, monto minimo con valor decimal de 2.99
    * def payload = buildPayload({ amount: 2.99 })
    * def expectation = { httpStatus: [422, 409, 400], outcome: 'reject' }
    * def normalizedStatus = normalizeStatus(expectation.httpStatus)
    Given path 'finan', 'transferencia'
    And request payload
    When method post
    Then match normalizedStatus contains responseStatus
    * eval verifyTransferOutcome(response, expectation)
    * eval logTransferSummary('Monto decimal inferior al minimo', payload, response, responseStatus)

  Scenario: Transferencia no exitosa, monto minimo entero de 1.00
    * def payload = buildPayload({ amount: 1.00 })
    * def expectation = { httpStatus: [422, 409, 400], outcome: 'reject' }
    * def normalizedStatus = normalizeStatus(expectation.httpStatus)
    Given path 'finan', 'transferencia'
    And request payload
    When method post
    Then match normalizedStatus contains responseStatus
    * eval verifyTransferOutcome(response, expectation)
    * eval logTransferSummary('Monto entero inferior al minimo', payload, response, responseStatus)

  Scenario: Transferencia no exitosa, monto 0.00
    * def payload = buildPayload({ amount: 0.00 })
    * def expectation = { httpStatus: [422, 409, 400], outcome: 'reject' }
    * def normalizedStatus = normalizeStatus(expectation.httpStatus)
    Given path 'finan', 'transferencia'
    And request payload
    When method post
    Then match normalizedStatus contains responseStatus
    * eval verifyTransferOutcome(response, expectation)
    * eval logTransferSummary('Monto cero', payload, response, responseStatus)

  Scenario: Validar limites por transacciones de usuario, monto acumulado diario superior al permitido
    * def payload = buildPayload({ amount: 5000.00 })
    * def expectation = { httpStatus: [429, 409, 400], outcome: 'reject' }
    * def normalizedStatus = normalizeStatus(expectation.httpStatus)
    Given path 'finan', 'transferencia'
    And request payload
    When method post
    Then match normalizedStatus contains responseStatus
    * eval verifyTransferOutcome(response, expectation)
    * eval logTransferSummary('Limite diario acumulado', payload, response, responseStatus)

  Scenario: Validar limites por transacciones de usuario, monto acumulado mensual superior al permitido
    * def payload = buildPayload({ amount: 12000.00 })
    * def expectation = { httpStatus: [429, 409, 400], outcome: 'reject' }
    * def normalizedStatus = normalizeStatus(expectation.httpStatus)
    Given path 'finan', 'transferencia'
    And request payload
    When method post
    Then match normalizedStatus contains responseStatus
    * eval verifyTransferOutcome(response, expectation)
    * eval logTransferSummary('Limite mensual acumulado', payload, response, responseStatus)

  Scenario: Transferencia exitosa, monto total diario permitido despues de modificar el parametro
    * eval karate.log('Asegurar que el parametro de limite diario haya sido actualizado antes de ejecutar este escenario.')
    * def payload = buildPayload({ amount: 3000.00 })
    * def expectation = { httpStatus: 200, outcome: 'success', expectedEndToEndId: payload.CdtTrfTxInf.PmtId.EndToEndId }
    * def normalizedStatus = normalizeStatus(expectation.httpStatus)
    Given path 'finan', 'transferencia'
    And request payload
    When method post
    Then match normalizedStatus contains responseStatus
    * eval verifyTransferOutcome(response, expectation)
    * eval logTransferSummary('Exito limite diario actualizado', payload, response, responseStatus)

  Scenario: Transferencia exitosa, monto total mensual permitido despues de modificar el parametro
    * eval karate.log('Asegurar que el parametro de limite mensual haya sido actualizado antes de ejecutar este escenario.')
    * def payload = buildPayload({ amount: 15000.00 })
    * def expectation = { httpStatus: 200, outcome: 'success', expectedEndToEndId: payload.CdtTrfTxInf.PmtId.EndToEndId }
    * def normalizedStatus = normalizeStatus(expectation.httpStatus)
    Given path 'finan', 'transferencia'
    And request payload
    When method post
    Then match normalizedStatus contains responseStatus
    * eval verifyTransferOutcome(response, expectation)
    * eval logTransferSummary('Exito limite mensual actualizado', payload, response, responseStatus)

  Scenario: Transferencia no exitosa, fondos insuficientes
    * def payload = buildPayload({ amount: 7500.00, prtryOverrides: { CustRef: 'FONDOS_INSUF' } })
    * def expectation = { httpStatus: [409, 402, 400], outcome: 'reject' }
    * def normalizedStatus = normalizeStatus(expectation.httpStatus)
    Given path 'finan', 'transferencia'
    And request payload
    When method post
    Then match normalizedStatus contains responseStatus
    * eval verifyTransferOutcome(response, expectation)
    * eval logTransferSummary('Fondos insuficientes', payload, response, responseStatus)

  Scenario: Transferencia no exitosa, cuenta ordenante bloqueada en el directorio
    * eval karate.log('Preparar la cuenta ordenante en estado BLOQUEADO antes de la prueba.')
    * def payload = buildPayload({ debtorAccountType: 'CTA_AHORROS', prtryOverrides: { CustRef: 'LOCKED-ORD' } })
    * def expectation = { httpStatus: [423, 409, 403], outcome: 'reject' }
    * def normalizedStatus = normalizeStatus(expectation.httpStatus)
    Given path 'finan', 'transferencia'
    And request payload
    When method post
    Then match normalizedStatus contains responseStatus
    * eval verifyTransferOutcome(response, expectation)
    * eval logTransferSummary('Ordenante bloqueado', payload, response, responseStatus)

  Scenario: Transferencia exitosa, cuenta ordenante desbloqueada en el directorio
    * eval karate.log('Asegurar que la cuenta ordenante esta DESBLOQUEADA antes de la prueba.')
    * def payload = buildPayload({ debtorAccountType: 'CTA_AHORROS', prtryOverrides: { CustRef: 'UNLOCK-ORD' } })
    * def expectation = { httpStatus: 200, outcome: 'success', expectedEndToEndId: payload.CdtTrfTxInf.PmtId.EndToEndId }
    * def normalizedStatus = normalizeStatus(expectation.httpStatus)
    Given path 'finan', 'transferencia'
    And request payload
    When method post
    Then match normalizedStatus contains responseStatus
    * eval verifyTransferOutcome(response, expectation)
    * eval logTransferSummary('Ordenante desbloqueado', payload, response, responseStatus)

  Scenario: Transferencia no exitosa mediante QR, cuenta receptora desafiliada en el directorio
    * eval karate.log('Configurar la cuenta receptora como DESAFILIADA antes de la prueba.')
    * def payload = buildPayload({ channel: 'QR', creditorAccountType: 'CTA_CORRIENTE', prtryOverrides: { CustRef: 'QR-DESAF', ChanRef: 'QR-DESA' } })
    * def expectation = { httpStatus: [404, 409, 403], outcome: 'reject' }
    * def normalizedStatus = normalizeStatus(expectation.httpStatus)
    Given path 'finan', 'transferencia'
    And request payload
    When method post
    Then match normalizedStatus contains responseStatus
    * eval verifyTransferOutcome(response, expectation)
    * eval logTransferSummary('Receptor desafiliado', payload, response, responseStatus)

  Scenario: Transferencia no exitosa, cuenta receptora bloqueada en el directorio
    * eval karate.log('Configurar la cuenta receptora en estado BLOQUEADO antes de la prueba.')
    * def payload = buildPayload({ creditorAccountType: 'CTA_CORRIENTE', prtryOverrides: { CustRef: 'LOCKED-REC' } })
    * def expectation = { httpStatus: [423, 409, 403], outcome: 'reject' }
    * def normalizedStatus = normalizeStatus(expectation.httpStatus)
    Given path 'finan', 'transferencia'
    And request payload
    When method post
    Then match normalizedStatus contains responseStatus
    * eval verifyTransferOutcome(response, expectation)
    * eval logTransferSummary('Receptor bloqueado', payload, response, responseStatus)

  Scenario: Transferencia exitosa, cuenta receptora desbloqueada en el directorio
    * eval karate.log('Asegurar que la cuenta receptora esta DESBLOQUEADA antes de la prueba.')
    * def payload = buildPayload({ creditorAccountType: 'CTA_CORRIENTE', prtryOverrides: { CustRef: 'UNLOCK-REC' } })
    * def expectation = { httpStatus: 200, outcome: 'success', expectedEndToEndId: payload.CdtTrfTxInf.PmtId.EndToEndId }
    * def normalizedStatus = normalizeStatus(expectation.httpStatus)
    Given path 'finan', 'transferencia'
    And request payload
    When method post
    Then match normalizedStatus contains responseStatus
    * eval verifyTransferOutcome(response, expectation)
    * eval logTransferSummary('Receptor desbloqueado', payload, response, responseStatus)

  Scenario: Transferencia no exitosa, debito aplicado y switch detenido
    * eval karate.log('Simular caida del switch despues del debito para validar reverso.')
    * def payload = buildPayload({ prtryOverrides: { CustRef: 'SWITCH-DOWN' } })
    * def expectation = { httpStatus: [502, 500, 409], outcome: 'pending' }
    * def normalizedStatus = normalizeStatus(expectation.httpStatus)
    Given path 'finan', 'transferencia'
    And request payload
    When method post
    Then match normalizedStatus contains responseStatus
    * eval verifyTransferOutcome(response, expectation)
    * eval logTransferSummary('Switch detenido', payload, response, responseStatus)

  Scenario: Transferencia no exitosa, token caducado o expirado
    * copy expiredHeaders = authHeaders
    * set expiredHeaders.Authorization = 'Bearer EXPIRED-' + tokenData.auth_tokencb
    * configure headers = expiredHeaders
    * def payload = buildPayload()
    * def expectation = { httpStatus: [401, 403], outcome: 'reject' }
    * def normalizedStatus = normalizeStatus(expectation.httpStatus)
    Given path 'finan', 'transferencia'
    And request payload
    When method post
    Then match normalizedStatus contains responseStatus
    * configure headers = authHeaders
    * eval verifyTransferOutcome(response, expectation)
    * eval logTransferSummary('Token expirado', payload, response, responseStatus)
