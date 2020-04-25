#!/usr/bin/ruby
# coding: utf-8 
#
# NITLOTT PRODUCTIONS
#
def brain
    
    #here you can put custom tradestyles 

    tmp=$last_global_trade
    entry=tmp * (1 - 0.00125)
    entry=(entry*2).ceil.to_f / 2
    target1 = entry * (1 + 0.0112515644555695) #remove first 1
    target1 = (target1*2).ceil.to_f / 2
    target2 = entry * (1 + 0.0143804755944931) #remove first 1
    target2 = (target2*2).ceil.to_f / 2
    target3 = entry * (1 + 0.0175093867334168) #remove first 1
    target3 = (target3*2).ceil.to_f / 2
    stop = entry * (1 - 0.003125)
    stop = (stop*2).ceil.to_f / 2
    if @data[:orders].length < 1 and $settings_trade and @data[:position][:currentQty] == 0
        set_trade('limit',target1,-10)
        set_trade('limit',target2,-20)
        set_trade('limit',target3,-40)
        set_trade('limit',entry,70)
        set_trade('stop',stop,-70)#stop suited for a long position hence its a selloff
        #set_trade('stop',7250,1)
    else
        if @data[:orders].length > 0 and !$settings_trade
            push("Trading is turned off!") unless $settings_trade
            reset
        end
    end
end