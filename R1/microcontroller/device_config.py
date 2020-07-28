import board

class DeviceConfig:

    BUTTON_INPUTS = [board.D12, board.D11, board.D6, board.D5]
    BUTTON_TLC_LED_ORDER = [0, 1, 2, 3]

    TRANSITION_DURATION = 0.2

    MAX_LED_VALUE = 65535