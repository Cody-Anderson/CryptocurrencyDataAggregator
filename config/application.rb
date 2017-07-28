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
          
          # Format: [[timeIntervalInSeconds, numberOfSeconds], [timeIntervalInSeconds, numberOfSeconds]]
          # Supported timeIntervalInSeconds values are 300 (5 minutes), 3600 (1 hour)
          timeToPull = [[300, 60*60*24]]
          pairsToPull = ["BTC_ETH", "BTC_XMR", "BTC_DASH", "BTC_LTC", "BTC_XRP", "BTC_ZEC", "BTC_SC"]
          
          loop do
            
            pullPoloniex(timeToPull, pairsToPull)
            pullBittrex(timeToPull, pairsToPull)
            
            # Set time to pull to slightly larger than two intervals
            timeToPull.each do |intervalArray|
              intervalArray[1] = intervalArray[0] * 2
            end
            
            sleep 5 # Sleep time in seconds
          end
          
        end
      end
    end
    
    # Get Poloniex candlestick data for all markets, limit to 6 HTTP requests per second, and write all candlesticks to database, skipping candlesticks that are already in database.
    def pullPoloniex(timeToPull, pairsToPull)
      requestStart = Time.now # Time in seconds
      allPoloniexTickers = JSON.parse(Net::HTTP.get(URI('https://poloniex.com/public?command=returnTicker')))
      
      # Loop for each currency pair in the Poloniex market.
      allPoloniexTickers.each do |ticker|
        
        # Check to see if pair is in pairsToPull whitelist.
        pairsToPull.each do |pair|
            if ticker[0] == pair
              timeToPull.each do |intervalArray|
                
                # Sleeps to prevent more than 6 requests per second (Poloniex limit)
                while ((Time.now.to_f * 1000.0) - (requestStart.to_f * 1000.0) < 167) do sleep 0.01 end
                requestStart = Time.now
                
                # Request candlestick data at five minute intervals.
                candlestickData = JSON.parse(Net::HTTP.get(URI("https://poloniex.com/public?command=returnChartData&currencyPair=#{ticker[0]}&start=#{requestStart.to_i - intervalArray[1]}&end=9999999999&period=#{intervalArray[0]}")))
                
                # Check if candlestick already exists in database. Then add if it doesn't.
                candlestickData.each do |candlestick|
                  time = Time.at(candlestick["date"])
                  currentRecord = Candlestick.find_by(:timestamp => time, :pair => ticker[0], :exchange => "Poloniex", :interval => intervalArray[0])
                  if currentRecord
                    currentRecord.update(:exchange => "Poloniex", :pair => ticker[0], :timestamp => time, :open => candlestick["open"], :high => candlestick["high"], :low => candlestick["low"], :close => candlestick["close"], :interval => intervalArray[0])
                  else
                    Candlestick.create(:exchange => "Poloniex", :pair => ticker[0], :timestamp => time, :open => candlestick["open"], :high => candlestick["high"], :low => candlestick["low"], :close => candlestick["close"], :interval => intervalArray[0])
                  end
                end
              end
              
              break # Skip checking of other pairsToPull pairs since match has been found.
            end
        end
      end
      puts "Finished retrieval and storage of Poloniex data."
    end
    
    # Get Bittrex candlestick data for all markets and write all candlesticks to database, skipping candlesticks that are already in database.
    def pullBittrex(timeToPull, pairsToPull)
      allBittrexTickers = JSON.parse(Net::HTTP.get(URI('https://bittrex.com/api/v1.1/public/getmarketsummaries')))
      
      if allBittrexTickers["success"]
        
        allBittrexTickers["result"].each do |ticker|
          
          # Check to see if pair is in whitelist
          pairsToPull.each do |pair|
            
            if ticker["MarketName"].sub('-','_') == pair
              
              timeToPull.each do |intervalArray|
                
                # Convert time interval to Bittrex-compatible time period in words
                intervalWords = case intervalArray[0]
                when 60 then "oneMin"
                when 300 then "fiveMin"
                when 1800 then "thirtyMin"
                when 3600 then "hour"
                when 86400 then "day"
                else next
                end
                
                # Request candlestick data at five minute intervals.
                candlestickData = JSON.parse(Net::HTTP.get(URI("https://bittrex.com/Api/v2.0/pub/market/GetTicks?marketName=#{ticker["MarketName"]}&tickInterval=#{intervalWords}")))
                
                if candlestickData["success"]
                  candlestickData["result"].each do |candlestick|
                    
                    # Skip values that are too old to be needed.
                    if (Time.now.to_i - DateTime.parse(candlestick["T"]).to_time.to_i > intervalArray[1]) then next end
                    
                    # Create variable to hold timestamp with time zone
                    time = Time.at(DateTime.parse(candlestick["T"]).to_time.to_i)
                    
                    # Check if candlestick already exists in database. Then add if it doesn't.
                    currentRecord = Candlestick.find_by(:timestamp => time, :pair => ticker["MarketName"].sub('-','_'), :exchange => "Bittrex", :interval => intervalArray[0])
                    if currentRecord
                      currentRecord.update(:exchange => "Bittrex", :pair => ticker["MarketName"].sub('-','_'), :timestamp => time, :open => candlestick["O"], :high => candlestick["H"], :low => candlestick["L"], :close => candlestick["C"], :interval => intervalArray[0])
                    else
                      Candlestick.create(:exchange => "Bittrex", :pair => ticker["MarketName"].sub('-','_'), :timestamp => time, :open => candlestick["O"], :high => candlestick["H"], :low => candlestick["L"], :close => candlestick["C"], :interval => intervalArray[0])
                    end
                  end
                end
              end
              
              break # Skip checking of other pairsToPull pairs since match has been found.
            end
          end
        end
      end
      puts "Finished retrieval and storage of Bittrex data."
    end
    
  end
end
