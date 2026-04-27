import serial
import time
from pythonosc import udp_client

PORT   = "/dev/cu.usbmodem12301"
BAUD   = 9600
client = udp_client.SimpleUDPClient("127.0.0.1", 57120)

print("HR Bridge running. Ctrl+C to stop.")

while True:
    try:
        print("Connecting...")
        ser = serial.Serial(PORT, BAUD, timeout=2)
        print("Connected. Waiting for HR data...")
        while True:
            line = ser.readline().decode("utf-8").strip()
            try:
                bpm = float(line)
                if 30 < bpm < 200:
                    print("HR: " + str(bpm) + " bpm")
                    client.send_message("/hr", bpm)
            except:
                pass
    except serial.SerialException:
        print("Disconnected. Retrying in 3 seconds...")
        time.sleep(3)
    except KeyboardInterrupt:
        print("Stopped.")
        break
