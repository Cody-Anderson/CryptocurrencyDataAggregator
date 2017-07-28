class Candlestick < ActiveRecord::Base
    
    def self.up
        create_table :candlesticks, force: :cascade do |t|
            t.string   :exchange
            t.string   :pair
            t.datetime :timestamp,                          null: false
            t.float  :open,      precision: 32, scale: 8, null: false
            t.float  :high,      precision: 32, scale: 8, null: false
            t.float  :low,       precision: 32, scale: 8, null: false
            t.float  :close,     precision: 32, scale: 8, null: false
            t.integer  :interval,                           null: false
            t.index [:timestamp, :pair, :exchange, :interval], unique: true
        end
    end
    
    def self.down
        drop_table :candlesticks
    end
end
