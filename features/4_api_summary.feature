Feature:    As a developer
            So that I can develop my own apps to interact with the Exchanges
            I would like a summary of how each Exchange’s API works

Scenario: API Summmary
    Given I am on the about page
    When I scroll down to the name of the exchange
    Then I should see helpful tips about the exchange API, such as rate limits