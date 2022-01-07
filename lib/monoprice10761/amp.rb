require 'io/wait'

module Monoprice10761
  class Amp
    attr_reader :zones
    attr_accessor :zone_updated_proc

    def initialize(uri)
      uri = URI.parse(uri)
      @mutex = Mutex.new
      @io = if uri.scheme == 'tcp'
        require 'socket'
        TCPSocket.new(uri.host, uri.port)
      elsif uri.scheme == 'telnet' || uri.scheme == 'rfc2217'
        require 'net/telnet/rfc2217'
        Net::Telnet::RFC2217.new(host: uri.host,
          port: uri.port || 23, baud: 9600,
          data_bits: 8,
          parity: :none,
          stop_bits: 1)
      else
        require 'ccutrer-serialport'
        CCutrer::SerialPort.new(uri.path,
          baud: 9600,
          data_bits: 8,
          parity: :none,
          stop_bits: 1)
      end

      # clear out any pending commands
      write("\r\n")

      refresh
    end

    def refresh
      write("?30\r\n")
      write("?20\r\n")
      write("?10\r\n")
    end

    COMMANDS = {
      pa: 'PA',
      power: 'PR',
      mute: 'MU',
      do_not_disturb: 'DT',
      volume: 'VO',
      treble: 'TR',
      bass: 'BS',
      balance: 'BL',
      channel: 'CH'
    }.freeze
    private_constant :COMMANDS    

    {
      pa: 'PA',
      power: 'PR',
      mute: 'MU',
      do_not_disturb: 'DT'
    }.each do |(method, command)|
      class_eval <<-RUBY, __FILE__, __LINE__ + 1
        def #{method}(zone_id, value)
          raise ArgumentError unless [true, false].include?(value)
          value = value ? 1 : 0
          write("<%d#{command}%02d\\r\\n" % [zone_id, value])
          write("?%d\\r\\n" % [zone_id])
        end
      RUBY
    end

    def balance(zone_id, value)
      raise ArgumentError unless (-10..10).include?(value)
      value += 10
      write("<%dBL%02d\r\n" % [zone_id, value])
      write("?%d\r\n" % [zone_id])
    end

    {
      volume: ['VO', 0..38],
      treble: ['TR', 0..14],
      bass: ['BS', 0..14],
      channel: ['CH', 1..6]
    }.each do |(method, (command, range))|
      class_eval <<-RUBY, __FILE__, __LINE__ + 1
        def #{method}(zone_id, value)
          value = value.to_i
          raise ArgumentError unless (#{range.inspect}).include?(value)
          write("<%d#{command}%02d\\r\\n" % [zone_id, value])
          write("?%d\\r\\n" % [zone_id])
        end
      RUBY
    end

    private

    def write(message)
      @mutex.synchronize do
        @io.write(message)
        @io.wait_readable
        read_messages
      end
    end

    def read_messages
      return unless @io.ready?

      message = ''
      loop do
        @io.wait_readable
        byte = @io.getbyte.chr

        if byte == "\n"
          got_message($1) if message =~ /^#?>(\d{22})\r\r$/
          message.clear
        elsif message.empty? && byte == '#' && !@io.ready?
          # wait for a 50ms
          break if sleep(0.05) && !@io.ready?
        else
          message << byte
        end
      end
    end

    def got_message(message)
      zone_id = message[0..1].to_i
      unless @zones
        @zones = ZoneArray.new.replace((1..(zone_id / 10)).map do |unit|
          (1..6).map do |z_id|
            Zone.new(unit * 10 + z_id, self)
          end
        end.flatten)
      end

      zone = zones.by_id(zone_id)
      zone.assign_attributes(message)
      zone_updated_proc&.call(zone)
    end
  end
end
