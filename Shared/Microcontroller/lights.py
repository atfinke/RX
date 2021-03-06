import board
import busio
import math
import pulseio
import adafruit_tlc59711

from hardware_config import HardwareConfig
from helpers import single_color_array, lerp_arrays


class Lights:

    def __init__(self):
        self._tlc_leds = None
        self._digital_leds = None

        if HardwareConfig.BUTTON_TLC_LED_ORDER is not None:
            self._light_order = HardwareConfig.BUTTON_TLC_LED_ORDER
            self._light_count = len(self._light_order)
            spi = busio.SPI(board.SCK, MOSI=board.MOSI)
            self._tlc_leds = adafruit_tlc59711.TLC59711(spi, auto_show=False)

        elif HardwareConfig.SINGLE_BUTTON_DIGITAL_RGB_OUTPUTS is not None:
            assert(len(HardwareConfig.SINGLE_BUTTON_DIGITAL_RGB_OUTPUTS) == 3)

            self._light_order = None
            self._light_count = 1

            duty_cycle = HardwareConfig.MAX_LED_VALUE
            self._digital_leds = [
                pulseio.PWMOut(HardwareConfig.SINGLE_BUTTON_DIGITAL_RGB_OUTPUTS[0], duty_cycle=duty_cycle),
                pulseio.PWMOut(HardwareConfig.SINGLE_BUTTON_DIGITAL_RGB_OUTPUTS[1], duty_cycle=duty_cycle),
                pulseio.PWMOut(HardwareConfig.SINGLE_BUTTON_DIGITAL_RGB_OUTPUTS[2], duty_cycle=duty_cycle)
            ]
        else:
            raise ValueError('Invalid init')

        self._resting_colors = single_color_array(0, self._light_count)
        self._pressed_colors = single_color_array(HardwareConfig.MAX_LED_VALUE, self._light_count)

        self._current_colors = single_color_array(0, self._light_count)
        self._transition_start_colors = None
        self._transition_final_colors = None

    # RESTING COLORS

    def start_transition_to_new_resting_colors(self, new_colors):
        self._resting_colors = new_colors
        self._transition_start_colors = self._current_colors
        self._transition_final_colors = new_colors

    def update_transition_to_new_resting_colors_progress(self, percent):
        inital = self._transition_start_colors
        final = self._transition_final_colors

        if percent > 1:
            self._update_lights_to_colors(final)
            return
        elif inital == final:
            return

        timing_function_progress = self._percent_complete_to_ease_in_out_function_progress(percent)
        lerp = lerp_arrays(inital, final, min(timing_function_progress, 1))

        self._update_lights_to_colors(lerp)

    def _percent_complete_to_ease_in_out_function_progress(self, percent):
        return -(math.cos(math.pi * percent) - 1) / 2

    # PRESSED COLORS

    def update_pressed_colors(self, new_colors):
        self._pressed_colors = new_colors

    def update_button_state(self, index, is_on):
        color = self._pressed_colors[index] if is_on else self._resting_colors[index]

        if self._tlc_leds is not None:
            self._tlc_leds[self._light_order[index]] = color
            self._tlc_leds.show()
        else:
            self._digital_leds[0].duty_cycle = HardwareConfig.MAX_LED_VALUE - color[0]
            self._digital_leds[1].duty_cycle = HardwareConfig.MAX_LED_VALUE - color[1]
            self._digital_leds[2].duty_cycle = HardwareConfig.MAX_LED_VALUE - color[2]

    # HELPERS

    def _update_lights_to_colors(self, colors):
        for index, color in enumerate(colors):
            if self._tlc_leds is not None:
                self._tlc_leds[self._light_order[index]] = color
            else:
                assert(len(colors) == 1)
                color = colors[0]

                self._digital_leds[0].duty_cycle = HardwareConfig.MAX_LED_VALUE - color[0]
                self._digital_leds[1].duty_cycle = HardwareConfig.MAX_LED_VALUE - color[1]
                self._digital_leds[2].duty_cycle = HardwareConfig.MAX_LED_VALUE - color[2]

        if self._tlc_leds is not None:
            self._tlc_leds.show()

        self._current_colors = colors

    def set_to_colors_tuple(self, colors_tuple):
        colors = [colors_tuple for i in range(self._light_count)]
        self._update_lights_to_colors(colors)
