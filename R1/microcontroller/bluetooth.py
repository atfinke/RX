from adafruit_ble import BLERadio
from adafruit_ble.advertising.standard import ProvideServicesAdvertisement
from adafruit_ble.services.nordic import UARTService

class Bluetooth:

    def __init__(self):
        self.radio = BLERadio()
        self.radio.name = "R1"

        self.uart_service = UARTService()
        self.advertisement = ProvideServicesAdvertisement(self.uart_service)

    def connect(self):
        self.radio.start_advertising(self.advertisement)
        while not self.is_connected():
            pass
        self.radio.stop_advertising()

    def is_connected(self):
        return self.radio.connected

    def write(self, value):
        self.uart_service.write(str(value))

    def read(self):
        if self.uart_service.in_waiting == 0:
            return None

        data = self.uart_service.read(32)
        if data is not None:
            return ''.join([chr(b) for b in data])
        else:
            return None