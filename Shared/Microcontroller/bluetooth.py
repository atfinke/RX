import time

from adafruit_ble import BLERadio
from adafruit_ble.advertising.standard import ProvideServicesAdvertisement
from adafruit_ble.services.nordic import UARTService

from constants import Constants
from hardware_config import HardwareConfig


class Bluetooth:

    def __init__(self):
        self._radio = BLERadio()
        self._radio.name = "RX:" + HardwareConfig.SERIAL_NUMBER

        self._uart_service = UARTService()
        self._advertisement = ProvideServicesAdvertisement(self._uart_service)

        self._connection = None
        self._next_send_heartbeat_time = time.time()
        self._max_response_heartbeat_time = None

    def connect(self, timeout=None):
        start_time = time.time()
        self._radio.start_advertising(self._advertisement)

        while not self.is_connected():
            if timeout is not None and time.time() - start_time > timeout:
                self._radio.stop_advertising()
                return False
            time.sleep(0.05)

        for connection in self._radio.connections:
            self._connection = connection
        self._radio.stop_advertising()

        self._next_send_heartbeat_time = time.time() + Constants.HEARTBEAT_INTERVAL
        self._max_response_heartbeat_time = None
        return True

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

    # Sometimes the RD write connection dies, but reading from RXd still works. This triggers a reconnect.
    def heartbeat(self):
        t = time.time()

        if self._max_response_heartbeat_time is not None and t > self._max_response_heartbeat_time:
            print("bluetooth.py: heartbeat: write connection dead")
            self.disconnect()
            time.sleep(0.2)
        elif t > self._next_send_heartbeat_time:
            self.write("h")
            self._next_send_heartbeat_time = t + Constants.HEARTBEAT_INTERVAL
            self._max_response_heartbeat_time = t + Constants.HEARTBEAT_MAX_RESPONSE_TIME
