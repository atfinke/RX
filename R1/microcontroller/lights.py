import board
import busio

import adafruit_tlc59711
from helpers import white_tuple_array, lerp_tuple_arrays

class Lights:

    def __init__(self, light_order):
        self._light_order = light_order
        self._light_count = len(light_order)
        assert(self._light_count <= 4)

        self._last_resting_colors = white_tuple_array(self._light_count)
        self._resting_colors = white_tuple_array(self._light_count)
        self._pressed_colors = white_tuple_array(self._light_count)

        spi = busio.SPI(board.SCK, MOSI=board.MOSI)
        self._leds = adafruit_tlc59711.TLC59711(spi, auto_show=False)

    # RESTING COLORS

    def start_transition_to_new_resting_colors(self, new_colors):
        self._last_resting_colors = self._resting_colors
        self._resting_colors = new_colors

    def update_transition_to_new_resting_colors_progress(self, progress):
        inital = self._last_resting_colors
        final = self._resting_colors
        lerp = lerp_tuple_arrays(inital, final, min(progress, 1))
        self._update_lights_to_colors(lerp)

    # PRESSED COLORS

    def update_pressed_colors(self, new_colors):
        self._pressed_colors = new_colors

    def update_button_state(self, index, is_on):
        color = self._pressed_colors[index] if is_on else self._resting_colors[index]
        self._leds[self._light_order[index]] = color
        self._leds.show()

    # HELPERS

    def _update_lights_to_colors(self, colors):
        for index, color in enumerate(colors):
            self._leds[self._light_order[index]] = color
        self._leds.show()

    def set_to_colors_tuple(self, colors_tuple):
        colors = []
        for i in range(self._light_count):
            colors.append(colors_tuple)
        self._update_lights_to_colors(colors)