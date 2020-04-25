#!/usr/bin/ruby
# coding: utf-8 
#
# NITLOTT PRODUCTIONS
#
def brain
    tmp=$last_global_trade
    amount=$amount_to_trade
    entry = @data[:position][:avgEntryPrice]
    target1=tmp +2.5
    target2=tmp -2.5
    #target1=(entry +2.5) ; (target1 = (target1*2).ceil.to_f / 2) if ($last_global_trade < @data[:position][:avgEntryPrice])
    #target2=(entry -2.5) ; (target2 = (target2*2).ceil.to_f / 2) if ($last_global_trade > @data[:position][:avgEntryPrice])
    amount+=1 if amount == @data[:position][:currentQty] 
    amount+=1 if (amount*2) == @data[:position][:currentQty]

    sell_count=0   
    buy_count=0
    @data[:orders].each do |x| 
        if not x[:Id].include? "manual"
            if x[:Side] == 'Sell'
                sell_count+=1
            elsif x[:Side] == 'Buy'
                buy_count+=1
            end
        end
    end
    total_orders=sell_count + buy_count 
    if total_orders == 2
        if @data[:position][:currentQty] > 0 #long
            @data[:orders].each do |o| 
                if ((o[:Side] == 'Sell' and ((o[:Price] - @data[:position][:avgEntryPrice]) > 10)) and ($last_global_trade < @data[:position][:avgEntryPrice]))
                    target4=entry + 5
                    target4 = (target4*2).ceil.to_f / 2
                    order = @client.order(clOrdID: o[:Id]).update price: target4, orderQty: +((@data[:position][:currentQty].abs/3).ceil.round)
                    push("Ammended Sell order abit closer!")
                end
            end
        elsif @data[:position][:currentQty] < 0 #short
            @data[:orders].each do |o| 
                if ((o[:Side] == 'Buy' and (@data[:position][:avgEntryPrice] - o[:Price]) > 10) and ($last_global_trade > @data[:position][:avgEntryPrice]))
                    target4=entry - 5
                    target4 = (target4*2).ceil.to_f / 2
                    order = @client.order(clOrdID: o[:Id]).update price: target4, orderQty: ((@data[:position][:currentQty].abs/3).ceil.round)
                    #@data[:position][:currentQty].abs/3).ceil.round)
                    push("Ammended Buy order abit closer!")
                end
            end
        else
            push("Error! Order-ammend issue!")
        end
        sleep 3
    elsif total_orders < 2  #and @data[:margin][:availableMargin] > 200
        if @data[:position][:currentQty] != 0 
            if total_orders < 2 and @data[:position][:currentQty] > 0 #long
                if ($last_global_trade < @data[:position][:avgEntryPrice])
                    target1=(entry + 2.5) ; (target1 = (target1*2).ceil.to_f / 2) 
                end
                if ($last_global_trade < @data[:position][:avgEntryPrice])
                    target1=(entry +2.5) ; (target1 = (target1*2).ceil.to_f / 2)
                end
                if (amount*2) == @data[:position][:currentQty].abs
                    amount +=3
                end
                (target3=entry +5 ; target3 = (target3*2).ceil.to_f / 2)
                (set_trade('limit',target2,amount) ; total_orders+=1) if (@data[:margin][:marginLeverage] < $max_leverage and buy_count==0) # long ej tjock ingen longorder
                (set_trade('limit',target1,-amount*2) ; total_orders+=1) if ($last_global_trade > entry and sell_count==0) # short take profit
                (set_trade('limit',target3,-(@data[:position][:currentQty]/3).ceil.round) ; total_orders+=1) if ($last_global_trade < entry and sell_count==0) #short above loss
               # return
            end
            if total_orders < 2 and @data[:position][:currentQty] < 0  #short
                if ($last_global_trade > @data[:position][:avgEntryPrice])
                    target2=(entry +2.5) ; (target2 = (target2*2).ceil.to_f / 2)
                end
                if ($last_global_trade < @data[:position][:avgEntryPrice])
                    target1=(entry +2.5) ; (target1 = (target1*2).ceil.to_f / 2)
                end
                if (amount*2) == @data[:position][:currentQty].abs
                    amount +=3
                end
                (target4=entry -5 ; target4 = (target4*2).ceil.to_f / 2)
                (set_trade('limit',target1,-amount) ; total_orders+=1) if (@data[:margin][:marginLeverage] <= $max_leverage and sell_count==0) # short ej tjock ingen shortorder
                (set_trade('limit',target2,amount*2) ; total_orders+=1) if ($last_global_trade < entry and buy_count==0) #buy take profit
                (set_trade('limit',target4,(@data[:position][:currentQty]/3).ceil.round.abs) ; total_orders+=1) if ($last_global_trade > entry and buy_count==0) #long above loss
            end
        end
        if total_orders == 0 
            set_trade('limit',target1,-amount) if @data[:margin][:marginLeverage] < $max_leverage and sell_count==0
            set_trade('limit',target2,amount) if @data[:margin][:marginLeverage] < $max_leverage and buy_count==0
        end
        sleep 3
    end
    sleep 3
    
end