# "bitmex_app" a dynamically updated ruby framework/bot for bitmex trading, updated in realtime also capable of fetching candles in various ranges.  
  
this uses this apilibrary https://github.com/icostan/bitmex-api-ruby   (gem install bitmex-api-ruby)     
and then change in line #9 how its included from require_relative 'libs/bitmex-api-ruby-master/lib/bitmex' to require 'bitmex-api'  
  
create your own settings.rb and brain.rb. rest is dynamically updated as bitmex reports it out through websocket.  
  
register:  
@data[:margin]  #contains info about your balance and levearage etc, to display available data just, puts @data[:margin]   
@data[:position] #contains info about position  
@data[:orders] #contains info about open orders manual / auto orders (needs better tracking of manual orders but low prio on that)  
  
couple of bugs left to fix probally and some more features!
  
support by trading with my affiliate link https://www.bitmex.com/register/8mZL3t and receive a 10% fee discount for 6 months.
or send a beer btc: 1McrKQ7e4JCXPPnzQE1j5xGd35E1Vn3XwV :)  
  
push("Example msg for log")  
get_candles[0] #last candle on default settings forced update (costs 1 api-call)  
get_candles('1d', $symbol, true, 10, 'close')  #Example if you want a specific 10 x set of candles. where "true" is if reverse order or not, can be set to false also.  
set_trade('limit',7000,100) #limit order buy at $7000 x 100contracts long  
set_trade('stop',6500,-100) #stopmarket suited for a long position hence its a selloff  
reset                       #resets all orders  
Layout of @data/ws.data variable  
  
{:position=>  
  {:account=>value,  
   :avgCostPrice=>value,  
   :avgEntryPrice=>value,  
   :bankruptPrice=>value,  
   :breakEvenPrice=>value,  
   :currency=>"value",  
   :currentComm=>value,  
   :currentCost=>value,  
   :currentQty=>-value,  
   :currentTimestamp=>"value",  
   :execBuyCost=>value,  
   :execBuyQty=>value,  
   :execComm=>value,  
   :execCost=>value,  
   :execQty=>value,  
   :foreignNotional=>value,  
   :grossExecCost=>value,  
   :grossOpenCost=>value,  
   :homeNotional=>value,  
   :initMargin=>value,  
   :lastValue=>value,  
   :liquidationPrice=>value,  
   :maintMargin=>value,  
   :marginCallPrice=>value,  
   :markPrice=>value,  
   :markValue=>value,  
   :posComm=>value,  
   :posCost=>value,  
   :posCost2=>value,  
   :posInit=>value,  
   :posMaint=>value,  
   :posMargin=>value,  
   :realisedPnl=>value,  
   :riskValue=>value,  
   :symbol=>"value",  
   :unrealisedCost=>value,  
   :unrealisedGrossPnl=>value,  
   :unrealisedPnl=>value,  
   :unrealisedRoePcnt=>value},  
 :orders=>  
  [{:Type=>"value",  
    :Id=>"TrackingId-value-value",  
    :Side=>"value",  
    :Price=>value,  
    :Num=>value}],  
 :margin=>  
  {:account=>value,  
   :availableMargin=>value,  
   :currency=>"value",  
   :excessMargin=>value,  
   :excessMarginPcnt=>value,  
   :grossLastValue=>value,  
   :grossMarkValue=>value,  
   :maintMargin=>value,  
   :marginBalance=>value,  
   :marginLeverage=>value,  
   :riskValue=>value,  
   :timestamp=>"value",  
   :unrealisedPnl=>value,  
   :withdrawableMargin=>value}}  