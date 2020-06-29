import board

class Config:

    BUTTONS = [board.D12, board.D11, board.D10, board.D9]
    BUTTON_LED_ORDER = [3, 2, 1, 0]

    # BUTTONS = [board.D9, board.D10, board.D11, board.D12]
    # BUTTON_LED_ORDER = [3, 2, 1, 0]

    TIME_TO_START_TRANSITION = 5
    TRANSITION_DURATION = 2