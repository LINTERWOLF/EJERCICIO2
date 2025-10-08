Feature: Helper para crear usuario

  Scenario:
    Given url 'https://api.demoblaze.com'
    And configure headers = { 'Content-Type': 'application/json', 'Accept': 'application/json' }
    And path 'signup'
    And request { username: '#(username)', password: '#(password)' }
    When method post
    Then status 200
    And print response
