import board
import busio
import adafruit_tlc59711
import digitalio
import time
import pulseio

from hardware_config import HardwareConfig

class DebugMode:

    def __init__(self, buttons):
        print(dir(board))
        if HardwareConfig.BUTTON_TLC_LED_ORDER is not None:
            self._tlc_debug_mode(buttons)
        elif HardwareConfig.SINGLE_BUTTON_DIGITAL_RGB_OUTPUTS is not None:
            self._digital_rgb_debug_mode(buttons)
        else:
            raise ValueError('Invalid init')


    def _tlc_debug_mode(self, buttons):
        led_order = HardwareConfig.BUTTON_TLC_LED_ORDER

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
            print(states)
            for index, state in enumerate(states):
                if state:
                    leds[led_order[index]] = (0,0,0)
                    any_on = True

            if any_on:
                time.sleep(1)

    def _digital_rgb_debug_mode(self, buttons):
        frequency = 5000
        duty_cycle = 0
        self._digital_leds = [
            pulseio.PWMOut(HardwareConfig.SINGLE_BUTTON_DIGITAL_RGB_OUTPUTS[0], frequency=frequency, duty_cycle=duty_cycle),
            pulseio.PWMOut(HardwareConfig.SINGLE_BUTTON_DIGITAL_RGB_OUTPUTS[1], frequency=frequency, duty_cycle=duty_cycle),
            pulseio.PWMOut(HardwareConfig.SINGLE_BUTTON_DIGITAL_RGB_OUTPUTS[2], frequency=frequency, duty_cycle=duty_cycle)
        ]

        button_count = 1
        white_button_index = 0

        while True:
            white_button_index += 1
            if white_button_index >= button_count:
                white_button_index = 0

            self._digital_leds[0].duty_cycle = 0
            self._digital_leds[1].duty_cycle = 0
            self._digital_leds[2].duty_cycle = 0

            time.sleep(0.5)

            color_index = 0
            while color_index < 3:
                for button in range(button_count):
                    r = 0
                    g = 0
                    b = 0
                    if color_index == 0:
                        g = HardwareConfig.MAX_LED_VALUE
                        b = HardwareConfig.MAX_LED_VALUE
                    elif color_index == 1:
                        r = HardwareConfig.MAX_LED_VALUE
                        b = HardwareConfig.MAX_LED_VALUE
                    else:
                        r = HardwareConfig.MAX_LED_VALUE
                        g = HardwareConfig.MAX_LED_VALUE

                    self._digital_leds[0].duty_cycle = r
                    self._digital_leds[1].duty_cycle = g
                    self._digital_leds[2].duty_cycle = b

                color_index += 1
                time.sleep(0.75)

            any_on = False
            _, states = buttons.states()
            print(states)
            for index, state in enumerate(states):
                if state:
                    self._digital_leds[0].duty_cycle = HardwareConfig.MAX_LED_VALUE
                    self._digital_leds[1].duty_cycle = HardwareConfig.MAX_LED_VALUE
                    self._digital_leds[2].duty_cycle = HardwareConfig.MAX_LED_VALUE
                    any_on = True

            if any_on:
                time.sleep(1)