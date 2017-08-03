When(/^I click an exchange name$/) do
    visit "/exchanges"
    links = Array.new
    page.all(:link,"exchanges").each do |link|
        links << link
    end
    count = links.length
    linkNumb = Random.rand(count)
    links[linkNumb].click
    
end

Then(/^I should see exhange button$/) do
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



When(/^I am on the about page$/) do
    visit "/about"
end

Then(/^I should see a github link$/) do
    page.should have_selector("a", :id=>'github')
end


