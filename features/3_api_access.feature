Feature:    As a developer
            So that I can develop my own projects
            I would like to have access to exchange APIs

Scenario: API Access
    Given PENDING: Given that I am on the About page
    When I click on an API box
    Then my web browser should open a new tab 
    And navigate to that API’s webpage
