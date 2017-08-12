Feature:    As a developer
            So that I can develop my own apps to interact with the Exchanges
            I would like a summary of how each Exchange’s API works

Scenario: API Summmary
    Given PENDING: That I am on the API page
    When I scroll down to the name of the exchange
    Then I should see helpful tips about the exchange’s API, such as rate limits