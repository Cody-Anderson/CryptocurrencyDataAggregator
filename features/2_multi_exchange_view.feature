Feature:    As an investor
            So that I can find the best deals for a given cryptocurrency
            I would like to see the prices at each exchange in one convenient location

Scenario: Multi-Exchange View
    Given I am on the exchanges page
    When I click an exchange name
    Then I should see exchange button
