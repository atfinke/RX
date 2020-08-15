import board

class HardwareConfig:

    INTERNAL_LED = None # board.NEOPIXEL

    BUTTON_INPUTS = [board.A2]
    BUTTON_TLC_LED_ORDER = None

    SINGLE_BUTTON_DIGITAL_RGB_OUTPUTS = [board.D11, board.D10, board.D9]

    TRANSITION_DURATION = 0.2
    MAX_LED_VALUE = 65535

    NAME = "Andrew's R1"
    SERIAL_NUMBER = "10"