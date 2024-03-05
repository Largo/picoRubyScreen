

spi = SPI.new(unit: :RP2040_SPI0, frequency: 100_000, mode: 0, cs_pin: 9,
                sck_pin: 10, copi_pin: 11
                )
@dc = GPIO.new(8, GPIO::OUT)
@rst = GPIO.new(12, GPIO::OUT)
@busy = GPIO.new(13, GPIO::IN)

# Function to reset the e-paper display
def reset
    @rst.write(0) # Reset the display
    sleep_ms(200) # Wait for 200ms
    @rst.write(1) # Release the reset
    sleep_ms(200) # Wait for 200ms
  end

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
  def send_data(data)
    @dc.write(1) # Data mode
    @spi.select
    @spi.write(data)
    @spi.deselect
  end
  reset