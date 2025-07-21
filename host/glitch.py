import serial
import time
import os
from pathlib import Path

BAUD_RATE = 9600

# Packet types
SET_OFFSET_CMD = 0xA0
SET_WIDTH_CMD = 0xA1
SET_REPEAT_CMD = 0xA2
GET_OFFSET_CMD = 0xB0
GET_WIDTH_CMD = 0xB1
GET_REPEAT_CMD = 0xB2
PING_CMD = 0xC0

ARM_CMD = 0x1
DISARM_CMD = 0x2
GET_ARM_STATE_CMD = 0x3
MANUAL_TRIGGER_CMD = 0x4

# Magic number for PING response
PING_RESPONSE = 0x42


class Glitch:
    def __init__(self, port):
        print("Connecting to:", port)

        self.ser = serial.Serial(port, BAUD_RATE, timeout=1)
        # Clear any pending data
        self.ser.reset_input_buffer()
        self.ser.reset_output_buffer()

    def set_offset(self, offset):
        # Send the full 32-bit value as 4 bytes (MSB first)
        msb = (offset >> 24) & 0xFF
        byte2 = (offset >> 16) & 0xFF
        byte3 = (offset >> 8) & 0xFF
        lsb = offset & 0xFF
        set_offset_packet = (
            (SET_OFFSET_CMD).to_bytes(1, byteorder="big")
            + msb.to_bytes(1, byteorder="big")
            + byte2.to_bytes(1, byteorder="big")
            + byte3.to_bytes(1, byteorder="big")
            + lsb.to_bytes(1, byteorder="big")
        )
        self.ser.write(set_offset_packet)

    def set_width(self, width):
        # Send the full 32-bit value as 4 bytes (MSB first)
        msb = (width >> 24) & 0xFF
        byte2 = (width >> 16) & 0xFF
        byte3 = (width >> 8) & 0xFF
        lsb = width & 0xFF
        set_width_packet = (
            (SET_WIDTH_CMD).to_bytes(1, byteorder="big")
            + msb.to_bytes(1, byteorder="big")
            + byte2.to_bytes(1, byteorder="big")
            + byte3.to_bytes(1, byteorder="big")
            + lsb.to_bytes(1, byteorder="big")
        )
        self.ser.write(set_width_packet)

    def set_repeat(self, rep_cnt):
        # Send the full 32-bit value as 4 bytes (MSB first)
        msb = (rep_cnt >> 24) & 0xFF
        byte2 = (rep_cnt >> 16) & 0xFF
        byte3 = (rep_cnt >> 8) & 0xFF
        lsb = rep_cnt & 0xFF
        set_repeat_packet = (
            (SET_REPEAT_CMD).to_bytes(1, byteorder="big")
            + msb.to_bytes(1, byteorder="big")
            + byte2.to_bytes(1, byteorder="big")
            + byte3.to_bytes(1, byteorder="big")
            + lsb.to_bytes(1, byteorder="big")
        )
        self.ser.write(set_repeat_packet)

    def get_offset(self, debug=False):
        self.ser.write((GET_OFFSET_CMD).to_bytes(1, byteorder="big"))
        time.sleep(0.1)  # Give the FPGA time to respond
        bytes_available = self.ser.in_waiting
        if debug:
            print(f"Bytes available: {bytes_available}")

        if bytes_available >= 4:  # We expect 4 bytes for a 32-bit value
            # Read 4 bytes and combine them into a 32-bit value
            msb = int.from_bytes(self.ser.read(1), byteorder="big")
            byte2 = int.from_bytes(self.ser.read(1), byteorder="big")
            byte3 = int.from_bytes(self.ser.read(1), byteorder="big")
            lsb = int.from_bytes(self.ser.read(1), byteorder="big")

            if debug:
                print(
                    f"Received bytes: {hex(msb)}, {hex(byte2)}, {hex(byte3)}, {hex(lsb)}"
                )
                print(
                    f"Combined value: {hex((msb << 24) | (byte2 << 16) | (byte3 << 8) | lsb)}"
                )

            return (msb << 24) | (byte2 << 16) | (byte3 << 8) | lsb
        else:
            if debug:
                print(f"Not enough bytes received. Expected 4, got {bytes_available}")
            return None

    def get_width(self, debug=False):
        self.ser.write((GET_WIDTH_CMD).to_bytes(1, byteorder="big"))
        time.sleep(0.1)  # Give the FPGA time to respond
        bytes_available = self.ser.in_waiting
        if debug:
            print(f"Bytes available: {bytes_available}")

        if bytes_available >= 4:  # We expect 4 bytes for a 32-bit value
            # Read 4 bytes and combine them into a 32-bit value
            msb = int.from_bytes(self.ser.read(1), byteorder="big")
            byte2 = int.from_bytes(self.ser.read(1), byteorder="big")
            byte3 = int.from_bytes(self.ser.read(1), byteorder="big")
            lsb = int.from_bytes(self.ser.read(1), byteorder="big")

            if debug:
                print(
                    f"Received bytes: {hex(msb)}, {hex(byte2)}, {hex(byte3)}, {hex(lsb)}"
                )
                print(
                    f"Combined value: {hex((msb << 24) | (byte2 << 16) | (byte3 << 8) | lsb)}"
                )

            return (msb << 24) | (byte2 << 16) | (byte3 << 8) | lsb
        else:
            if debug:
                print(f"Not enough bytes received. Expected 4, got {bytes_available}")
            return None

    def get_repeat(self, debug=False):
        self.ser.write((GET_REPEAT_CMD).to_bytes(1, byteorder="big"))
        time.sleep(0.1)  # Give the FPGA time to respond
        bytes_available = self.ser.in_waiting
        if debug:
            print(f"Bytes available: {bytes_available}")

        if bytes_available >= 4:  # We expect 4 bytes for a 32-bit value
            # Read 4 bytes and combine them into a 32-bit value
            msb = int.from_bytes(self.ser.read(1), byteorder="big")
            byte2 = int.from_bytes(self.ser.read(1), byteorder="big")
            byte3 = int.from_bytes(self.ser.read(1), byteorder="big")
            lsb = int.from_bytes(self.ser.read(1), byteorder="big")

            if debug:
                print(
                    f"Received bytes: {hex(msb)}, {hex(byte2)}, {hex(byte3)}, {hex(lsb)}"
                )
                print(
                    f"Combined value: {hex((msb << 24) | (byte2 << 16) | (byte3 << 8) | lsb)}"
                )

            return (msb << 24) | (byte2 << 16) | (byte3 << 8) | lsb
        else:
            if debug:
                print(f"Not enough bytes received. Expected 4, got {bytes_available}")
            return None

    def ping(self):
        self.ser.write((PING_CMD).to_bytes(1, byteorder="big"))
        time.sleep(0.1)  # Give the FPGA time to respond
        if self.ser.in_waiting > 0:
            response = int.from_bytes(self.ser.read(1), byteorder="big")
            return response == PING_RESPONSE
        return False

    def arm(self):
        self.ser.write((ARM_CMD).to_bytes(1, byteorder="big"))

    def disarm(self):
        self.ser.write((DISARM_CMD).to_bytes(1, byteorder="big"))

    def is_armed(self):
        self.ser.write((GET_ARM_STATE_CMD).to_bytes(1, byteorder="big"))
        time.sleep(0.1)  # Give the FPGA time to respond
        if self.ser.in_waiting > 0:
            response = int.from_bytes(self.ser.read(1), byteorder="big")
            return response == 0xF1
        return False

    def manual_trigger(self):
        self.ser.write((MANUAL_TRIGGER_CMD).to_bytes(1, byteorder="big"))


