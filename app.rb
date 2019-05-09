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

    # May 9 11:51:09 Isaac P. has opened unit2 front door
    m = message.match /(\S+ \S\.) has (\S+) (unit\d) (\S+ door)/
    if m && m[1] && m[2] && m[3] && m[4]
      obj = { id: @uuid,
              timestamp: Time.now.to_i,
              person: m[1],
              action: m[2],
              unit: m[3],
              door: m[4]
            }
    else
      obj = { id: @uuid,
              timestamp: Time.now.to_i,
              message: message
            }
    end

    # messages look like "FIRSTNAME INITIAL. has opened unit3 back door"
    # parse them into "(PERSON) has (VERBED) (DOOR)"
    # may also look like "unit3 access control is online"
    @mqtt.publish "/door", JSON.generate(obj)
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
