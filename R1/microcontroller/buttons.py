import board
import busio
import digitalio

class Buttons:

    def __init__(self):
        self.first = self._setup_button(board.D9)
        self.second = self._setup_button(board.D10)
        self.third = self._setup_button(board.D11)
        self.fourth = self._setup_button(board.D12)
        self.last_states = [False, False, False, False]

    def _setup_button(self, pin):
        button = digitalio.DigitalInOut(pin)
        button.direction = digitalio.Direction.INPUT
        button.pull = digitalio.Pull.UP
        return button

    def active_states(self):
        states = [
            not self.first.value,
            not self.second.value,
            not self.third.value,
            not self.fourth.value,
        ]
        adjusted_states = [
            states[0] and not self.last_states[0],
            states[1] and not self.last_states[1],
            states[2] and not self.last_states[2],
            states[3] and not self.last_states[3],
        ]
        self.last_states = states
        return adjusted_states