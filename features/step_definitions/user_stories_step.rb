Given(/^I am on the exchanges page$/)do
    visit "/exchanges"
end
When(/^I click an exchange name$/) do
    links = Array.new
    page.all(:link,"exchanges").each do |link|
        links << link
    end
    count = links.length
    linkNumb = Random.rand(count)
    links[linkNumb].click
    
end
Then(/^I should see exchange button$/) do
    page.should have_selector("a", :class => 'exchange_button')
end

Given(/^I am comparing currencies$/) do
    visit "/exchanges/show.html?x=Bitfinex"
end
When(/^I select a currency$/) do
    links = Array.new
    page.all(:link, :class =>"exchange_button").each do |link|
        links << link
    end
    count = links.length
    linkNumb = Random.rand(count)
    links[linkNumb].click
end
Then(/^I should see the currency price history$/) do
    page.should have_selector("div", :id => 'pair1')
    page.should have_selector("div", :id => 'pair2')
end

Given(/^I am on the welcome page$/) do
    visit "/"
end
When(/^I click on the about button$/) do
    click_on(:id=>"about")
end
Then(/^I should be on the about page$/) do
    current_path.should == "/about"
end

When(/^I click on new to market button$/) do
    page.should have_selector("a", :id => "intro")
end
Then(/^Browser creates new tab that directs me to an introduction$/) do
    href = "http://cryptosource.org/getting-started/"
    page.should have_selector "a[href='#{href}']"
end

Given(/^I am on the wallets page$/) do
    visit "/wallets"
end
When(/^I click the coinbase button$/) do
    page.should have_selector("img", :id => "coinbase")
end
Then(/^My browser should open a new tab and go to the coinbase webpage$/) do
    href = "https://www.coinbase.com/mobile?locale=en-US"
    page.should have_selector "a[href='#{href}']"
end

Given(/^I am on the home page$/) do
    visit "/"
end
When(/^I click on the Twitter feed$/) do
    page.should have_selector("a", :class => "twitter-timeline")
end
Then(/^my browser should redirect me to the article source$/) do
    href = "https://twitter.com/CryptoCoinsNews"
    page.should have_selector "a[href='#{href}']"
end

Then(/^I should see an all exchanges button$/) do
    page.should have_selector(:link, "All Exchanges")
end

Given(/^I am on the about page$/) do
    visit "/about"
end
When(/^I click on the button marked Bittrex$/) do
    page.should have_selector("a", :id => "BittrexAPILink")
end
Then(/^my web browser should navigate to that APIs webpage$/) do
    href = "https://bittrex.com/home/api"
    page.should have_selector "a[href='#{href}']"
end

When(/^I scroll down to the name of the exchange$/) do
    page.should have_selector("a", :id => "BittrexAPILink")
end
Then(/^I should see helpful tips about the exchange API, such as rate limits$/) do
    page.should have_selector("div", :id => "APInotes")
end

When(/^I hover over the name of an exchange$/) do
   page.should have_selector("a", :id => "exchanges")
end
Then(/^I should see a value denoting the fees for trading at that exchange$/) do
    page.should have_selector("div", :id => "bittrex_fees")
end

Then(/^my web browser should navigate to Bittrex's webpage$/) do
    href = "https://bittrex.com/home/api"
    page.should have_selector "a[href='#{href}']"
end