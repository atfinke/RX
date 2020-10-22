import board


class HardwareConfig:

    VERSION = 2
    
    INTERNAL_LED = board.NEOPIXEL

    BUTTON_INPUTS = [board.D12, board.D11, board.D6, board.D5]
    BUTTON_TLC_LED_ORDER = [0, 1, 2, 3]  # R1 has a TLC59711 to manage LEDs

    SINGLE_BUTTON_DIGITAL_RGB_OUTPUTS = None  # R, G, B
    
    MAX_LED_VALUE = 65535

    NAME = "<NAME>"
    SERIAL_NUMBER = "<SERIAL_NUMBER>"
    