Feature:    As a trader
            So I can store my cryptocurrencies
            I would like to be able to click links to go to the websites of wallets.

Scenario: Fee Information
    Given I am on the wallets page
    When I click the coinbase button
    Then My browser should open a new tab and go to the coinbase webpage
