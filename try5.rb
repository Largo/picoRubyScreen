require 'spi'
require 'gpio'

# Assume the following class is part of a library you are using
class EPaperDisplay
  # Initialize the e-paper display with the Raspberry Pi Pico's pins based on the schematic provided
  def initialize(sck_pin:, copi_pin:, cs_pin:, dc_pin:, rst_pin:, busy_pin:)
    @spi = SPI.new(unit: :RP2040_SPI0, frequency: 100_000, mode: 0, cs_pin: cs_pin,
                   scresetk_pin: sck_pin, copi_pin: copi_pin
                  )
    @dc = GPIO.new(dc_pin, GPIO::OUT)
   #@rst = GPIO.new(rst_pin, GPIO::OUT)
    @busy = GPIO.new(busy_pin, GPIO::IN)
    #@rst.write(1) # Release the reset
    #sleep_ms(200) # Wait for 200ms

    # Initialize the pins for DC, RST, and BUSY
    #reset
  end

  # # Function to reset the e-paper display
  # def reset
  #   @rst.write(0) # Reset the display
  #   sleep_ms(200) # Wait for 200ms
  #   @rst.write(1) # Release the reset
  #   sleep_ms(200) # Wait for 200ms
  # end

  # Function to wait for the e-paper display to be ready
  def wait_until_ready
    while @busy.read == 1
      # Busy pin is high, so wait
      sleep_ms(10) # Sleep for 10ms
    end
  end

  # Function to send a command to the e-paper display
  def send_command(command)
    @dc.write(0) # Command mode
    @spi.select
    @spi.write(command)
    @spi.deselect
  end

  # Function to send data to the e-paper display
  def send_data(data)
    @dc.write(1) # Data mode
    @spi.select
    @spi.write(data)
    @spi.deselect
  end

  # Function to draw a rectangle on the e-paper display
  # You would call this after initializing and clearing the display
  def draw_rectangle(x_start, y_start, width, height, color)
    # ... The logic to create the bitmap for the rectangle goes here

    # Example: just to illustrate sending the data
    #send_command(0x10) # Example: Command to start data transfer
    rectangle_data = Array.new(2368,0x00)

    # rectangle_data = [0x00, 0x00, 0x00, 0x00]
    send_data(rectangle_data) # rectangle_data should be an array of bytes representing the rectangle
    
    #send_command(0x12) # Example: Command to refresh the display
    wait_until_ready

    puts @busy.read
  end
end

# Example usage:
# Initialize the e-paper display object with the correct pin numbers
epaper = EPaperDisplay.new(
  sck_pin: 10,
  copi_pin: 11,
  cs_pin: 9,
  dc_pin: 8,
  rst_pin: 12,
  busy_pin: 13
)

# Now you can call methods on the epaper object to control the e-paper display
epaper.draw_rectangle(20, 30, 100, 60, 0) # Draw a black rectangle

puts "drawed rectangle"