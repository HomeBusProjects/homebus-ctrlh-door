require 'homebus'
require 'homebus_app'
require 'summer'
require 'mqtt'
require 'json'

class DoorBot < Summer::Connection
  def initialize(callback)
    @callback = callback

    super('irc.freenode.net')
  end

  def channel_message(sender, channel, message)
    @callback.call(sender, channel, message)
  end
end

class DoorHomeBusApp < HomeBusApp
  def initialize(options)
    @options = options

    super
  end



  def setup!
  end

  def work!
    @irc = DoorBot.new(lambda {|sender, channel, message| self.irc_message(sender, channel, message); })
  end

  def irc_message(sender, channel, message)
    puts "got a message #{message}"

    obj = {}

    # May 9 11:51:09 Isaac P. has opened unit2 front door
    obj = case message
    when /(\S+ \S\.) has (\S+) (unit\d) (\S+ door)/
      { id: @uuid,
        timestamp: Time.now.to_i,
        access: {
          person: $1,
          action: $2,
          unit: $3,
          door: $4
        }
      }
    when /(\S+ \S\.) has (\S+) (front craft lab)/
      { id: @uuid,
        timestamp: Time.now.to_i,
        access: {
          person: $1,
          action: $2,
          unit: 'unit3',
          door: $3
        }
      }
    when /(front craft lab) (\S+) by (\S+ \S\.)/
      { id: @uuid,
        timestamp: Time.now.to_i,
        access: {
          person: $3,
          action: $2,
          unit: 'unit3',
          door: $1
        }
      }
    # "May 16 21:35:39 unit2 front door locked by John R."
    when /(unit\d) (\S+ door) (\S+) by (\S+ \S\.)/
      { id: @uuid,
        timestamp: Time.now.to_i,
        access: {
          person: $4,
          action: $3,
          unit: $1,
          door: $2
        }
      }
    else
      obj = { id: @uuid,
              timestamp: Time.now.to_i,
              access: {
                message: message
              }
            }
    end

    # messages look like "FIRSTNAME INITIAL. has opened unit3 back door"
    # parse them into "(PERSON) has (VERBED) (DOOR)"
    # may also look like "unit3 access control is online"
    @mqtt.publish "/door", JSON.generate(obj), true
  end

  def manufacturer
    'HomeBus'
  end

  def model
    'D'
  end

  def friendly_name
    'Door activity'
  end

  def friendly_location
    'PDX Hackerspace'
  end

  def serial_number
    ''
  end

  def pin
    ''
  end

  def devices
    [
      { friendly_name: 'Who goes there',
        friendly_location: 'PDX Hackerspace',
        update_frequency: 60,
        index: 0,
        accuracy: 0,
        precision: 0,
        wo_topics: [ 'door' ],
        ro_topics: [],
        rw_topics: []
      }
    ]
  end
end
