import board

class HardwareConfig:

    INTERNAL_LED = None # board.NEOPIXEL

    BUTTON_INPUTS = [board.A2]
    BUTTON_TLC_LED_ORDER = None

    SINGLE_BUTTON_DIGITAL_RGB_OUTPUTS = [board.D11, board.D10, board.D9]

    TRANSITION_DURATION = 0.32
    MAX_LED_VALUE = 65535

    HEARTBEAT_INTERVAL = 120
    HEARTBEAT_MAX_RESPONSE_TIME = 5
    
    NAME = "TBD's RD"
    SERIAL_NUMBER = "10"
