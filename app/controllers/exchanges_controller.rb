class ExchangesController < ApplicationController
  def index
  end
  
  def show
    if( params[:p] == nil )   # This logic sets the default pair to BTC_ETH
      pair = 'BTC_ETH'        # It also avoids a nil value being assigned to pair
    else
      pair = params[:p]
    end
    
    @pair1 = pair[0..2]   # First part of pair
    @pair2 = pair[4..-1]   # Second part of pair
    
    @exchange = params[:x]  # Exchange value
    
    # Assigns the appropriate data to @candles, according the the exchange, pair, and interval data
    @candles = Candlestick.order( :timestamp ).where( :exchange => @exchange, :pair => pair, :interval => 300 ).pluck( :timestamp, :low, :open, :close, :high )
  end
end
