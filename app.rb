#!/usr/bin/ruby
# coding: utf-8 
#
# NITLOTT PRODUCTIONS
#
require 'securerandom'
require 'em/pure_ruby'
require 'enumerator'
require_relative 'libs/bitmex-api-ruby-master/lib/bitmex'
require 'simple_statistics'
require_relative 'settings'
class String
    def black;          "\e[30m#{self}\e[0m" end
    def red;            "\e[31m#{self}\e[0m" end
    def green;          "\e[32m#{self}\e[0m" end
    def brown;          "\e[33m#{self}\e[0m" end
    def blue;           "\e[34m#{self}\e[0m" end
    def magenta;        "\e[35m#{self}\e[0m" end
    def cyan;           "\e[36m#{self}\e[0m" end
    def gray;           "\e[37m#{self}\e[0m" end

    def bg_black;       "\e[40m#{self}\e[0m" end
    def bg_red;         "\e[41m#{self}\e[0m" end
    def bg_green;       "\e[42m#{self}\e[0m" end
    def bg_brown;       "\e[43m#{self}\e[0m" end
    def bg_blue;        "\e[44m#{self}\e[0m" end
    def bg_magenta;     "\e[45m#{self}\e[0m" end
    def bg_cyan;        "\e[46m#{self}\e[0m" end
    def bg_gray;        "\e[47m#{self}\e[0m" end

    def bold;           "\e[1m#{self}\e[22m" end
    def italic;         "\e[3m#{self}\e[23m" end
    def underline;      "\e[4m#{self}\e[24m" end
    def blink;          "\e[5m#{self}\e[25m" end
    def reverse_color;  "\e[7m#{self}\e[27m" end    
    def no_colors
        self.gsub /\e\[\d+m/, ""
    end
end
class BitmexWebsocket
    require_relative 'brain'
    attr_reader :client
    attr_accessor :data
    def initialize()#sets up client etc
        @start=Time.new
        @counter=0
        @data = { position: {}, orders: [], margin: {} }
        @client = $settings_testnet ? (Bitmex::Client.new testnet: true, api_key: $tapi_key, api_secret: $tapi_secret) : (Bitmex::Client.new testnet: false, api_key: $api_key, api_secret: $api_secret)
    end
    def push(mess)#pushes info to log with timestamp
        time = Time.new
        caller_method = caller_locations.first.label
        x="no_colors"
        if caller_method.include? "listen"
            if mess.include?('Filterd trade')
                puts (time.strftime("log[%d/%m/%Y-%k:%M]>->").gsub(/\s+/, "0")+" "+mess+" ").bg_black.green
            elsif mess.include?('REKTALABAMA')
                puts (time.strftime("log[%d/%m/%Y-%k:%M]>->").gsub(/\s+/, "0")+" "+mess+" ").bg_black.cyan
            else
                puts (time.strftime("log[%d/%m/%Y-%k:%M]>->").gsub(/\s+/, "0")+" "+mess+" ").bg_black.red
            end
        elsif caller_method.include? "selfcheck"
            puts (time.strftime("log[%d/%m/%Y-%k:%M]>->").gsub(/\s+/, "0")+" "+mess+" ").bg_black.gray
        elsif caller_method.include? "set_trade"
            puts (time.strftime("log[%d/%m/%Y-%k:%M]>->").gsub(/\s+/, "0")+" "+mess+" ").bg_black.cyan
        elsif caller_method.include? "reset"
            puts (time.strftime("log[%d/%m/%Y-%k:%M]>->").gsub(/\s+/, "0")+" "+mess+" ").bg_black.magenta
        elsif caller_method.include? "main"
            puts (time.strftime("log[%d/%m/%Y-%k:%M]>->").gsub(/\s+/, "0")+" "+mess+" ").bg_black.gray
        else
            puts (time.strftime("log[%d/%m/%Y-%k:%M]>->").gsub(/\s+/, "0")+" "+mess+" ").no_colors
        end
        #puts caller_method
    end
    def get_candles(bucket = '1d', symbol = $symbol, reverse = 'true', count = 5, value = 'neutral')#fetches candles of choice
        #Example ws.get_candles('1d', $symbol, true, 10, 'close')
        b, s, r, c, v, output = bucket, symbol, reverse, count, value, []
        candles = @client.trades.bucketed b, symbol: s, reverse: r, count: c 
        candles.each do |x|
            op, close, low, high, vol, vwap, symbol = x.open, x.close, x.low, x.high, x.volume, x.vwap, x.symbol
            if v == 'close'
                output << x.close
            else
                output << "Coin: #{symbol} Open #{op} Close: #{close} High: #{high} Low: #{low} Volume: #{vol} Vwap: #{vwap}"
            end
        end     
        return output
    end
    def set_trade(type='limit', price=3000, qty=1)#sets a a limit or a stoploss order with unique trackingid
        def rand(x=type,q=qty)          
            if q > 0           
                x = x + "buy"          
            else           
                x = x + "sell"          
            end
            clOrdID = "TrackingId-" + x +SecureRandom.uuid[23..35]            
        end
        if type=='stop'
            order = @client.orders.create $symbol, orderQty: qty, ordType: 'Stop', clOrdID: rand(type,qty), stopPx: price, execInst: 'Close,LastPrice' #"Close,LastPrice" ReduceOnly
            push("Posting StopMarket | Qty: #{order.orderQty} @ #{order.stopPx} with ID: #{order.clOrdID[-12,12]}")
        elsif type=='limit' 
            order = @client.orders.create $symbol, orderQty: qty, price: price, clOrdID: rand(type,qty), execInst: 'ParticipateDoNotInitiate'
            push("Posting LimitOrder | Side: #{order.side} Qty: #{order.orderQty} @ #{order.price} with ID: #{order.clOrdID[-12,12]}")
        else
            push("This function is not supported yet.. :(")
        end  
    end
    def listen#listens to live data and keeps variables up to date
        client = @client
        puts "Subscribing to selected channels!"
        client.websocket.listen position: $symbol, margin: '', order: $symbol, chat: '1', liquidation: $symbol, trade: $symbol do |data|
            if data.maintMargin and data.marginBalance
                margin={ account: data.account, action: data.action, amount: data.amount, availableMargin: data.availableMargin, commission: data.commission,
                    confirmedDebit: data.confirmedDebit, currency: data.currency, excessMargin: data.excessMargin, excessMarginPcnt: data.excessMarginPcnt, 
                    grossComm: data.grossComm, grossExecCost: data.grossExecCost, grossLastValue: data.grossLastValue, grossMarkValue: data.grossMarkValue,
                    grossOpenCost: data.grossOpenCost, grossOpenPremium: data.grossOpenPremium, indicativeTax: data.indicativeTax, initMargin: data.initMargin,
                    maintMargin: data.maintMargin, marginBalance: data.marginBalance, marginBalancePcnt: data.marginBalancePcnt, marginLeverage: data.marginLeverage,
                    marginUsedPcnt: data.marginUsedPcnt, pendingCredit: data.pendingCredit, pendingDebit:data.pendingDebit, prevRealisedPnl:data.prevRealisedPnl,
                    prevState: data.prevState, prevUnrealisedPnl: data.prevUnrealisedPnl, realisedPnl: data.realisedPnl, riskLimit: data.riskLimit,
                    riskValue: data.riskValue, sessionMargin: data.sessionMargin, state: data.state, syntheticMargin: data.syntheticMargin,
                    targetExcessMargin: data.targetExcessMargin, taxableMargin: data.taxableMargin, timestamp: data.timestamp, unrealisedPnl: data.unrealisedPnl,
                    unrealisedProfit: data.unrealisedProfit, varMargin: data.varMargin, walletBalance: data.walletBalance, withdrawableMargin: data.withdrawableMargin }
                    margin=margin.compact 
                    @data[:margin] = margin
            end
            if data.clOrdID 
                if data.clOrdID.include?('Tracking') and data.symbol != nil and data.price != nil
                    @data[:orders].each do |y|
                        if y[:Id] == data.clOrdID 
                            y[:Price] = data.price
                           # push("Updated existing order: #{y} via Amend!")
                        end
                    end
                end
            end
            if data.channelID == 1 and $settings_chat
                push("Bitmex chat| #{data.user}: #{data.message}")

            elsif data.ordStatus == "New" or data.ordStatus == "Canceled" or data.ordStatus == "Filled"
                if data.clOrdID == "" or nil
                    data.clOrdID = "manual_order"
                end
                ord=nil
                tmp=[]
                if data.ordStatus == "New"
                    ord={ account: data.account, avgPx: data.avgPx, clOrdID: data.clOrdID, clOrdLinkID: data.clOrdLinkID, contingencyType: data.contingencyType, cumQty: data.cumQty,
                    currency: data.currency, displayQty: data.displayQty, exDestination: data.exDestination, execInst: data.execInst, leavesQty: data.leavesQty,
                    multiLegReportingType: data.multiLegReportingType, ordRejReason: data.ordRejReason, ordStatus: data.ordStatus, ordType: data.ordType, orderID: data.orderID,
                    orderQty: data.orderQty, pegOffsetValue: data.pegOffsetValue, pegPriceType: data.pegPriceType, price: data.price, settlCurrency: data.settlCurrency,
                    side: data.side, simpleCumQty: data.simpleCumQty, simpleLeavesQty: data.simpleLeavesQty, simpleOrderQty: data.simpleOrderQty, stopPx: data.stopPx, symbol: data.symbol,
                    text: data.text, timeInForce: data.timeInForce, timestamp: data.timestamp, transactTime: data.transactTime, triggered: data.triggered, workingIndicator: data.workingIndicator }                
                elsif data.ordStatus == "Canceled"
                    ord={ account: data.account, clOrdID: data.clOrdID, leavesQty: data.leavesQty, ordStatus: data.ordStatus, orderID: data.orderID, symbol: data.symbol, text: data.text,
                    timestamp: data.timestamp, workingIndicator: data.workingIndicator }           
                elsif data.ordStatus == "Filled"
                    ord={ account: data.account, avgPx: data.avgPx, clOrdID: data.clOrdID, cumQty: data.cumQty, leavesQty: data.leavesQty, ordStatus: data.ordStatus, orderID: data.orderID,
                    symbol: data.symbol, timestamp: data.timestamp, workingIndicator: data.workingIndicator }
                end
                if ord[:ordType] == "Limit"
                    push("Found! #{ord[:ordType]} order with id #{ord[:clOrdID][-12,12]} side: #{ord[:side]} @ #{ord[:price]} x #{ord[:leavesQty]}")
                    limit={ Type: ord[:ordType], Id: ord[:clOrdID], Side: ord[:side], Price: ord[:price], Num: ord[:leavesQty] }
                    @data[:orders].each do |x|
                        tmp << x[:clOrdID]
                    end
                    @data[:orders] << limit unless tmp.include?(ord[:clOrdID])
                elsif ord[:ordType] == "Stop"
                    push("Found! #{ord[:ordType]}  order with id #{ord[:clOrdID][-12,12]} side: #{ord[:side]} @ #{ord[:stopPx]} x #{ord[:leavesQty]}")
                    stop={ Type: ord[:ordType], Id: ord[:clOrdID], Side: ord[:side], Price: ord[:stopPx], Num: ord[:leavesQty] }
                    @data[:orders].each do |x|
                        tmp << x[:clOrdID]
                    end
                    @data[:orders] << stop unless tmp.include?(ord[:clOrdID])         
                elsif ord[:ordStatus] == "Filled"
                    @data[:orders].delete_if { |h| h[:Id] == data.clOrdID }
                    if data.clOrdID[11..19].include?('limit')
                        push("Filled limitorder! Id# #{data.clOrdID[-12,12]}.")
                    elsif data.clOrdID[11..19].include?('stop')
                        push("Stop triggerd! Id# #{data.clOrdID[-12,12]}.")
                    end
                elsif ord[:ordStatus] == "Canceled"
                    @data[:orders].delete_if { |h| h[:Id] == data.clOrdID }
                    if data.clOrdID[11..19].include?('limit')
                        push("Canceled limitorder! Id# #{data.clOrdID[-12,12]}.")
                    elsif data.clOrdID[11..19].include?('stop')
                        push("Canceled stop! Id# #{data.clOrdID[-12,12]}.")
                    end
                else
                    push("Error! Probally made a manual order. If so ignore this..")
                end
            elsif data.account and data.currentQty and data.timestamp
                pos=nil
                pos={ account: data.account, avgCostPrice: data.avgCostPrice, avgEntryPrice: data.avgEntryPrice, bankruptPrice: data.bankruptPrice, breakEvenPrice: data.breakEvenPrice, currency: data.currency, currentComm: data.currentComm, currentCost: data.currentCost, currentQty: data.currentQty,
                    currentTimestamp: data.currentTimestamp, execBuyCost: data.execBuyCost, execBuyQty: data.execBuyQty, execComm: data.execComm, execCost: data.execCost, execQty: data.execQty, foreignNotional: data.foreignNotional, grossExecCost: data.grossExecCost, grossOpenCost: data.grossOpenCost,
                    homeNotional: data.homeNotional, initMargin: data.initMargin, lastValue: data.lastValue, liquidationPrice: data.liquidationPrice, maintMargin: data.maintMargin, marginCallPrice: data.marginCallPrice, markPrice: data.markPrice, markValue: data.markValue, posComm: data.posComm,
                    posCost: data.posCost, posCost2: data.posCost2, posInit: data.posInit, posMaint: data.posMaint, posMargin: data.posMargin, realisedPnl: data.realisedPnl, riskValue: data.riskValue, symbol: data.symbol, unrealisedCost: data.unrealisedCost, unrealisedGrossPnl: data.unrealisedGrossPnl,
                    unrealisedPnl: data.unrealisedPnl, unrealisedRoePcnt: data.unrealisedRoePcnt }
                pos=pos.compact 
                x=@data[:position][:currentQty]
                z=data.currentQty
                if x !=  z
                    push("Position updated to: #{data.currentQty} from #{@data[:position][:currentQty]}")
                end
                pos.each do |k,v|
                    @data[:position][k] = v
                end
            elsif (data.homeNotional and data.side and data.symbol and data.price) != nil and $settings_live_trades
                if data.price
                    $last_global_trade = data.price
                end
                #display=("Live trades| timestamp: #{data.timestamp} symbol: #{data.symbol} side: #{data.side} #{data.homeNotional} #{data.symbol} @ #{data.price}")
                dollar=(data.homeNotional.abs * data.price) #timestamp: #{data.timestamp}
                push("Filterd tradealert! | symbol: #{data.symbol} side: #{data.side} $#{dollar.round(2)} #{data.symbol} @ #{data.price}") if data.homeNotional > $settings_live_trigger_size.to_i
                if (data.homeNotional and data.symbol and data.price) != nil and $settings_marketflow
                    if data.side == 'Buy' 
                        $flow=$flow + data.homeNotional
                    else
                        $flow=$flow - data.homeNotional
                    end
                    push("Live motioncounter | BTC | #{$flow}") if $settings_live_flow
                end       
            elsif (data.leavesQty and data.price) != nil 
            push("REKTALABAMA | CONTRACTS REKT | #{data.side} #{data.leavesQty} @ #{data.price} :D:D:D:D:D ! RIP")
            else
            #p data #for debugg
            end    
        end
    end
    def reset(type='all')#resets autotrading orders but not manual orders
        if type == 'all'
            @data[:orders].each do |z|
                a=z[:Id]
                b=z[:Type]
                c=z[:Side]
                if a.start_with?("TrackingId")
                    order = @client.order(clOrdID: a).cancel
                    push("  ->  Deleting order with ID: " + a[-12,12] + " Type: " + b + " Direction: " + c + " ")
                    sleep 1
                end
            end
        elsif type == 'sell'
            @data[:orders].each do |z|
                a=z[:Id]
                b=z[:Type]
                c=z[:Side]
                if a.start_with?("TrackingId") and c == 'Sell'
                    order = @client.order(clOrdID: a).cancel
                    push("  ->  Deleting order with ID: " + a[-12,12] + " Type: " + b + " Direction: " + c + " ")
                end
            end
        elsif type == 'buy'
            @data[:orders].each do |z|
                a=z[:Id]
                b=z[:Type]
                c=z[:Side]
                if a.start_with?("TrackingId") and c == 'Buy'
                    order = @client.order(clOrdID: a).cancel
                    push("  ->  Deleting order with ID: " + a[-12,12] + " Type: " + b + " Direction: " + c + " ")
                end
            end
        else
            push("Error! Not a supported reset parameter.")
        end
    end
    def ordercheck #here you can put custom tradestyles
        brain
    end
    def send_cmd
        if $settings_send_cmd
            file = File.open("send_command.txt")
            file_data = file.readlines.map(&:chomp)
            file.close
            file_data.each do |x|
                if x.include?("$max_leverage=")
                    z=x.split('=',2).last.to_i
                    $max_leverage=z
                elsif x.include?("$amount_to_trade=")
                    z=x.split('=',2).last.to_i
                    $amount_to_trade=z
            
                elsif x.include?("$display_info_timer=")
                    z=x.split('=',2).last.to_i
                    $display_info_timer=z
                else
                    p "Not a valid command."
                end
            end    
        end    
    end
    def selfcheck#what runs every mainloop to check all is allright 
        $amount_to_trade = (@data[:margin][:marginBalance]/100000) if @data[:margin][:marginBalance] > 100000
        if @counter<=0
            send_cmd
            @counter=$display_info_timer * 15 * 3
            push("Current position: " + @data[:position][:currentQty].to_s + " avg entry @ " + @data[:position][:avgEntryPrice].to_s ) if @data[:position][:currentQty] != 0
            push("Current leverage: " + @data[:margin][:marginLeverage].round(2).to_s + "x. Maximum leverage: " + $max_leverage.to_s + "x." ) if @data[:position][:currentQty] != 0
            push("Position unrealised profit/loss: #{(@data[:position][:unrealisedRoePcnt]*100).round(2)}%") if @data[:position][:currentQty] != 0
            push("Position unrealised profit/loss BTC: #{@data[:position][:unrealisedPnl]}") if @data[:position][:currentQty] != 0
            push("Total position profits @ BTC: #{@data[:position][:realisedPnl].to_f/100000000.round(8)}") if @data[:position][:currentQty] != 0
            push("Balance: #{@data[:margin][:marginBalance].to_f/100000000.round(8)} BTC")
            push("Available margin: #{@data[:margin][:availableMargin].to_f/100000000.round(8)} BTC") 
            push("Current Price @ #{$symbol + ": "+$last_global_trade.to_s} $")
            push("Since #{@start} People have traded: #{$flow.round(4)} +/- BTC")
            if @data[:orders].length > 0
                push"Current active orders: "
                @data[:orders].each do |z|
                    a=z[:Id]
                    b=z[:Type]
                    c=z[:Side]
                    d=z[:Price]
                    y=z[:Num]
                    puts "  ->  ID: " + a[-12,12] + " Type: " + b + " Direction: " + c + " @ " + d.to_s + " x " + y.to_s + " "
                end 
            end
            #reset 
        push("______________________________________________________________________________")
        end
        @counter-=1        
        ordercheck 
        sleep 1
    end
end

##initiating stuffs 
ws = BitmexWebsocket.new
x = 0 #times
run = true
arr=[]
data={}
listen_thread=nil
Thread.abort_on_exception=true
listen_thread=Thread.new { ws.listen }
sleep 3
puts""
ws.push("______________________________________________________________________________")
while run#mainloop
    begin
        if not listen_thread.alive?
            ws.push("Mainthread running? " +  listen_thread.alive?.to_s) if not listen_thread.alive?
            listen_thread=Thread.new { ws.listen }
            sleep 15
        end
        ws.selfcheck if listen_thread.alive?
        sleep 0.5 if not listen_thread.alive?
    rescue Exception => e
        puts "Error Occured!"
       # puts e.inspect
       # puts e.message
        if e.message.include? 'certificate has expired'
            ws.push("Resetting websocket connection since certificate has expired")
            sleep 15
            ws.data[:orders] = []
            Thread.kill(listen_thread)
        elsif e.message.include? 'Not Found'
            ws.push("Resetting websocket connection since it died (Not Found)")
            sleep 15
            ws.data[:orders] = []
            Thread.kill(listen_thread)
        elsif e.message.include? 'The system is currently overloaded. Please try again later.'
            ws.push('BITMEX: The system is currently overloaded. Please try again later.')
            #ws.data[:orders] = []
        elsif e.message.include? 'ValidationError'
            sleep 15
            Thread.kill(listen_thread)
            ws.data[:orders] = []
            ws.push("Resetting websocket connection since ValidationError")
        else
            ws.push("Resetting all autotrading orders.")
            ws.reset
            ws.push("Exiting and killing thread")
            Thread.kill(listen_thread)
            p e.message
            exit
        end
        sleep 3
       #p e
        #run=false# if x >49 
    end
end
