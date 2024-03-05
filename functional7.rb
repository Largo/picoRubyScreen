puts "start"

require 'spi'
require 'gpio'

# Display resolution
EPD_WIDTH  = 128
EPD_HEIGHT = 296

# Display commands
DRIVER_OUTPUT_CONTROL                = 0x01
BOOSTER_SOFT_START_CONTROL           = 0x0C
DEEP_SLEEP_MODE                      = 0x10
DATA_ENTRY_MODE_SETTING              = 0x11
MASTER_ACTIVATION                    = 0x20
DISPLAY_UPDATE_CONTROL_2             = 0x22
WRITE_RAM                            = 0x24
WRITE_VCOM_REGISTER                  = 0x2C
WRITE_LUT_REGISTER                   = 0x32
SET_DUMMY_LINE_PERIOD                = 0x3A
SET_GATE_TIME                        = 0x3B
SET_RAM_X_ADDRESS_START_END_POSITION = 0x44
SET_RAM_Y_ADDRESS_START_END_POSITION = 0x45
SET_RAM_X_ADDRESS_COUNTER            = 0x4E
SET_RAM_Y_ADDRESS_COUNTER            = 0x4F
TERMINATE_FRAME_READ_WRITE           = 0xFF

BUSY = 1  # 1=busy, 0=idle

# LUTs
LUT_FULL_UPDATE    = [0x02, 0x02, 0x01, 0x11, 0x12, 0x12, 0x22, 0x22, 0x66, 0x69, 0x69, 0x59, 0x58, 0x99, 0x99, 0x88, 0x00, 0x00, 0x00, 0x00, 0xF8, 0xB4, 0x13, 0x51, 0x35, 0x51, 0x51, 0x19, 0x01, 0x00]
LUT_PARTIAL_UPDATE = [0x10, 0x18, 0x18, 0x08, 0x18, 0x18, 0x08, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x13, 0x14, 0x44, 0x12, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00]

# Define GPIO constants
GPIO_OUT = :out
GPIO_IN = :in

# Initialize GPIO pins
dc = GPIO.new(8, GPIO_OUT)
cs = GPIO.new(9, GPIO_OUT)
rst = GPIO.new(12, GPIO_OUT)
busy = GPIO.new(13, GPIO_IN)

# Set the GPIO pin states
cs.write(1)
dc.write(0)
rst.write(0)
busy.read

# Initialize SPI
spi = SPI.new(unit: :RP2040_SPI0, frequency: 100_000, mode: 0, cs_pin: 9, sck_pin: 10, copi_pin: 11)

def command(spi, cs, dc, command, data = nil)
  dc.write(0)
  cs.write(0)
  spi.write([command])
  cs.write(1)
  data(spi, cs, dc, data) if data
end

def data(spi, cs, dc, data)
  dc.write(1)
  cs.write(0)
  spi.write(data)
  cs.write(1)
end

def wait_until_idle(busy)
  sleep_ms(100) while busy.read == BUSY
end

def reset(rst)
  rst.write(0)
  sleep_ms(200)
  rst.write(1)
  sleep_ms(200)
end

# Initialize the e-paper display
reset(rst)
command(spi, cs, dc, DRIVER_OUTPUT_CONTROL, [EPD_HEIGHT - 1, 0x00].pack('C*'))
command(spi, cs, dc, BOOSTER_SOFT_START_CONTROL, [0xD7, 0xD6, 0x9D].pack('C*'))
command(spi, cs, dc, WRITE_VCOM_REGISTER, [0xA8].pack('C*'))
command(spi, cs, dc, SET_DUMMY_LINE_PERIOD, [0x1A].pack('C*'))

def set_lut(spi, cs, dc, lut)
  command(spi, cs, dc, WRITE_LUT_REGISTER, lut.pack('C*'))
end

def set_frame_memory(spi, cs, dc, image, x, y, w, h, width, height)
  x &= 0xF8
  w &= 0xF8
  x_end = (x + w >= width) ? width - 1 : x + w - 1
  y_end = (y + h >= height) ? height - 1 : y + h - 1

  set_memory_area(spi, cs, dc, x, y, x_end, y_end)
  set_memory_pointer(spi, cs, dc, x, y)
  command(spi, cs, dc, WRITE_RAM, image.pack('C*'))
end

def clear_frame_memory(spi, cs, dc, color, width, height)
  set_memory_area(spi, cs, dc, 0, 0, width - 1, height - 1)
  set_memory_pointer(spi, cs, dc, 0, 0)
  command(spi, cs, dc, WRITE_RAM)
  (0...(width / 8 * height)).each do |_|
    data(spi, cs, dc, [color].pack('C*'))
  end
end

def display_frame(spi, cs, dc)
  command(spi, cs, dc, DISPLAY_UPDATE_CONTROL_2, [0xC4].pack('C*'))
  command(spi, cs, dc, MASTER_ACTIVATION)
  command(spi, cs, dc, TERMINATE_FRAME_READ_WRITE)
  wait_until_idle(busy)
end

def set_memory_area(spi, cs, dc, x_start, y_start, x_end, y_end)
  command(spi, cs, dc, SET_RAM_X_ADDRESS_START_END_POSITION)
  data(spi, cs, dc, [x_start >> 3, x_end >> 3].pack('C*'))
  command(spi, cs, dc, SET_RAM_Y_ADDRESS_START_END_POSITION, [y_start, y_end].pack('S*'))
end

def set_memory_pointer(spi, cs, dc, x, y)
  command(spi, cs, dc, SET_RAM_X_ADDRESS_COUNTER)
  data(spi, cs, dc, [(x >> 3)].pack('C*'))
  command(spi, cs, dc, SET_RAM_Y_ADDRESS_COUNTER, [y].pack('S*'))
  wait_until_idle(busy)
end

puts "bla"

# def sleep(spi, cs, dc)
#   command(spi, cs, dc, DEEP_SLEEP_MODE)
#   wait_until_idle(busy)
# end

w = 128
h = 296
x = 0
y = 0

#clear_frame_memory(spi, cs, dc, b'\xFF', EPD_WIDTH, EPD_HEIGHT)
#set_frame_memory(spi, cs, dc, hello_world_dark, x, y, w, h)
#display_frame(spi, cs, dc)