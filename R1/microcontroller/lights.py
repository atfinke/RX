import board
import busio

import adafruit_tlc59711
from helpers import white_tuple_array

class Lights:

    def __init__(self):
        self.open_color = white_tuple_array()
        self.resting_color = white_tuple_array()
        self.pressed_color = white_tuple_array()

        spi = busio.SPI(board.SCK, MOSI=board.MOSI)
        self.leds = adafruit_tlc59711.TLC59711(spi)
        self.update_to_open_color()

    def update_open_color(self, color):
        self.open_color = color

    def update_resting_color(self, color):
        self.resting_color = color

    def update_pressed_color(self, color):
        self.pressed_color = color

    def update_to_open_color(self):
        self._update_to_color(self.open_color)

    def _update_to_color(self, color):
        for i in range(4):
            self.leds[i] = color[i]
















