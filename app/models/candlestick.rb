class Candlestick < ActiveRecord::Base
    
    def self.up
        create_table :candlesticks, force: :cascade do |t|
            t.string   :exchange
            t.string   :pair
            t.datetime :timestamp,                          null: false
            t.decimal  :open,      precision: 32, scale: 8, null: false
            t.decimal  :high,      precision: 32, scale: 8, null: false
            t.decimal  :low,       precision: 32, scale: 8, null: false
            t.decimal  :close,     precision: 32, scale: 8, null: false
            t.index [:timestamp, :pair, :exchange], unique: true
        end
    end
    
    def self.down
        drop_table :candlesticks
    end
end
