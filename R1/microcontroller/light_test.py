import board
import busio
import adafruit_tlc59711
import digitalio
import time

class LightTest:

     def __init__(self):
        print(dir(board))
        button = digitalio.DigitalInOut(board.D10)
        button.direction = digitalio.Direction.INPUT
        button.pull = digitalio.Pull.UP

        spi = busio.SPI(board.SCK, MOSI=board.MOSI)
        leds = adafruit_tlc59711.TLC59711(spi)

        button_count = 4
        button_index = 0


        while True:
            button_index += 1
            if button_index >= button_count:
                button_index = 0

            leds[button_index] = (60000,60000,60000)

            time.sleep(0.5)

            color_index = 0
            while color_index < 3:
                for button in range(button_count):
                    if color_index == 0:
                        leds[button] = (60000,0,0)
                    elif color_index == 1:
                        leds[button] = (0,60000,0)
                    else:
                        leds[button] = (0,0,60000)

                color_index += 1
                time.sleep(0.75)
