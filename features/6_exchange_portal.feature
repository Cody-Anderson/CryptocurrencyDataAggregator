Feature:    As an investor/user
            So I can trade at specific exchanges
            I would like to be able to click links to go to the websites of the exchanges

Scenario: Exchange Portal
    Given I am on the about page
    When I click on the button marked Bittrex
    Then my web browser should navigate to Bittrex's webpage
