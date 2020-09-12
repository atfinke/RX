import time

from adafruit_ble import BLERadio
from adafruit_ble.advertising.standard import ProvideServicesAdvertisement
from adafruit_ble.services.nordic import UARTService

from hardware_config import HardwareConfig

class Bluetooth:

    def __init__(self):
        self._radio = BLERadio()
        self._radio.name = "RX:" + HardwareConfig.SERIAL_NUMBER

        self._uart_service = UARTService()
        self._advertisement = ProvideServicesAdvertisement(self._uart_service)

        self._connection = None
        self._next_send_heartbeat_time = time.monotonic()
        self._max_response_heartbeat_time = None

    def connect(self):
        self._radio.start_advertising(self._advertisement)

        while not self.is_connected():
            pass

        for connection in self._radio.connections:
            self._connection = connection
        self._radio.stop_advertising()

        self._next_send_heartbeat_time = time.monotonic() + HardwareConfig.HEARTBEAT_INTERVAL
        self._max_response_heartbeat_time = None

    def disconnect(self):
        if self._connection is not None:
            self._connection.disconnect()

    def is_connected(self):
        return self._radio.connected

    def write(self, value):
        self._uart_service.write(str(value))

    def read(self):
        if self._uart_service.in_waiting == 0:
            return None

        data = self._uart_service.read(self._uart_service.in_waiting)
        if data is not None:
            formatted_data = ''.join([chr(b) for b in data])
            if "h" in formatted_data:
                print("bluetooth.py: read: got heartbeat")
                formatted_data = formatted_data.replace("h", "")
                self._max_response_heartbeat_time = None
            return formatted_data
        else:
            return None

    def heartbeat(self):
        mono = time.monotonic()

        if self._max_response_heartbeat_time is not None and mono > self._max_response_heartbeat_time:
            print("bluetooth.py: heartbeat: write connection dead")
            self.disconnect()
            time.sleep(0.2)
        elif mono > self._next_send_heartbeat_time:
            self.write("h")
            self._next_send_heartbeat_time = mono + HardwareConfig.HEARTBEAT_INTERVAL
            self._max_response_heartbeat_time = mono + HardwareConfig.HEARTBEAT_MAX_RESPONSE_TIME