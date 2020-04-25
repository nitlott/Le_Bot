#!/usr/bin/ruby
# coding: utf-8 
# 
# NITLOTT PRODUCTIONS
#
#Required
$api_key = ""#mainnet apikey
$api_secret = ""#mainnet secret
$tapi_key = ""#testnet apikey
$tapi_secret = ""#testnet secret
$symbol = 'XBTUSD'#symbol
$settings_testnet = true #or false just set correct keys above first!
$max_leverage=2.5#it will stop trade above this level
$amount_to_trade=1#startinglevel (will autoincrease by itself after balance so no point of changing atm)
$display_info_timer=10#timer for when info is displayed

#optional
$settings_chat = true#trollbox tunneld to terminal on/off
$settings_trade = true#no use atm
$settings_send_cmd = false#enables ability to send few cmds in send_command.txt

$settings_marketflow = true#might increase performance to turn this off never tried since i like it
$settings_live_trades = true#list trades based on size below
$settings_live_trigger_size = 10#size for trades to be listed in terminal
$settings_live_flow = false#see live how flownumber changes
$settings_live_flow_debug = false

#dont touch
$flow = 0