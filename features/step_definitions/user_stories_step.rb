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
    page.should have_selector("div", :id=>'pair1')
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