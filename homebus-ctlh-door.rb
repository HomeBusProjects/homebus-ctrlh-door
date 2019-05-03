#!/usr/bin/env ruby

require './options'
require './app'

door_app_options = DoorHomeBusAppOptions.new

door = DoorHomeBusApp.new door_app_options.options
door.run!
