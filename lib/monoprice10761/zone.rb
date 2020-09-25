module Monoprice10761
  class Zone
    attr_reader :id, :pa, :power, :mute, :do_not_disturb, :volume, :treble, :bass, :balance, :channel, :keypad_connected

    def initialize(id, owner)
      @id = id
      @owner = owner
    end

    def assign_attributes(status_line)
      parts = status_line.scan(/\d{2}/)
      raise "unrecognized status line #{status_line.inspect}" unless parts.length == 11
      # zone ID
      parts.shift
      @pa, @power, @mute, @do_not_disturb = parts[0..3].map { |xx| xx.to_i != 0 }
      @volume, @treble, @bass = parts[4..6].map(&:to_i)
      @balance = parts[7].to_i - 10
      @channel = parts[8].to_i
      @keypad_connected = parts[9].to_i != 0
    end

    def inspect
      result = "#<#{self.class.name}"
      [:pa, :power, :mute, :do_not_disturb, :volume, :treble, :bass, :balance, :channel, :keypad_connected].each do |attribute|
        result << " #{attribute}=#{send(attribute)}"
      end
      result << ">"
      result
    end

    [:pa, :power, :mute, :do_not_disturb, :volume, :treble, :bass, :balance, :channel].each do |method|
      class_eval <<-RUBY, __FILE__, __LINE__ + 1
        def #{method}=(val)
          @owner.#{method}(id, val)
          # return the current value of the attribute; if it was succesful it would have queried
          # and updated it
          #{method}
        end
      RUBY
    end
  end
end