Scenario: See prices from multiple exchanges
GIVEN I am comparing currencies
WHEN I select a currency summary
THEN I should see  a list of markets and prices

Scenario: Compare two currencies growth
GIVEN I am comparing currencies
WHEN I select two currencies
THEN I should see both currencies price histories

Scenario: Link to exchange website
WHEN I click an exchange name
THEN I should go to that exchange websites

Scenario: Historical Prices
GIVEN I am comparing currencies
WHEN I select a currency
THEN I should see the currency price history