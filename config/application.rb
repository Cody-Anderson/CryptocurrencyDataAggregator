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
          # Supported timeIntervalInSeconds values are any multiple of 300.
          timeToPull = [[300, 60*60*24 + 300], [3600, 60*60*24*7 + 3600], [43200, 60*60*24*7 + 43200], [86400, 60*60*24*30 + 86400]]
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
      supportedIntervals = [300, 900, 1800, 7200, 14400, 86400] # Intervals supported by Poloniex
      
      # Loop for each currency pair in the Poloniex market.
      allPoloniexTickers.each do |ticker|
        
        # Check to see if pair is in pairsToPull whitelist.
        if pairsToPull.include?(ticker[0])
          timeToPull.each do |intervalArray|
              
              # Set pull interval to highest factor of intervalArray[0] if possible
              pullInterval = intervalArray[0]
              unless supportedIntervals.include?(intervalArray[0])
                supportedIntervals.reverse_each do |interval|
                  if intervalArray[0] % interval == 0
                    pullInterval = interval
                    break
                  end
                end
              end
              
              # Go to next if not able to support that interval
              unless supportedIntervals.include?(pullInterval) then next end
              
              # Sleeps to prevent more than 6 requests per second (Poloniex limit)
              while ((Time.now.to_f * 1000.0) - (requestStart.to_f * 1000.0) < 167) do sleep 0.01 end
              requestStart = Time.now
              
              # Request candlestick data
              candlestickData = JSON.parse(Net::HTTP.get(URI("https://poloniex.com/public?command=returnChartData&currencyPair=#{ticker[0]}&start=#{requestStart.to_i - intervalArray[1]}&end=9999999999&period=#{pullInterval}")))
              
              # Merge candlesticks if pulling an interval that isn't natively supported by Poloniex
              unless supportedIntervals.include?(intervalArray[0])
                newClose = newHigh = 0
                newLow = Float::INFINITY
                toBeMerged = false
                candlestickData.reverse_each do |candlestick|
                  if candlestick["date"] % intervalArray[0] == 0 && toBeMerged
                    candlestick["close"] = newClose
                    candlestick["low"] = [newLow, candlestick["low"]].min
                    candlestick["high"] = [newHigh, candlestick["high"]].max
                    newClose = newHigh = 0
                    newLow = Float::INFINITY
                    toBeMerged = false
                  else
                    newLow = [newLow, candlestick["low"]].min
                    newHigh = [newHigh, candlestick["high"]].max
                    unless toBeMerged
                      toBeMerged = true
                      newClose = candlestick["close"]
                    end
                    candlestickData.delete(candlestick)
                  end
                end
              end
              
              # Check if each candlestick already exists in database. Then add if it doesn't and update if it does.
              candlestickData.each do |candlestick|
                time = Time.at(candlestick["date"])
                currentRecord = Candlestick.find_by(:timestamp => time, :pair => ticker[0], :exchange => "Poloniex", :interval => intervalArray[0])
                if currentRecord then currentRecord.update(:exchange => "Poloniex", :pair => ticker[0], :timestamp => time, :open => candlestick["open"], :high => candlestick["high"], :low => candlestick["low"], :close => candlestick["close"], :interval => intervalArray[0])
                else Candlestick.create(:exchange => "Poloniex", :pair => ticker[0], :timestamp => time, :open => candlestick["open"], :high => candlestick["high"], :low => candlestick["low"], :close => candlestick["close"], :interval => intervalArray[0]) end
              end
            end
            
            break # Skip checking of other pairsToPull pairs since match has been found.
        end
        
      end
      puts "Finished retrieval and storage of Poloniex data."
    end
    
    # Get Bittrex candlestick data for all markets and write all candlesticks to database, skipping candlesticks that are already in database.
    def pullBittrex(timeToPull, pairsToPull)
      allBittrexTickers = JSON.parse(Net::HTTP.get(URI('https://bittrex.com/api/v1.1/public/getmarketsummaries')))
      supportedIntervals = [60, 300, 1800, 3600, 86400]
      
      if allBittrexTickers["success"]
        allBittrexTickers["result"].each do |ticker|
          
          # Check to see if pair is in whitelist
          if pairsToPull.include?(ticker["MarketName"].sub('-','_'))
            timeToPull.each do |intervalArray|
                
              # Set pull interval to highest factor of intervalArray[0] if possible
              pullInterval = intervalArray[0]
              unless supportedIntervals.include?(intervalArray[0])
                supportedIntervals.reverse_each do |interval|
                  if intervalArray[0] % interval == 0
                    pullInterval = interval
                    break
                  end
                end
              end
              
              # Go to next if not able to support that interval
              unless supportedIntervals.include?(pullInterval) then next end
                
              # Convert time interval to Bittrex-compatible time period in words
              intervalWords = case pullInterval
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
                candlestickData = candlestickData["result"]
                
                # Remove all entries that are too old from candlestickData
                temp = []
                candlestickData.reverse_each do |candlestick|
                  if (Time.now.to_i - DateTime.parse(candlestick["T"]).to_time.to_i > intervalArray[1]) then break
                  else temp.push(candlestick) end
                end
                candlestickData = temp.reverse
                
                # Merge candlesticks if pulling an interval that isn't natively supported by Poloniex
                unless supportedIntervals.include?(intervalArray[0])
                  newClose = newHigh = 0
                  newLow = Float::INFINITY
                  toBeMerged = false
                  candlestickData.reverse_each do |candlestick|
                    if DateTime.parse(candlestick["T"]).to_time.to_i % intervalArray[0] == 0 && toBeMerged
                      candlestick["C"] = newClose
                      candlestick["L"] = [newLow, candlestick["L"]].min
                      candlestick["H"] = [newHigh, candlestick["H"]].max
                      newClose = newHigh = 0
                      newLow = Float::INFINITY
                      toBeMerged = false
                    else
                      newLow = [newLow, candlestick["L"]].min
                      newHigh = [newHigh, candlestick["H"]].max
                      unless toBeMerged
                        toBeMerged = true
                        newClose = candlestick["C"]
                      end
                      candlestickData.delete(candlestick)
                    end
                  end
                end
                
                candlestickData.each do |candlestick|
                    
                  # Create variable to hold timestamp with time zone
                  time = Time.at(DateTime.parse(candlestick["T"]).to_time.to_i)
                  
                  # Check if candlestick already exists in database. Then add if it doesn't.
                  currentRecord = Candlestick.find_by(:timestamp => time, :pair => ticker["MarketName"].sub('-','_'), :exchange => "Bittrex", :interval => intervalArray[0])
                  if currentRecord then currentRecord.update(:exchange => "Bittrex", :pair => ticker["MarketName"].sub('-','_'), :timestamp => time, :open => candlestick["O"], :high => candlestick["H"], :low => candlestick["L"], :close => candlestick["C"], :interval => intervalArray[0])
                  else Candlestick.create(:exchange => "Bittrex", :pair => ticker["MarketName"].sub('-','_'), :timestamp => time, :open => candlestick["O"], :high => candlestick["H"], :low => candlestick["L"], :close => candlestick["C"], :interval => intervalArray[0]) end
                end
              end
            end
            
            break # Skip checking of other pairsToPull pairs since match has been found.
          end
          
        end
      end
      puts "Finished retrieval and storage of Bittrex data."
    end
    
  end
end
