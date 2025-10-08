Feature: Crear usuario dinamico

  Scenario:
    * def username = 'u' + java.util.UUID.randomUUID().toString().replace('-', '').substring(0, 12)
    * def password = java.util.UUID.randomUUID().toString().replace('-', '')
    * def signupResult = karate.call('classpath:helpers/signup-once.feature', { username: username, password: password })
    * def signupResponse = signupResult.response
    * if (karate.typeOf(signupResponse) != 'string') karate.fail('Respuesta inesperada en signup: ' + signupResponse)
    * def response = signupResponse.trim()
    * karate.match(response, '""')
    * karate.log('usuario creado', username)
