Feature:    As an investor/user
            So I can trade at specific exchanges
            I would like to be able to click links to go to the websites of the exchanges

Scenario: Link to exchange website
    Given I am on the exchanges page
    When I click an exchange name
    Then I should see exchange button