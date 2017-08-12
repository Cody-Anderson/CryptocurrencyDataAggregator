Feature:    As an investor/user
            So I can trade at specific exchanges
            I would like to be able to click links to go to the websites of the exchanges

Scenario: Link to exchange website
    Given PENDING: That I am on the Exchanges page
    When I click on the button marked Bitstamp
    Then My web browser should open a new tab 
    And navigate to Bitstamp’s homepage
