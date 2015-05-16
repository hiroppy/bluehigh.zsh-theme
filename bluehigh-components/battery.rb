#!/usr/bin/env ruby
# coding: utf-8
output = `pmset -g batt`
percent_battery = output.match(/\d+\%/).to_s.gsub("%","").to_f

empty = '🔸'
filled = '🔹'

num_filled = (percent_battery/10).ceil - 1
puts (filled * num_filled) + empty * (10 - num_filled)
