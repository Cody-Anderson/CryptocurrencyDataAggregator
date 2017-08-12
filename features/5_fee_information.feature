Feature:    As a trader
            So I can trade large volumes of cryptocurrencies with minimal fees
            I would like to see a summary of the fee rates at each cryptocurrency exchange

Scenario: Fee Information
    Given PENDING: I am on the Exchanges page
    When I click on the name of the exchange
    Then I should see a value denoting the fees for trading at that exchange
