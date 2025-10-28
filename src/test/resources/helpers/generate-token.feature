Feature: Generar y almacenar token OAuth PANAPAY

  Background:
    * def projectDir = karate.properties['karate.project.dir'] ? karate.properties['karate.project.dir'] : java.lang.System.getProperty('user.dir')
    * def Paths = Java.type('java.nio.file.Paths')
    * def tokenDirectory = Paths.get(projectDir, 'target')
    * def tokenTextPath = tokenDirectory.resolve('token.txt').toString()
    * def tokenJsonPath = tokenDirectory.resolve('token-data.json').toString()
    * def tokenResponsePath = tokenDirectory.resolve('token-response.json').toString()

  Scenario: Solicitar token con client_credentials y preparar datos compartidos
    # Solicita el token con grant client_credentials utilizando las credenciales QA.
    * def clientId = '0205cb'
    * def clientSecret = 'iXaIz03uhylB2nG6jxTLz2QdHs37GbXn'
    Given url 'https://autenticacionqa.coonecta.com.ec/auth/realms/PANAPAY/protocol/openid-connect/token'
    And header Content-Type = 'application/x-www-form-urlencoded'
    And form field grant_type = 'client_credentials'
    And form field client_id = clientId
    And form field client_secret = clientSecret
    When method post
    Then status 200
    * def jsonResponse = response
    * def codecb = clientId.substring(0, 4)
    * def formattedDate = java.time.LocalDate.now().format(java.time.format.DateTimeFormatter.ofPattern('yyyyMMdd'))
    * match jsonResponse.access_token != null
    * def tokenInfo =
    """
    {
      currentDate: '#(formattedDate)',
      coop_codecb: '#(codecb)',
      auth_tokencb: '#(jsonResponse.access_token)'
    }
    """
    * set tokenInfo.responseStatus = responseStatus
    * set tokenInfo.rawResponse = jsonResponse
    * def Files = Java.type('java.nio.file.Files')
    * def StandardCharsets = Java.type('java.nio.charset.StandardCharsets')
    * def ObjectMapper = Java.type('com.fasterxml.jackson.databind.ObjectMapper')
    * def mapper = new ObjectMapper()
    * eval Files.createDirectories(tokenDirectory)
    * set tokenInfo.tokenPath = tokenTextPath
    * set tokenInfo.tokenJsonPath = tokenJsonPath
    * set tokenInfo.tokenResponsePath = tokenResponsePath
    * eval Files.write(Paths.get(tokenTextPath), tokenInfo.auth_tokencb.getBytes(StandardCharsets.UTF_8))
    * eval Files.write(Paths.get(tokenJsonPath), mapper.writeValueAsBytes(tokenInfo))
    * eval Files.write(Paths.get(tokenResponsePath), mapper.writeValueAsBytes({ status: responseStatus, response: jsonResponse }))
    * karate.log('Token almacenado en:', tokenTextPath)
    * karate.log('Detalle crudo almacenado en:', tokenResponsePath)
    * def result = tokenInfo

  Scenario: Validar estructura persistida del token
    * def savedToken = read('file:' + tokenJsonPath)
    * match savedToken.auth_tokencb != null
    * match savedToken.responseStatus == 200
    * def today = java.time.LocalDate.now().format(java.time.format.DateTimeFormatter.ofPattern('yyyyMMdd'))
    * match savedToken.currentDate == today
    * match savedToken.coop_codecb == '0205'
    * def responseEnvelope = read('file:' + tokenResponsePath)
    * match responseEnvelope.status == savedToken.responseStatus

  Scenario: Verificar consistencia de archivos auxiliares
    * def rawToken = karate.readAsString('file:' + tokenTextPath).trim()
    * assert rawToken.length() > 20
    * def savedToken = read('file:' + tokenJsonPath)
    * match savedToken.auth_tokencb == rawToken
    * match savedToken.tokenPath == tokenTextPath
    * def tokenInfo = savedToken
    * def result = tokenInfo
