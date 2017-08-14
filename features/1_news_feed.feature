Feature:    As a trader
            So that I can keep up to date on the latest cryptocurrency news
            I would like a central location from which to view cryptocurrency news articles


Scenario: News Feed
    Given I am on the home page
    When I click on the Twitter feed
    Then my browser should redirect me to the article source
