Feature: Ejecutar afiliacion auxiliar para preparar escenarios de desafiliacion

  Scenario: Registrar afiliacion con datos predefinidos
    # Este helper reutiliza la configuracion global para registrar una afiliacion directa.
    Given url baseUrl
    And headers headers
    And path 'afiliacion'
    And request payload
    When method post
    * def result = { status: responseStatus, body: response }
