require 'spi'
require 'gpio'

# Display resolution
EPD_WIDTH  = 128
EPD_HEIGHT = 296

# Display commands
DRIVER_OUTPUT_CONTROL = 0x01
BOOSTER_SOFT_START_CONTROL = 0x0C
DEEP_SLEEP_MODE = 0x10
DATA_ENTRY_MODE_SETTING = 0x11
MASTER_ACTIVATION = 0x20
DISPLAY_UPDATE_CONTROL_2 = 0x22
WRITE_RAM = 0x24
WRITE_VCOM_REGISTER = 0x2C
WRITE_LUT_REGISTER = 0x32
SET_DUMMY_LINE_PERIOD = 0x3A
SET_GATE_TIME = 0x3B
SET_RAM_X_ADDRESS_START_END_POSITION = 0x44
SET_RAM_Y_ADDRESS_START_END_POSITION = 0x45
SET_RAM_X_ADDRESS_COUNTER = 0x4E
SET_RAM_Y_ADDRESS_COUNTER = 0x4F
TERMINATE_FRAME_READ_WRITE = 0xFF

BUSY = 1  # 1=busy, 0=idle

LUT_FULL_UPDATE    = [0x02, 0x02, 0x01, 0x11, 0x12, 0x12, 0x22, 0x22, 0x66, 0x69, 0x69, 0x59, 0x58, 0x99, 0x99, 0x88, 0x00, 0x00, 0x00, 0x00, 0xF8, 0xB4, 0x13, 0x51, 0x35, 0x51, 0x51, 0x19, 0x01, 0x00]
LUT_PARTIAL_UPDATE = [0x10, 0x18, 0x18, 0x08, 0x18, 0x18, 0x08, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x13, 0x14, 0x44, 0x12, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00]

@dc = GPIO.new(8, GPIO::OUT)
@cs = GPIO.new(9, GPIO::OUT)
@rst = GPIO.new(12, GPIO::OUT)
@busy = GPIO.new(13, GPIO::IN|GPIO::PULL_UP)

@cs.write(1)
@dc.write(0)
@rst.write(0)
@busy.read

# Initialize SPI
@spi = SPI.new(unit: :RP2040_SPI1, frequency: 4000_000, mode: 0, cs_pin: 9, sck_pin: 10, copi_pin: 11)

sleep_ms(500)

def turnOnDisplay
  command(0x22)
  data(0xC7)
  command(0x20)
  wait_until_idle
end

def command(command, data = nil)
  #puts "command " + command.to_s
  @dc.write(0)
  @cs.write(0)
  @spi.write([command])
  @cs.write(1)
  data(data) if data
end

def data(data)
  @dc.write(1)
  @cs.write(0)
  @spi.write(data)
  @cs.write(1)
end

def wait_until_idle
  puts "epaper busy"
  sleep_ms(10) while @busy.read == BUSY
  puts "epaper release"
end

def reset
  @rst.write(1)
  sleep_ms(50)
  @rst.write(0)
  sleep_ms(2)
  @rst.write(1)
  sleep_ms(50)
end

# Initialize the e-paper display
puts "prereset"
reset
puts "reset"
command(DRIVER_OUTPUT_CONTROL, [EPD_HEIGHT - 1, 0x00])
command(BOOSTER_SOFT_START_CONTROL, [0xD7, 0xD6, 0x9D])
command(WRITE_VCOM_REGISTER, [0xA8])
command(SET_DUMMY_LINE_PERIOD, [0x1A])

def set_lut(lut)
  command(WRITE_LUT_REGISTER, lut)
end



def set_frame_memory(image, x, y, w, h, width, height)
  x &= 0xF8
  w &= 0xF8
  x_end = (x + w >= width) ? width - 1 : x + w - 1
  y_end = (y + h >= height) ? height - 1 : y + h - 1

  set_memory_area(x, y, x_end, y_end)
  set_memory_pointer(x, y)
  command(WRITE_RAM, image)
end

def clear_frame_memory(color, width, height)
  set_memory_area(0, 0, width - 1, height - 1)
  set_memory_pointer(0, 0)
  command(WRITE_RAM)
  (0...(width / 8 * height)).each do |_|
    data([color])
  end
end

def display_frame()
  command(DISPLAY_UPDATE_CONTROL_2, [0xC7])
  command(MASTER_ACTIVATION)
  command(TERMINATE_FRAME_READ_WRITE)
  wait_until_idle
end

def set_memory_area(x_start, y_start, x_end, y_end)
  command(SET_RAM_X_ADDRESS_START_END_POSITION)
  data([x_start >> 3, x_end >> 3])
  command(SET_RAM_Y_ADDRESS_START_END_POSITION, [y_start, y_end])
end

def set_memory_pointer(x, y)
  command(SET_RAM_X_ADDRESS_COUNTER)
  data([(x >> 3)])
  command(SET_RAM_Y_ADDRESS_COUNTER, [y])
  wait_until_idle
end

puts "bla"

# def sleep()
#   command(DEEP_SLEEP_MODE)
#   wait_until_idle(busy)
# end

w = 128
h = 296
x = 0
y = 0

clear_frame_memory(0xFF, EPD_WIDTH, EPD_HEIGHT)
#set_frame_memory(hello_world_dark, x, y, w, h, EPD_WIDTH, EPD_HEIGHT)
display_frame()