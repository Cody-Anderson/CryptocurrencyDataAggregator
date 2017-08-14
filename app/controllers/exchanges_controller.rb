class ExchangesController < ApplicationController
  def index
  end
  
  def show
    if( params[:p] == nil )   # This logic sets the default pair to BTC_ETH
      pair = 'BTC_ETH'        # It also avoids a nil value being assigned to pair
    else
      pair = params[:p]
    end
    
    if( params[:tf] == nil )    # This logic sets the default timeframe to 6 hours
      @frame = 6.hours          # It also avoids a nil value being assigned to @frame
    else
      @frame = eval(params[:tf])
    end
    
    if( params[:all] == 'true' )     # Sets @all variable to be true if all exhanges are wanted
      @all = true
    elsif( params[:all] == 'false' )   # Sets @all variable to be false if one exchange is wanted
      @all = false
    end
    
    @pair1 = pair[0..2]             # First part of pair
    @pair2 = pair[4..-1]            # Second part of pair
    @pair = "#{@pair1}_#{@pair2}"   # Entire pair
    
    @exchange = params[:x]  # Exchange value
    
    case @frame
      when 6.hours
        interval = 300      # For a 6-hour timeframe, use 5 minute candles
      when 1.day
        interval = 3600     # For a day-long timeframe, use 1 hour candles
      when 1.week
        interval = 43200    # For a week-long timeframe, use 12 hour candles
      when 1.month
        interval = 86400    # For a month-long timeframe, use 24 hour candles
    end
    
    # Minimum and maximum verticle axis values will be calculated from these values
    @min = Candlestick.where( :timestamp => (Time.now - @frame)..(Time.now), :exchange => @exchange, :pair => pair, :interval => interval ).minimum(:low)
    @max = Candlestick.where( :timestamp => (Time.now - @frame)..(Time.now), :exchange => @exchange, :pair => pair, :interval => interval ).maximum(:high)
    
    # Sets up the data variable based on if it wants one or multiple series
    if( @all == false )
      # Assigns the appropriate data to @candles, according the the exchange, pair, and interval data
      @candles = Candlestick.order( :timestamp ).where( :timestamp => (Time.now - @frame)..(Time.now),
                :exchange => @exchange, :pair => pair, :interval => interval ).pluck( :timestamp, :low, :open, :close, :high )
      
      # Sets up the label information for the legend
      labels = [ '', @exchange, '', '', '' ]
      @candles = @candles.unshift( labels )
      
    # Sets up the @candles array to display multiple series
    else
      @candles = Candlestick.order( :timestamp ).where( :timestamp => (Time.now - @frame)..(Time.now),
                :exchange => "Bittrex", :pair => pair, :interval => interval ).pluck( :timestamp, :low, :open, :close, :high )
      
      @candles2 = Candlestick.order( :timestamp ).where( :timestamp => (Time.now - @frame)..(Time.now),
                :exchange => "Poloniex", :pair => pair, :interval => interval ).pluck( :timestamp, :low, :open, :close, :high )
      
      # Accounts for the case where BTC_ZEC or BTC_SC pairs are shown (Bitfinex doesn't have these)
      unless( :pair == 'BTC_ZEC' || :pair == 'BTC_SC' )
      
        # Calculates the new mins and maxes
        @min = Candlestick.where( :timestamp => (Time.now - @frame)..(Time.now), :pair => pair, :interval => interval ).minimum(:low)
        @max = Candlestick.where( :timestamp => (Time.now - @frame)..(Time.now), :pair => pair, :interval => interval ).maximum(:high)
      
        @candles3 = Candlestick.order( :timestamp ).where( :timestamp => (Time.now - @frame)..(Time.now),
                  :exchange => "Bitfinex", :pair => pair, :interval => interval ).pluck( :timestamp, :low, :open, :close, :high )
      end
      
      i = 0            
      @candles.each do |candle|   # Combines the first and second series so the graph can render them
        
        # Ensures that empty spots in a series are taken care of
        if( @candles2[i] != nil && candle[0] == @candles2[i][0] )
            candle.push( @candles2[i][1], @candles2[i][2], @candles2[i][3], @candles2[i][4] )
            i = i + 1
          else
            candle.push( 0, 0, 0, 0 )
            i = i + 1
          end
          
      end
      
      # Combines the third series, if it's not BTC_ZEC or BTC_SC
      unless( @pair == 'BTC_ZEC' || @pair == 'BTC_SC' )
        i = 0
        @candles.each do |candle|
          
          # Ensures that empty spots in a series are taken care of
          if( @candles3[i] != nil && candle[0] == @candles3[i][0] )
            candle.push( @candles3[i][1], @candles3[i][2], @candles3[i][3], @candles3[i][4] )
            i = i + 1
          else
            candle.push( 0, 0, 0, 0 )
            i = i + 1
          end
          
        end
      end
      
      # This sets up the legend for the chart to interpret
      if( @pair == 'BTC_ZEC' || @pair == 'BTC_SC' )
        labels = [ '', 'Bittrex', '', '', '', 'Poloniex', '', '', '' ]
      else
        labels = [ '', 'Bittrex', '', '', '', 'Poloniex', '', '', '', 'Bitfinex', '', '', '' ]
      end
      
      # Puts the labels array at the beggining of @candles, and shifts the rest forward one index
      @candles = @candles.unshift( labels )
      
    end
  
  end
end
