import board
import busio
import adafruit_tlc59711
import digitalio
import time

class Test:

     def __init__(self):
        print(dir(board))
        button = digitalio.DigitalInOut(board.D10)
        button.direction = digitalio.Direction.INPUT
        button.pull = digitalio.Pull.UP

        spi = busio.SPI(board.SCK, MOSI=board.MOSI)
        leds = adafruit_tlc59711.TLC59711(spi)

        while True:
            print(button.value)
            if button.value:
                leds[1] = (0,0,60000)
            else:
                leds[1] = (0,60000,0)
            time.sleep(0.1)