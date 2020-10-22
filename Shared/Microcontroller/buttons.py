import busio
import digitalio


class Buttons:

    def __init__(self, pins):
        self._buttons = []
        self._last_states = []
        for pin in pins:
            button = self._setup_button(pin)
            self._buttons.append(button)
            self._last_states.append(False)

    def _setup_button(self, pin):
        button = digitalio.DigitalInOut(pin)
        button.direction = digitalio.Direction.INPUT
        button.pull = digitalio.Pull.UP
        return button

    def states(self):
        # adjusted_states = when a button is pressed, adjusted_states for button is only 'True' for first tick
        # states = truth

        states = []
        adjusted_states = []
        for index, button in enumerate(self._buttons):
            value = not button.value
            states.append(value)
            adjusted_states.append(value and not self._last_states[index])
        self._last_states = states
        return adjusted_states, states
