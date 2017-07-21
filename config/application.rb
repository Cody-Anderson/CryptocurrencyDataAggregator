require File.expand_path('../boot', __FILE__)

require 'rails/all'
require 'net/http'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Workspace
  class Application < Rails::Application
    config.web_console.whiny_requests = false
    config.web_console.development_only = false
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    # config.time_zone = 'Central Time (US & Canada)'

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
    # config.i18n.default_locale = :de

    # Do not swallow errors in after_commit/after_rollback callbacks.
    config.active_record.raise_in_transactional_callbacks = true
    
    if defined?(Rails::Server)
      config.after_initialize do
        Thread.new do
          timeToPull = 36000 # Initial number of seconds worth of data to request from server
          loop do
            
            # Get Poloniex candlestick data for all markets, limit to 6 HTTP requests per second, and write all candlesticks to database, skipping candlesticks that are already in database.
            requestStart = Time.now # Time in seconds
            allTickers = JSON.parse(Net::HTTP.get(URI('https://poloniex.com/public?command=returnTicker')))
            
            # Loop for each currency pair in the Poloniex market.
            allTickers.each do |ticker|
              # Sleeps to prevent more than 6 requests per second (Poloniex limit)
              while ((Time.now.to_f * 1000.0) - (requestStart.to_f * 1000.0) < 167) do sleep 0.01 end
              requestStart = Time.now
              
              # Request candlestick data at five minute intervals.
              candlestickData = JSON.parse(Net::HTTP.get(URI("https://poloniex.com/public?command=returnChartData&currencyPair=#{ticker[0]}&start=#{requestStart.to_i - timeToPull}&end=9999999999&period=300")))
              
              # Do something for each candlestick.
              candlestickData.each do |candlestick|
                time = Time.at(candlestick["date"])
                unless Candlestick.exists?(:timestamp => time, :pair => ticker[0], :exchange => "Poloniex")
                  Candlestick.create(:exchange => "Poloniex", :pair => ticker[0], :timestamp => time, :open => candlestick["open"], :high => candlestick["high"], :low => candlestick["low"], :close => candlestick["close"])
                end
              end
            end
            puts "Finished retrieval and storage of Poloniex data."
            
            timeToPull = 650 # After first loop, reduce amount of time worth of data to request
            sleep 5 # Sleep time in seconds
          end
        end
      end
    end
  end
end
