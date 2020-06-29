import board
import busio
import adafruit_tlc59711
import digitalio
import time

class DebugMode:

     def __init__(self, buttons, led_order):
        print(dir(board))

        spi = busio.SPI(board.SCK, MOSI=board.MOSI)
        leds = adafruit_tlc59711.TLC59711(spi)

        button_count = 4
        white_button_index = 0

        while True:
            white_button_index += 1
            if white_button_index >= button_count:
                white_button_index = 0

            leds[led_order[white_button_index]] = (60000,60000,60000)

            time.sleep(0.5)

            color_index = 0
            while color_index < 3:
                for button in range(button_count):
                    if color_index == 0:
                        leds[led_order[button]] = (60000,0,0)
                    elif color_index == 1:
                        leds[led_order[button]] = (0,60000,0)
                    else:
                        leds[led_order[button]] = (0,0,60000)

                color_index += 1
                time.sleep(0.75)

            any_on = False
            _, states = buttons.states()
            for index, state in enumerate(states):
                if state:
                    leds[led_order[index]] = (0,0,0)
                    any_on = True

            if any_on:
                time.sleep(1)