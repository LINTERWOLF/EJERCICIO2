Feature: Ejecutar acciones de desafiliacion auxiliares

  Scenario: Ejecutar una accion sobre desafiliacion
    # Permite encadenar bloqueos/desbloqueos previos antes del escenario principal.
    Given url baseUrl
    And headers headers
    And path 'desafiliacion'
    And request payload
    When method post
    * def result = { status: responseStatus, body: response }
