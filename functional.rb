require 'spi'
require 'gpio'

@spi = SPI.new(unit: :RP2040_SPI0, frequency: 100_000, mode: 0, cs_pin: 9, sck_pin: 10, copi_pin: 11)
@dc = GPIO.new(8, GPIO::OUT)
@busy = GPIO.new(13, GPIO::IN)

def wait_until_ready(busy_pin)
    do
        sendCommand(0x71)
        sleep_ms(200) # first time dont 
    while busy_pin.read == 1
end

def sendCommand(command)
  @dc.write(0)
  @spi.select
  @spi.write(command)
  @spi.deselect
end

def sendData(data)
  @dc.write(1)
  @spi.select
  @spi.write(data)
  @spi.deselect
end

def reset
    @rst.write(0) # Reset the display
    sleep_ms(200) # Wait for 200ms
    @rst.write(1) # Release the reset
    sleep_ms(200) # Wait for 200ms
end

reset

# init 

sendCommand(0x01)
sendData(0x03)
sendData(0x00)
sendData(0x2b)
sendData(0x2b)
sendData(0x03)
sendCommand(0x06)
sendData(0x17)
sendData(0x17)
sendData(0x17)

sendCommand(0x04)


# Reset and initialize display is skipped here, assuming it's done already
wait_until_ready(busy)


sendCommand(0x00)
sendData(0xbf)
sendData(0x0e)

sendCommand(0x30)
sendData(0x3a)

sendCommand(0x61)

EPD_2IN9D_WIDTH = 128
EPD_2IN9D_HEIGHT = 296
sendData(EPD_2IN9D_WIDTH)
sendData((EPD_2IN9D_HEIGHT >> 8) & 0xff)
sendData(EPD_2IN9D_HEIGHT & 0xff)

sendCommand(0x82)
sendData(0x28)

# clear

#sendCommand(0x10)

sleep_ms 500

# Example: just to illustrate sending the data
rectangle_data = Array.new(50, 0x00)
send_data(spi, dc, rectangle_data)
wait_until_ready(busy)

puts busy.read
puts "drew rectangle"

