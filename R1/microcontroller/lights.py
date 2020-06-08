import board
import busio

import adafruit_tlc59711
from helpers import white_tuple_array, lerp_tuple_arrays

class GlobalLightsState:
    OPEN = 1
    TRANSITION_TO_RESTING = 2
    RESTING = 3
    PRESSED = 4


class SingleLightOverrideState:
    NONE = 1
    PRESSED = 2

class Lights:

    def __init__(self, light_count):
        assert(light_count <= 4)

        self._colors = {
            GlobalLightsState.OPEN: white_tuple_array(light_count),
            GlobalLightsState.RESTING: white_tuple_array(light_count),
            GlobalLightsState.PRESSED: white_tuple_array(light_count)
        }

        self._global_lights_state = GlobalLightsState.OPEN
        self._single_light_override_state = []

        self._light_count = light_count
        for i in range(light_count):
            self._single_light_override_state.append(SingleLightOverrideState.NONE)

        spi = busio.SPI(board.SCK, MOSI=board.MOSI)
        self._leds = adafruit_tlc59711.TLC59711(spi, auto_show=False)

    def set_colors(self, colors, state):
        assert(len(colors) == self._light_count)
        self._colors[state] = colors

    def set_global_state(self, state):
        self._global_lights_state = state

    def set_single_state(self, state, light_index):
        self._single_light_override_state[light_index] = state

    def set_transition_progress(self, progress):
        self._transition_progress = progress


    def _update_lights_to_colors(self, colors):
        for index, color in enumerate(colors):
            self._leds[index] = color

    def _update_to_global_lights_state(self):
        colors = self._colors[self._global_lights_state]
        self._update_lights_to_colors(colors)


    def tick(self):
        if self._global_lights_state == GlobalLightsState.OPEN or self._global_lights_state == GlobalLightsState.RESTING:
            self._update_to_global_lights_state()
        elif self._global_lights_state == GlobalLightsState.TRANSITION_TO_RESTING:
           inital = self._colors[GlobalLightsState.OPEN]
           final = self._colors[GlobalLightsState.RESTING]
           lerp = lerp_tuple_arrays(inital, final, self._transition_progress)
           self._update_lights_to_colors(lerp)

        for index, state in enumerate(self._single_light_override_state):
            if state == SingleLightOverrideState.PRESSED:
                self._leds[index] = self._colors[GlobalLightsState.PRESSED][index]


        self._leds.show()





    def _update_to_color(self, color):
        for i in range(4):
            self.leds[i] = color[i]

    def set_to_white(self):
        for i in range(4):
            self.leds[i] = white_tuple_array()









