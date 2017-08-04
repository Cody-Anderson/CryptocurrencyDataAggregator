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
          
          # Bitfinex has different formatting for pairs, so this hash enables correct data pulling
          bfx_pair = {
            'BTC_ETH'  => 'ETHBTC',
            'BTC_XMR'  => 'XMRBTC',
            'BTC_DASH' => 'DSHBTC',
            'BTC_LTC'  => 'LTCBTC',
            'BTC_XRP'  => 'XRPBTC'
          }
          
          # Bitfinex has different formatting for time intervals, this array accounts for that
          bfx_time = [
            [ '5m',   300,    72, 6.hours ],
            [ '1h',   3600,   24, 1.day   ],
            [ '12h',  43200,  14, 1.week  ],
            [ '1D',   86400,  30, 1.month ],
          ]
          
          # Sets a variable to keep track of the loops
          first_loop = true
          
          loop do
            
            # pullPoloniex(timeToPull, pairsToPull)
            pullBittrex(timeToPull, pairsToPull)
            
            # Set time to pull to slightly larger than two intervals
            timeToPull.each do |intervalArray|
              intervalArray[1] = intervalArray[0] * 2
            end
            
            # Main loop that pulls data from Bitfinex
            # Nested loop so each pair/interval combo gets pulled
            bfx_pair.each do |k, v|
              bfx_time.each do |t|
                # Only pulls the two most-recent intervals after the first loop (saves time)
                if( first_loop )
                  bitfinex_pull( k, v, t[0], t[1], t[2] )
                else
                  bitfinex_pull( k, v, t[0], t[1], 2 )
                end
              end
            end
            
            # Removes candles when they become so old that they are no longer displayed
            bfx_time.each do |t|
              if( Candlestick.exists?( :timestamp => ( Time.at( 000000000 ) )...( Time.now - t[3] ), :interval => t[1] ) )
                Candlestick.where( :timestamp => ( Time.at( 000000000 ) )...( Time.now - t[3] ), :interval => t[1] ).destroy_all
              end
            end
            
            # No longer the first loop
            first_loop = false;
            
            sleep 120 # Sleep time in seconds
          end
          
        end
      end
    end
    
    # Grab data from Bitfinex
    def bitfinex_pull( pr1, pr2, int, int2, quant )
      # Data pulled, parsed from JSON
      parsed_tick_vals = JSON.parse(Net::HTTP.get(URI("https://api.bitfinex.com/v2/candles/trade:#{int}:t#{pr2}/hist?limit=#{quant}")))
      
      # For each tick
      parsed_tick_vals.each do |tick|
        time = Time.at(tick[0] / 1000).to_datetime  # Converts the epoch timestamp to datetime
        puts "preparing to add one of many"
        
        # Checks if a candle with the same timestamp and interval exists in the database
        # Also checks of the value of the candle has changed
        if( Candlestick.exists?( :exchange => 'Bitfinex', :pair => pr1, :interval => int2, :timestamp => time ) )
          if( Candlestick.exists?( :exchange => 'Bitfinex', :pair => pr1, :interval => int2, :timestamp => time,
                                  :low => tick[4], :open => tick[1], :close => tick[2], :high => tick[3] ) )
            puts "candle already exists, and has the same values"
          else
            # If the value of the candle has changed, overwrite the entry
            puts "overwriting outdated entry"
            Candlestick.where( :exchange => 'Bitfinex', :pair => pr1, :interval => int2, :timestamp => time ).destroy_all
            candle_tick = Candlestick.new( :exchange => 'Bitfinex', :pair => pr1, :low => tick[4], :open => tick[1], :close => tick[2], :high => tick[3], :timestamp => time, :interval => int2 )
            candle_tick.save
          end
        else
          # The candle does not exist, so write to database
          puts "candle does not exist - add to database"
          candle_tick = Candlestick.new( :exchange => 'Bitfinex', :pair => pr1, :low => tick[4], :open => tick[1], :close => tick[2], :high => tick[3], :timestamp => time, :interval => int2 )
          candle_tick.save
        end
      end
      puts "finished adding values for this interval"
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
              
            # Attempt to set pullInterval to largest factor of intervalArray[0] that is present in supportedIntervals
            pullInterval = getCompatibleInterval(intervalArray[0], supportedIntervals)
            unless supportedIntervals.include?(pullInterval) then next end
            
            # Sleeps to prevent more than 6 requests per second (Poloniex limit)
            while ((Time.now.to_f * 1000.0) - (requestStart.to_f * 1000.0) < 167) do sleep 0.01 end
            requestStart = Time.now
            
            # Request candlestick data
            candlestickData = JSON.parse(Net::HTTP.get(URI("https://poloniex.com/public?command=returnChartData&currencyPair=#{ticker[0]}&start=#{requestStart.to_i - intervalArray[1]}&end=9999999999&period=#{pullInterval}")))
            
            # Merge candlesticks if pulling an interval that isn't natively supported.
            unless supportedIntervals.include?(intervalArray[0]) then candlestickData = merge_Candlesticks(candlestickData, intervalArray[0], "high", "low", "close", "date") end
            
            # Check if each candlestick already exists in database. Then add if it doesn't and update if it does.
            candlestickData.each do |candlestick|
              addCandlestick("Poloniex", ticker[0], Time.at(candlestick["date"]), candlestick["open"], candlestick["high"], candlestick["low"], candlestick["close"], intervalArray[0])
            end
            
          end
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
                
              # Attempt to set pullInterval to largest factor of intervalArray[0] that is present in supportedIntervals
              pullInterval = getCompatibleInterval(intervalArray[0], supportedIntervals)
              unless supportedIntervals.include?(pullInterval) then next end
              
              # Go to next if not able to support that interval.
              unless supportedIntervals.include?(pullInterval) then next end
                
              # Convert time interval to Bittrex-compatible time period in words.
              intervalWords = convert_Intervals_to_Bittrex_Words(pullInterval)
              
              # Request candlestick data at five minute intervals.
              candlestickData = JSON.parse(Net::HTTP.get(URI("https://bittrex.com/Api/v2.0/pub/market/GetTicks?marketName=#{ticker["MarketName"]}&tickInterval=#{intervalWords}")))
            
              if candlestickData["success"]
                candlestickData = candlestickData["result"]
                
                # Remove all entries at the front of candlestickData that are too old.
                candlestickData = cleanup_Old_Candlesticks_Front("T", intervalArray[1], candlestickData)

                # Merge candlesticks if pulling an interval that isn't natively supported.
                unless supportedIntervals.include?(intervalArray[0]) then candlestickData = merge_Candlesticks(candlestickData, intervalArray[0], "H", "L", "C", "T") end
                
                # Store/update candlestick data
                candlestickData.each do |candlestick|
                  addCandlestick("Bittrex", ticker["MarketName"].sub('-','_'), Time.at(time_To_Seconds(candlestick["T"])), candlestick["O"], candlestick["H"], candlestick["L"], candlestick["C"], intervalArray[0])
                end
                
              end
            end
          end
          
        end
      end
      puts "Finished retrieval and storage of Bittrex data."
    end
    
    def addCandlestick(exchange, pair, time, openPrice, high, low, close, interval)
      # Check if candlestick already exists in database. Then add if it doesn't.
      currentRecord = Candlestick.find_by(:timestamp => time, :pair => pair, :exchange => exchange, :interval => interval)
      if currentRecord then currentRecord.update(:exchange => exchange, :pair => pair, :timestamp => time, :open => openPrice, :high => high, :low => low, :close => close, :interval => interval)
      else Candlestick.create(:exchange => exchange, :pair => pair, :timestamp => time, :open => openPrice, :high => high, :low => low, :close => close, :interval => interval) end
    end
    
    # Find highest possible factor of desiredInterval in supportedIntervals array.
    def getCompatibleInterval(desiredInterval, supportedIntervals)
      supportedIntervals.reverse_each do |interval|
        if desiredInterval % interval == 0 then return interval end
      end
      return 0 # Return 0 if impossible interval
    end
    
    # Converts Bittrex time to seconds timestamp.
    def time_To_Seconds(time)
      if time.is_a? Integer then return time else return DateTime.parse(time).to_time.to_i end
    end
    
    # Return array that only includes candlesticks timePeriod seconds ago.
    # Works faster when there is a larger amount of old candlesticks at the front of the array.
    def cleanup_Old_Candlesticks_Front(timeMarker, timePeriod, candlestickData)
      temp = []
      candlestickData.reverse_each do |candlestick|
        if (Time.now.to_i - DateTime.parse(candlestick[timeMarker]).to_time.to_i > timePeriod) then break
        else temp.push(candlestick) end
      end
      return temp.reverse
    end
    
    # Merge candlesticks into desiredInterval
    def merge_Candlesticks(candlestickData, desiredInterval, highSymbol, lowSymbol, closeSymbol, timeSymbol)
      newClose = newHigh = 0
      newLow = Float::INFINITY
      toBeMerged = false
      
      candlestickData.reverse_each do |candlestick|
        if time_To_Seconds(candlestick[timeSymbol]) % desiredInterval == 0 && toBeMerged
          candlestick[closeSymbol] = newClose
          candlestick[lowSymbol] = [newLow, candlestick[lowSymbol]].min
          candlestick[highSymbol] = [newHigh, candlestick[highSymbol]].max
          newClose = newHigh = 0
          newLow = Float::INFINITY
          toBeMerged = false
        else
          newLow = [newLow, candlestick[lowSymbol]].min
          newHigh = [newHigh, candlestick[highSymbol]].max
          unless toBeMerged
            toBeMerged = true
            newClose = candlestick[closeSymbol]
          end
          candlestickData.delete(candlestick)
        end
      end
      
      return candlestickData
    end
    
    # Convert pullInterval to Bittrex-request-compatible text
    def convert_Intervals_to_Bittrex_Words(pullInterval)
      return case pullInterval
      when 60 then "oneMin"
      when 300 then "fiveMin"
      when 1800 then "thirtyMin"
      when 3600 then "hour"
      when 86400 then "day"
      end
    end
    
  end
end
