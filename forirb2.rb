require 'spi'
require 'gpio'

def wait_until_ready(busy_pin)
  while busy_pin.read == 1
    sleep_ms(10)
  end
end

def send_command(spi, dc, command)
  dc.write(0)
  spi.select
  spi.write(command)
  spi.deselect
end

def send_data(spi, dc, data)
  dc.write(1)
  spi.select
  spi.write(data)
  spi.deselect
end

spi = SPI.new(unit: :RP2040_SPI0, frequency: 100_000, mode: 0, cs_pin: 9, sck_pin: 10, copi_pin: 11)
dc = GPIO.new(8, GPIO::OUT)
busy = GPIO.new(13, GPIO::IN)

# Reset and initialize display is skipped here, assuming it's done already
wait_until_ready(busy)

# Example: just to illustrate sending the data
rectangle_data = Array.new(50, 0x00)
send_data(spi, dc, rectangle_data)
wait_until_ready(busy)

puts busy.read
puts "drew rectangle"







spi = SPI.new(unit: :RP2040_SPI0, frequency: 100_000, mode: 2, cs_pin: 9, sck_pin: 10, copi_pin: 11)
dc = GPIO.new(8, GPIO::OUT)
busy = GPIO.new(13, GPIO::IN)
rectangle_data = Array.new(140, 0x00)
send_data(spi, dc, rectangle_data)


spi = SPI.new(unit: :RP2040_SPI0, frequency: 100_000, mode: 3, cs_pin: 9, sck_pin: 10, copi_pin: 11)
send_data(spi, dc, rectangle_data)