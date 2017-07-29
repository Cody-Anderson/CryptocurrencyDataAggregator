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
    
    @pair1 = pair[0..2]             # First part of pair
    @pair2 = pair[4..-1]            # Second part of pair
    @pair = "#{@pair1}_#{@pair2}"   # Entire pair
    
    @exchange = params[:x]  # Exchange value
    
    case @frame
      when 6.hours
        interval = 300      # For a 6-hour timeframe, use 5 minute candles
      when 1.day
        interval = 3600     # For a day-long timeframe, use 30 minute candles
      when 1.week
        interval = 14400    # For a week-long timeframe, use 4 hour candles
      when 1.month
        interval = 86400    # For a month-long timeframe, use 24 hour candles
    end
    
    # Assigns the appropriate data to @candles, according the the exchange, pair, and interval data
    @candles = Candlestick.order( :timestamp ).where( :timestamp => (Time.now - @frame)..(Time.now),
                :exchange => @exchange, :pair => pair, :interval => interval ).pluck( :timestamp, :low, :open, :close, :high )
  end
end
