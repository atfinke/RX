from bluetooth import Bluetooth
import board
import time

from config import Config

from lights import Lights
from buttons import Buttons
from helpers import hex_to_rgb, num_tuple_array_from_buffer

from debug_mode import DebugMode

import neopixel

class Main:

    def __init__(self):
        print("__init__")
        internal_led = neopixel.NeoPixel(board.NEOPIXEL, 1)[0]
        internal_led = (255, 0, 0)

        self.buttons = Buttons(Config.BUTTONS)
        self.buttons_count = len(Config.BUTTONS)

        time.sleep(1)
        _, states = self.buttons.states()
        self._last_button_states = states
        if states[:1] == [True]:
            DebugMode(self.buttons, Config.BUTTON_LED_ORDER)

        self.host_machine_sleeping = False

        self.lights = Lights(Config.BUTTON_LED_ORDER)
        self.lights.set_to_colors_tuple((Config.MAX_LED_VALUE, Config.MAX_LED_VALUE, Config.MAX_LED_VALUE))
        internal_led = (0, 255, 0)

        self.transition_start_time = None
        self.buffer_rgbs = []
        self.incomplete_hex = ""
        internal_led = (0, 0, 255)

        self.bluetooth = Bluetooth()
        self.bluetooth.connect()
        self.lights.set_to_colors_tuple((0, 0, Config.MAX_LED_VALUE))

        print("connected")
        internal_led = (0, 0, 0)

    def _reset_bluetooth(self):
        self.bluetooth.disconnect()
        self.lights.set_to_colors_tuple((Config.MAX_LED_VALUE, Config.MAX_LED_VALUE, Config.MAX_LED_VALUE))
        self.transition_start_time = None
        self.buffer_rgbs = []
        self.incomplete_hex = ""
        self.bluetooth.connect()
        self.lights.set_to_colors_tuple((0, 0, Config.MAX_LED_VALUE))

    def run(self):
        while True:
            while self.bluetooth.is_connected:
                self.read_bluetooth_data()
                self.update_buttons()
                self.update_leds_for_transition()

                if self.host_machine_sleeping:
                    time.sleep(5)
                elif not self.transition_start_time:
                    time.sleep(0.1)

            print("not connected")
            self.lights.set_to_colors_tuple((Config.MAX_LED_VALUE, Config.MAX_LED_VALUE, Config.MAX_LED_VALUE))
            self.bluetooth.connect()
            self.lights.set_to_colors_tuple((0, 0, Config.MAX_LED_VALUE))

    # Buttons

    def update_buttons(self):
        # adjusted_states = when pressed, only 'True' for first tick
        adjusted_states, states = self.buttons.states()

        if states[:4] == [True, True, True, True]:
            self._reset_bluetooth()
            return

        for (index, is_on) in enumerate(adjusted_states):
            if is_on:
                self.bluetooth.write(index + 1)
                self.lights.update_button_state(index, True)
            elif self._last_button_states[index] and not states[index]:
                self.lights.update_button_state(index, False)

        self._last_button_states = states

    def update_leds_for_transition(self):
        if not self.transition_start_time:
            return

        progress = (time.monotonic() - self.transition_start_time) / Config.TRANSITION_DURATION
        self.lights.update_transition_to_new_resting_colors_progress(progress)
        if progress >= 1:
            self.transition_start_time = None

    # Read Bluetooth

    def received(self, rgb_values):
        self.buffer_rgbs += rgb_values

        if len(self.buffer_rgbs) >= self.buttons_count * 2:
            buffer = num_tuple_array_from_buffer(buffer=self.buffer_rgbs, offset=0, light_count=self.buttons_count)
            self.lights.start_transition_to_new_resting_colors(buffer)

            buffer = num_tuple_array_from_buffer(buffer=self.buffer_rgbs, offset=self.buttons_count, light_count=self.buttons_count)
            self.lights.update_pressed_colors(buffer)
            self.transition_start_time = time.monotonic()
            self.incomplete_hex = ""


    def clear_buffers(self):
        self.buffer_rgbs = []
        self.incomplete_hex = ""
        self.transition_start_time = None

    def read_bluetooth_data(self):
        data = self.bluetooth.read()
        is_new = data is not None and len(data) > 0
        if is_new or len(self.incomplete_hex) > 0:
            self.host_sleeping = False

            str_values = ""
            if is_new and "s" in data:
                self.clear_buffers()
                str_values = data.split("e")[-1].split(",")[1:]
            elif is_new and "x" in data:
                self.clear_buffers()
                self.host_machine_sleeping = True
                self.lights.set_to_colors_tuple((0, 0, 0))
            elif is_new and "q" in data:
                self.clear_buffers()
                self.lights.set_to_colors_tuple((0, 0, 0))
            elif is_new:
                str_values = (self.incomplete_hex + data).split(",")
            else:
                pass

            if len(str_values) > 0:
                try:
                    self.incomplete_hex = str_values.pop()
                    cleaned = [x for x in str_values if x]
                    rgb_values = [hex_to_rgb(n) for n in cleaned]
                    self.received(rgb_values)
                except:
                    pass

print("On")

main = Main()
main.run()