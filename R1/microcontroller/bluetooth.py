from adafruit_ble import BLERadio
from adafruit_ble.advertising.standard import ProvideServicesAdvertisement
from adafruit_ble.services.nordic import UARTService

class Bluetooth:

    def __init__(self):
        self._radio = BLERadio()
        self._radio.name = "R1"

        self._uart_service = UARTService()
        self._advertisement = ProvideServicesAdvertisement(self._uart_service)

    def connect(self):
        self._radio.start_advertising(self._advertisement)
        while not self.is_connected():
            pass

        for connection in self._radio.connections:
            self._connection = connection
        self._radio.stop_advertising()

    def disconnect(self):
        self._connection.disconnect()

    def is_connected(self):
        return self._radio.connected

    def write(self, value):
        self._uart_service.write(str(value))

    def read(self):
        if self._uart_service.in_waiting == 0:
            return None

        data = self._uart_service.read(32)
        if data is not None:
            return ''.join([chr(b) for b in data])
        else:
            return None