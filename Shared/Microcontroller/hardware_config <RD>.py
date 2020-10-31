import board


class HardwareConfig:

    INTERNAL_LED = None  # board.NEOPIXEL

    BUTTON_INPUTS = [board.A2]
    BUTTON_TLC_LED_ORDER = None  # R1 has a TLC59711 to manage LEDs

    SINGLE_BUTTON_DIGITAL_RGB_OUTPUTS = [board.D11, board.D10, board.D9]  # R, G, B

    MAX_LED_VALUE = 65535

    NAME = "<NAME>"
    SERIAL_NUMBER = "<SERIAL_NUMBER>"
    