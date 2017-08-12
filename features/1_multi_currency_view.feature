Feature:    As an investor
            So I can compare growth rates of different currencies
            I would like to be able to view two or more currency prices in the same chart

Scenario: Multi-Currency View
    Given PENDING: I am on the currency market graphs page
    When I check the Bitcoin box
    Then the current market graph for Bitcoin will displayed in the relevant time range
    And I check the Ethereum box
    Then the current market graph for Ethereum and Bitcoin will be displayed together, both in the relevant time range
