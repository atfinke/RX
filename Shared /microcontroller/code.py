import board
import time
import neopixel

from debug_mode import DebugMode

from bluetooth import Bluetooth
from lights import Lights
from buttons import Buttons

from hardware_config import HardwareConfig
from helpers import hex_to_rgb, num_tuple_array_from_buffer

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
        time.sleep(1)
        _, states = self.buttons.states()
        self._last_button_states = states
        if states[:1] == [True] or force_debug:
            DebugMode(self.buttons)

        # Init the lights, set to blue
        self.lights = Lights()
        self.lights.set_to_colors_tuple((0, 0, int(HardwareConfig.MAX_LED_VALUE / 4)))
        self._update_internal_led_color((0, 255, 0))

        # Prep the bluetooth vars
        self.transition_start_time = None
        self.buffered_colors = []
        self._update_internal_led_color((0, 0, 255))

        self.bluetooth = Bluetooth()
        self.bluetooth.connect()
        self.lights.set_to_colors_tuple((0, 0, 0))

        print("connected")
        self._update_internal_led_color((0, 0, 0))

    def _update_internal_led_color(self, color):
        if self.internal_led is not None:
            self.internal_led[0] = color

    def _reset_bluetooth(self):
        self.bluetooth.disconnect()
        self.lights.set_to_colors_tuple((0, 0, 0))
        self.transition_start_time = None
        self.buffered_colors = []
        self.bluetooth.connect()

    def run(self):
        while True:
            while self.bluetooth.is_connected():
                self.read_bluetooth_data()
                self.update_buttons()
                self.update_leds_for_transition()

                # sleep a bit unless animating between colors
                if not self.transition_start_time:
                    self.bluetooth.heartbeat()
                    time.sleep(0.01)


            print("not connected")
            self.lights.set_to_colors_tuple((0, 0, 0))
            self.bluetooth.connect()

    # Buttons

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
        progress = (time.monotonic() - self.transition_start_time) / HardwareConfig.TRANSITION_DURATION
        self.lights.update_transition_to_new_resting_colors_progress(progress)
        if progress >= 1:
            self.transition_start_time = None

    # Read Bluetooth

    def clear_buffers(self):
        self.buffered_colors = []
        self.transition_start_time = None

    def read_bluetooth_data(self):
        data = self.bluetooth.read()

        if data is None or len(data) == 0:
            return

        if "q" in data: # RXd says to disconnect
            self.clear_buffers()
            self._reset_bluetooth()
            return
        elif "n" in data: # RXd ready for name
            self.bluetooth.write("n:" + HardwareConfig.NAME)
            data = data.replace("n", "")
        elif "s" in data: # RXd sending new colors
            self.clear_buffers()
            data = data[1:]

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
            resting_colors = num_tuple_array_from_buffer(buffer=self.buffered_colors, offset=0, light_count=self.buttons_count)
            self.lights.start_transition_to_new_resting_colors(resting_colors)

            pressed_colors = num_tuple_array_from_buffer(buffer=self.buffered_colors, offset=self.buttons_count, light_count=self.buttons_count)
            self.lights.update_pressed_colors(pressed_colors)
            self.transition_start_time = time.monotonic()


print("Booted V: 2020.09")
main = Main(force_debug=False)
main.run()