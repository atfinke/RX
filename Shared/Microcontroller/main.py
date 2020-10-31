import board
import neopixel
import supervisor
import time

from debug_mode import DebugMode

from bluetooth import Bluetooth
from lights import Lights
from buttons import Buttons

from constants import Constants
from hardware_config import HardwareConfig
from helpers import hex_to_rgb, num_array_from_buffer, color_array, single_color_array, color_array

class Main:

    def __init__(self, force_debug=False):
        print("__init__")

        # Setup board led (R1 only)
        self.internal_led = None
        if HardwareConfig.INTERNAL_LED is not None:
            self.internal_led = neopixel.NeoPixel(HardwareConfig.INTERNAL_LED, 1)

        self._update_internal_led_color((255, 0, 0))

        self.buttons = Buttons(HardwareConfig.BUTTON_INPUTS)
        self.buttons_count = len(HardwareConfig.BUTTON_INPUTS)

        # Check if should enter debug hardware mode
        time.sleep(0.5)
        _, states = self.buttons.states()
        self._last_button_states = states
        if states[:1] == [True] or force_debug:
            DebugMode(self.buttons)

        # Init the lights, set to blue
        self.lights = Lights()

        self.lights.start_transition_to_new_resting_colors(color_array([0, 0, HardwareConfig.MAX_LED_VALUE], self.buttons_count))
        self.transition_start_time = time.monotonic_ns()
        while self.transition_start_time is not None:
            self.update_leds_for_transition()

        self._update_internal_led_color((0, 255, 0))

        # Prep the bluetooth vars
        self.buffered_colors = []
        self._update_internal_led_color((0, 0, 255))

        self.bluetooth = Bluetooth()
        self.bluetooth.connect()

        self.lights.start_transition_to_new_resting_colors(single_color_array(0, self.buttons_count))
        self.transition_start_time = time.monotonic_ns()

        print("connected")
        self._update_internal_led_color((0, 0, 0))

    def _update_internal_led_color(self, color):
        if self.internal_led is not None:
            self.internal_led[0] = color

    def run(self):
        while True:
            while self.bluetooth.is_connected():
                self.read_bluetooth_data()
                self.update_buttons()
                
                if self.transition_start_time:
                    self.update_leds_for_transition()
                else:
                    self.bluetooth.heartbeat()
                    time.sleep(0.05)

            print("not connected - waiting a bit for fast reconnect")
            self.bluetooth.connect(timeout=Constants.FAST_RECONNECT_WAIT_TIME_BEFORE_RESETING_LIGHTS)

            if self.bluetooth.is_connected():
                print("fast connect success")
                continue
            else:
                print("fast connect failed")
                
            self.lights.set_to_colors_tuple((0, 0, 0))
            self.bluetooth.connect()

    # BUTTONS

    def update_buttons(self):
        # adjusted_states = when a button is pressed, adjusted_states for button is only 'True' for first tick
        # states = truth
        adjusted_states, states = self.buttons.states()

        # Only R1
        if states[:4] == [True, True, True, True]:
            self._reset_bluetooth()
            return

        # Send button data (button num starts at 1)
        for (index, is_on) in enumerate(adjusted_states):
            if is_on:
                self.bluetooth.write("b:" + str(index + 1))
                self.lights.update_button_state(index, True)
            elif self._last_button_states[index] and not states[index]:
                self.lights.update_button_state(index, False)

        self._last_button_states = states

    def update_leds_for_transition(self):
        if not self.transition_start_time:
            return

        # Get percent progress
        time_since_start_ms = round((time.monotonic_ns() - self.transition_start_time) / 1e6, 1)
        progress = time_since_start_ms / Constants.LIGHT_TRANSITION_DURATION
        self.lights.update_transition_to_new_resting_colors_progress(progress)
        if progress >= 1:
            self.transition_start_time = None

    # BLUETOOTH

    def _reset_bluetooth(self):
        self.bluetooth.disconnect()
        self.lights.set_to_colors_tuple((0, 0, 0))
        self.transition_start_time = None
        self.buffered_colors = []
        self.bluetooth.connect()

    def clear_buffers(self):
        self.buffered_colors = []
        self.transition_start_time = None

    def read_bluetooth_data(self):
        data = self.bluetooth.read()

        if data is None or len(data) == 0:
            return

        if "q" in data:  # RXd says to disconnect
            self.clear_buffers()
            self._reset_bluetooth()
            return

        if "n" in data:  # RXd ready for name
            self.bluetooth.write("n:" + HardwareConfig.NAME)
            data = data.replace("n", "")

        if "s" in data:  # RXd sending new colors
            self.clear_buffers()
            data = data.split("s")[-1]  # throw away previous colors in data

        if len(data) == 0:
            return

        # Seperate colors
        hex_values = [data[i:i+6] for i in range(0, len(data), 6)]

        # Convert to rgb
        rgb_values = [hex_to_rgb(n) for n in hex_values]

        # Add to buffer (not all colors can fit in one message)
        self.buffered_colors += rgb_values

        # If we have gotten all colors needed...
        if len(self.buffered_colors) >= self.buttons_count * 2:
            resting_colors = num_array_from_buffer(buffer=self.buffered_colors, offset=0, light_count=self.buttons_count)
            self.lights.start_transition_to_new_resting_colors(resting_colors)

            pressed_colors = num_array_from_buffer(buffer=self.buffered_colors, offset=self.buttons_count, light_count=self.buttons_count)
            self.lights.update_pressed_colors(pressed_colors)
            self.transition_start_time = time.monotonic_ns()


print("Booted FW: {}".format(Constants.FW_VERSION))
supervisor.disable_autoreload() # to enable call enable_autoreload() once
main = Main(force_debug=False)
main.run()