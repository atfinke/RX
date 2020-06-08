import board
import busio
import adafruit_tlc59711
import time

from buttons import Buttons

class InputTest:

     def __init__(self):
        print(dir(board))
        buttons = Buttons([board.D9, board.D10, board.D11, board.D12])

        spi = busio.SPI(board.SCK, MOSI=board.MOSI)
        leds = adafruit_tlc59711.TLC59711(spi)

        while True:
            _ = buttons.active_states()
            states = buttons._last_states
            for index, state in enumerate(states):
                if state:
                    leds[index] = (60000,60000,60000)
                    print(index)
                else:
                    leds[index] = (0,0,60000)
            time.sleep(0.1)