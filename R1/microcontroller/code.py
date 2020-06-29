from bluetooth import Bluetooth
import board
import time

from config import Config

from lights import Lights, GlobalLightsState, SingleLightOverrideState
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
        if states[:1] == [True]:
            DebugMode(self.buttons, Config.BUTTON_LED_ORDER)

        self.lights = Lights(Config.BUTTON_LED_ORDER)
        self.lights.set_to_off()
        self.lights.tick()
        internal_led = (0, 255, 0)

        self.started_receiving_time = None
        self.finished_receiving = False
        self.transition_start_time = None
        self.buffer_rgbs = []
        self.incomplete_hex = ""
        internal_led = (0, 0, 255)

        self.bluetooth = Bluetooth()
        self.bluetooth.connect()
        self.lights.set_to_blue()

        print("connected")
        internal_led = (0, 0, 0)

    def _reset_bluetooth(self):
        self.bluetooth.disconnect()
        self.lights.set_to_on()
        self.started_receiving_time = None
        self.finished_receiving = False
        self.transition_start_time = None
        self.buffer_rgbs = []
        self.incomplete_hex = ""
        self.bluetooth.connect()
        self.lights.set_to_blue()

    def run(self):
        while True:
            while self.bluetooth.is_connected:
                self.read_bluetooth_data()
                self.update_buttons()
                self.lights.tick()
                time.sleep(0.05)

            print("not connected")
            self.lights.set_to_on()
            self.bluetooth.connect()
            self.lights.set_to_blue()

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

        # current_states = actual states (variable updated)
        for (index, is_on) in enumerate(states):
            state = SingleLightOverrideState.PRESSED if is_on else SingleLightOverrideState.NONE
            self.lights.set_single_state(state, index)

        self.update_colors_for_transition()

    def update_colors_for_transition(self):
        if not self.started_receiving_time:
            return

        current_time = time.monotonic()
        if not self.transition_start_time:
            if current_time - self.started_receiving_time > Config.TIME_TO_START_TRANSITION:
                self.transition_start_time = current_time
                self.lights.set_global_state(GlobalLightsState.TRANSITION_TO_RESTING)
            else:
                return

        progress = (current_time - self.transition_start_time) / Config.TRANSITION_DURATION
        if progress > 1:
            self.started_receiving_time = None
            self.finished_receiving = False
            self.transition_start_time = None
            self.lights.set_global_state(GlobalLightsState.RESTING)

        else:
            self.lights.set_transition_progress(progress)


    # Read Bluetooth

    def received(self, rgb_values):
        self.buffer_rgbs += rgb_values

        if len(self.buffer_rgbs) >= self.buttons_count * 1:
            buffer = num_tuple_array_from_buffer(buffer=self.buffer_rgbs, offset=0, light_count=self.buttons_count)
            self.lights.set_colors(buffer, GlobalLightsState.OPEN)
            self.lights.set_global_state(GlobalLightsState.OPEN)

            if not self.started_receiving_time:
                self.started_receiving_time = time.monotonic()
            self.finished_receiving = False
            self.transition_start_time = None
        if len(self.buffer_rgbs) >= self.buttons_count * 2:
            buffer = num_tuple_array_from_buffer(buffer=self.buffer_rgbs, offset=self.buttons_count, light_count=self.buttons_count)
            self.lights.set_colors(buffer, GlobalLightsState.RESTING)
        if len(self.buffer_rgbs) >= self.buttons_count * 3:
            buffer = num_tuple_array_from_buffer(buffer=self.buffer_rgbs, offset=self.buttons_count * 2, light_count=self.buttons_count)
            self.lights.set_colors(buffer, GlobalLightsState.PRESSED)
        if len(self.buffer_rgbs) == self.buttons_count * 3:
            self.clear_buffers()
            self.finished_receiving = True

    def clear_buffers(self):
        self.buffer_rgbs = []
        self.incomplete_hex = ""

    def read_bluetooth_data(self):
        data = self.bluetooth.read()
        is_new = data is not None and len(data) > 0
        if is_new or len(self.incomplete_hex) > 0:
            if is_new and "s" in data:
                self.clear_buffers()
                str_values = data.split("e")[-1].split(",")[1:]
            elif is_new:
                str_values = (self.incomplete_hex + data).split(",")
            else:
                pass

            if len(str_values) > 0:
                self.incomplete_hex = str_values.pop()
                cleaned = [x for x in str_values if x]
                rgb_values = [hex_to_rgb(n) for n in cleaned]
                self.received(rgb_values)

print("On")

main = Main()
main.run()