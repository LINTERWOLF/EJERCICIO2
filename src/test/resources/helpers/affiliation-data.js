// Generador centralizado de datos para los escenarios de afiliación PANAPAY.
// Expone utilidades para crear identificadores, cuentas y payloads ISO compatibles
// con la API real, asegurando longitudes y formatos exigidos por negocio.
function() {
  var RandomData = {};

  // Crea una cadena numérica aleatoria de longitud fija.
  RandomData.randomDigits = function(length) {
    var digits = '';
    for (var i = 0; i < length; i++) {
      digits += Math.floor(Math.random() * 10);
    }
    return digits;
  };

  RandomData.randomAlpha = function(length) {
    var chars = '';
    var letters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    for (var i = 0; i < length; i++) {
      chars += letters.charAt(Math.floor(Math.random() * letters.length));
    }
    return chars;
  };

  RandomData.randomElement = function(list) {
    return list[Math.floor(Math.random() * list.length)];
  };

  // Fabrica un nombre completo aleatorio usando catálogos pequeños.
  RandomData.generateNames = function() {
    var firstNames = ['Ana', 'Luis', 'Carla', 'Diego', 'Lucia', 'Mateo', 'Fernanda', 'Marco', 'Valeria', 'Sebastian'];
    var lastNames = ['Perez', 'Garcia', 'Lopez', 'Torres', 'Castillo', 'Sanchez', 'Rojas', 'Flores', 'Guzman', 'Romero'];
    var first = RandomData.randomElement(firstNames);
    var last = RandomData.randomElement(lastNames);
    return {
      first: first,
      last: last,
      full: first + ' ' + last
    };
  };

  RandomData.generateDocument = function(docType) {
    if (docType === 'PAS') {
      return 'PA' + RandomData.randomAlpha(2) + RandomData.randomDigits(6);
    }
    if (docType === 'RUC') {
      return RandomData.randomDigits(13);
    }
    if (docType === 'CDI') {
      return RandomData.randomDigits(10);
    }
    return RandomData.randomDigits(10);
  };

  RandomData.isValidDocId = function(docId, docType) {
    docType = docType || 'CED';
    if (!docId) return false;
    if (docType === 'PAS') {
      return /^[A-Z]{4}\d{6}$/.test(docId);
    }
    if (docType === 'RUC') {
      return /^\d{13}$/.test(docId);
    }
    if (docType === 'CDI') {
      return /^\d{10}$/.test(docId);
    }
    return /^\d{10}$/.test(docId);
  };

  RandomData.generateMobile = function() {
    return '09' + RandomData.randomDigits(8);
  };

  RandomData.isValidMobile = function(mobile) {
    return /^09\d{8}$/.test(mobile || '');
  };

  RandomData.generateEmail = function(first, last) {
    var suffix = RandomData.randomDigits(2);
    var normalize = function(value) {
      return value.toLowerCase().replace(/[^a-z0-9]/g, '');
    };
    return normalize(first) + '.' + normalize(last) + suffix + '@qa-affiliations.com';
  };

  RandomData.generateAccountId = function(accountType) {
    accountType = accountType || 'CTA_AHORROS';
    var prefix = accountType === 'CTA_CORRIENTE' ? '32' : '31';
    return prefix + RandomData.randomDigits(18);
  };

  RandomData.isValidAccount = function(accountType, acctId) {
    return !!acctId && acctId.length === 20 && /^\d+$/.test(acctId);
  };

  RandomData.accountTypeCode = function(accountType) {
    var map = {
      CTA_AHORROS: '10',
      CTA_CORRIENTE: '20'
    };
    return map[accountType] || '10';
  };

  RandomData.generateMessageId = function(options) {
    options = options || {};
    var LocalDateTime = Java.type('java.time.LocalDateTime');
    var DateTimeFormatter = Java.type('java.time.format.DateTimeFormatter');
    var now = options.timestamp || LocalDateTime.now().format(DateTimeFormatter.ofPattern("yyyy-MM-dd'T'HH:mm:ss"));
    var prefix = options.prefix || '0205';
    var sanitized = now.replace(/[^0-9]/g, '');
    var randomSuffix = RandomData.randomDigits(6);
    return prefix + sanitized + randomSuffix;
  };

  RandomData.generateAffiliationPayload = function(overrides) {
    overrides = overrides || {};
    var LocalDateTime = Java.type('java.time.LocalDateTime');
    var DateTimeFormatter = Java.type('java.time.format.DateTimeFormatter');
    var timestamp = overrides.transactionDate || LocalDateTime.now().format(DateTimeFormatter.ofPattern("yyyy-MM-dd'T'HH:mm:ss"));
    var nameData = RandomData.generateNames();
    var docType = overrides.docType || 'CDI';
    var docId = overrides.docId || RandomData.generateDocument(docType);
    var accountType = overrides.accountType || 'CTA_AHORROS';
    var accountId = overrides.acctId || RandomData.generateAccountId(accountType);
    var mobile = overrides.mobile || RandomData.generateMobile();
    var email = overrides.email || RandomData.generateEmail(nameData.first, nameData.last);
    var coopCode = overrides.coopCode || '0205';
    var instgAgtFinInstnId = overrides.instgAgtFinInstnId || overrides.coopCodecb || coopCode;
    var msgId = overrides.msgId || RandomData.generateMessageId({ prefix: coopCode, timestamp: timestamp });
    var accountTypeCode = overrides.accountTypeCode || RandomData.accountTypeCode(accountType);

    var payload = {
      grpHdr: {
        msgId: msgId,
        creDtTm: timestamp,
        nbOfTxs: overrides.nbOfTxs != null ? overrides.nbOfTxs : 1,
        sttlmInf: { sttlmMtd: overrides.settlementMethod || 'INGA' },
        instgAgt: { finInstnId: instgAgtFinInstnId },
        instdAgt: { finInstnId: overrides.instdAgtFinInstnId || '0000' },
        mge: { type: overrides.messageType || 'acmt.998.211.01' },
        chnlId: overrides.channelId || 'APP'
      },
      acctEnroll: {
        acct: {
          nm: overrides.name || nameData.full,
          docTp: docType,
          docId: docId,
          acctTp: accountTypeCode,
          acctId: accountId
        },
        othr: {
          cred: overrides.contacts || [
            { id: 'CEL', value: mobile },
            { id: 'EMA', value: email }
          ]
        },
        operationType: overrides.operationType || 'AFIL'
      }
    };

    if (overrides.acctStatus) {
      payload.acctEnroll.acct.status = overrides.acctStatus;
    }
    if (overrides.notes) {
      payload.acctEnroll.notes = overrides.notes;
    }
    if (overrides.secondaryAccounts) {
      payload.acctEnroll.secondaryAccounts = overrides.secondaryAccounts;
    }
    if (overrides.orderingEntity) {
      payload.acctEnroll.orderingEntity = overrides.orderingEntity;
    }
    if (overrides.beneficiaryEntity) {
      payload.acctEnroll.beneficiaryEntity = overrides.beneficiaryEntity;
    }

    return payload;
  };

  // Replica profunda de cualquier objeto generado para manipularlo sin mutar el original.
  RandomData.clone = function(obj) {
    return JSON.parse(JSON.stringify(obj));
  };

  // Convierte el arreglo de credenciales en un mapa id->valor para validaciones puntuales.
  RandomData.normalizeContacts = function(credList) {
    var map = {};
    if (!credList) return map;
    credList.forEach(function(c) {
      map[c.id] = c.value;
    });
    return map;
  };

  return RandomData;
}
