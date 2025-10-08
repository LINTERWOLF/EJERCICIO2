Feature: Pruebas de autenticacion Demoblaze

  Background:
    * url 'https://api.demoblaze.com'
    * configure headers = { 'Content-Type': 'application/json', 'Accept': 'application/json' }
    * def normalizeError = read('classpath:helpers/normalize-error.js')
    * def userData = callonce read('classpath:helpers/create-user.feature')
    * def username = userData.username
    * def password = userData.password

  Scenario: Signup crea un usuario nuevo
    Then match userData.response == '""'
    And print { createdUser: username, signupResponse: userData.response }

  Scenario: Signup rechaza un usuario existente
    Given path 'signup'
    And request { username: '#(username)', password: '#(password)' }
    When method post
    Then status 200
    * def duplicateMessage = normalizeError(response)
    * match duplicateMessage == 'This user already exist.'
    And print { duplicateError: duplicateMessage }

  Scenario: Login exitoso con usuario valido
    Given path 'login'
    And request { username: '#(username)', password: '#(password)' }
    When method post
    Then status 200
    * def loginResponse = response
    * if (karate.typeOf(loginResponse) != 'string') karate.fail('Se esperaba cadena vacía en login exitoso, se recibió: ' + loginResponse)
    * def loginBody = loginResponse.trim()
    * eval if (loginBody != '""' && loginBody.startsWith('"') && loginBody.endsWith('"')) loginBody = loginBody.substring(1, loginBody.length() - 1)
    * if (loginBody != '""' && !loginBody.startsWith('Auth_token:')) karate.fail('Respuesta inesperada en login exitoso: ' + loginBody)
    And print { loginOk: loginBody }

  Scenario: Login falla con password incorrecto
    Given path 'login'
    * def invalidPassword = password + 'X'
    And request { username: '#(username)', password: '#(invalidPassword)' }
    When method post
    Then status 200
    * def loginErrorMessage = normalizeError(response)
    * match loginErrorMessage == 'Wrong password.'
    And print { loginError: loginErrorMessage }