def find_usb_device(
    dev="/dev/serial/by-id/usb-Digilent_Digilent_Adept_USB_Device_210328AFE462-if01-port0",
):
    path_obj = Path(dev)

    if path_obj.is_symlink():
        target = path_obj.readlink()
        return str((path_obj.parent / target).resolve())

    return None


if __name__ == "__main__":
    g = Glitch(find_usb_device())
    print(f"Ping result: {g.ping()}")

    g.set_repeat(1)
    g.set_offset(1)
    g.set_width(4000)
    g.manual_trigger()
    exit()

    # Test arming
    g.arm()
    print(g.is_armed())
    g.disarm()
    print(g.is_armed())

    # Test width
    test_value = 0xFFEEDD88
    print(f"\nSetting width to: {hex(test_value)}")
    g.set_width(test_value)

    print("Getting width with debug info:")
    result = g.get_width(debug=True)
    if result is not None:
        print(f"Final result: {hex(result)}")
    else:
        print("Failed to get width")

    # Test offset
    test_value = 0x12345678
    print(f"\nSetting offset to: {hex(test_value)}")
    g.set_offset(test_value)

    print("Getting offset with debug info:")
    result = g.get_offset(debug=True)
    if result is not None:
        print(f"Final result: {hex(result)}")
    else:
        print("Failed to get offset")

    # Test repeat
    test_value = 0xABCDEF12
    print(f"\nSetting repeat to: {hex(test_value)}")
    g.set_repeat(test_value)

    print("Getting repeat with debug info:")
    result = g.get_repeat(debug=True)
    if result is not None:
        print(f"Final result: {hex(result)}")
    else:
        print("Failed to get repeat")
