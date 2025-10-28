Feature: Generacion y verificacion de token PANAPAY

  Background:
    * def responseContext = callonce read('classpath:helpers/generate-token.feature')
    * def tokenData = responseContext.tokenInfo
    * def Files = Java.type('java.nio.file.Files')
    * def Paths = Java.type('java.nio.file.Paths')
    * def StandardCharsets = Java.type('java.nio.charset.StandardCharsets')
    * def projectDir = karate.properties['karate.project.dir'] ? karate.properties['karate.project.dir'] : java.lang.System.getProperty('user.dir')
    * def tokenPath = Paths.get(projectDir, 'target', 'token.txt')
    * def tokenJsonPath = Paths.get(projectDir, 'target', 'token-data.json')
    * def tokenResponsePath = Paths.get(projectDir, 'target', 'token-response.json')

  Scenario: Token obtenido correctamente y persistido en archivos auxiliares
    * match tokenData.auth_tokencb != null
    * def plainToken = karate.readAsString('file:' + tokenPath.toString())
    * def persisted = karate.read('file:' + tokenJsonPath.toString())
    * def persistedResponse = karate.read('file:' + tokenResponsePath.toString())
    * match plainToken.trim() == tokenData.auth_tokencb
    * match persisted.auth_tokencb == tokenData.auth_tokencb  
    * match persisted.currentDate == tokenData.currentDate  
    * match persisted.coop_codecb == tokenData.coop_codecb  
    * match persisted.responseStatus == tokenData.responseStatus 
    * match persistedResponse.status == tokenData.responseStatus 
    And print { currentDate: tokenData.currentDate, coop_codecb: tokenData.coop_codecb, tokenLength: tokenData.auth_tokencb.length }
    And print { statusCode: tokenData.responseStatus, responseBody: tokenData.rawResponse }

  @token_negative @invalid_client_id
  Scenario: Error al solicitar token con client_id incorrecto
    Given url 'https://autenticacionqa.coonecta.com.ec/auth/realms/PANAPAY/protocol/openid-connect/token'
    And header Content-Type = 'application/x-www-form-urlencoded'
    And form field grant_type = 'client_credentials'
    And form field client_id = '9999cb'
    And form field client_secret = 'iXaIz03uhylB2nG6jxTLz2QdHs37GbXn'
    When method post 
    Then status 200 
    And match response.error == 'invalid_client'
    And match karate.lowerCase(response.error_description) contains 'invalid client'

  @token_negative @invalid_client_secret 
  Scenario: Error al solicitar token con client_secret incorrecto  
    Given url 'https://autenticacionqa.coonecta.com.ec/auth/realms/PANAPAY/protocol/openid-connect/token' 
    And header Content-Type = 'application/x-www-form-urlencoded' 
    And form field grant_type = 'client_credentials' 
    And form field client_id = '0205cb' 
    And form field client_secret = 'invalid-secret-123' 
    When method post 
    Then status 200 
    And match response.error == 'unauthorized_client' 
    And match karate.lowerCase(response.error_description) contains 'invalid client' 
