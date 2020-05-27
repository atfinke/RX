from bluetooth import Bluetooth
from lights import Lights
from buttons import Buttons
from helpers import hex_to_rgb, num_tuple_array_from_buffer
from test import Test

import time

class Main:

    def __init__(self):
        self.lights = Lights()
        self.buttons = Buttons()

        self.bluetooth = Bluetooth()
        self.bluetooth.connect()

        self.buffer_rgbs = []
        self.incomplete_hex = ""

    def run(self):
        while True:
            while self.bluetooth.is_connected:
                self.read_bluetooth_data()
                self.send_on_buttons()
                time.sleep(0.05)

    # Buttons

    def send_on_buttons(self):
        states = self.buttons.active_states()
        for (index, is_on) in enumerate(states):
            if is_on:
                self.bluetooth.write(index + 1)

    # Read Bluetooth

    def received(self, rgb_values):
        self.buffer_rgbs += rgb_values

        if len(self.buffer_rgbs) >= 4:
            self.lights.update_open_color(num_tuple_array_from_buffer(buffer=self.buffer_rgbs, offset=0))
            self.lights.update_to_open_color()

        if len(self.buffer_rgbs) >= 8:
            self.lights.update_resting_color(num_tuple_array_from_buffer(buffer=self.buffer_rgbs, offset=4))

        if len(self.buffer_rgbs) >= 12:
            self.lights.update_pressed_color(num_tuple_array_from_buffer(buffer=self.buffer_rgbs, offset=8))

        if len(self.buffer_rgbs) == 12:
            self.clear_buffers()

    def clear_buffers(self):
        print("clear")
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
                print(cleaned)
                rgb_values = [hex_to_rgb(n) for n in cleaned]
                self.received(rgb_values)

#Test()

main = Main()
main.run()