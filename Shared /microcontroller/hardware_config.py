import board

class HardwareConfig:

    INTERNAL_LED = board.NEOPIXEL

    BUTTON_INPUTS = [board.D12, board.D11, board.D6, board.D5]
    BUTTON_TLC_LED_ORDER = [0, 1, 2, 3]

    SINGLE_BUTTON_DIGITAL_RGB_OUTPUTS = None

    TRANSITION_DURATION = 0.2
    MAX_LED_VALUE = 65535

    NAME = "Andrew's R1"
    SERIAL_NUMBER = "10"