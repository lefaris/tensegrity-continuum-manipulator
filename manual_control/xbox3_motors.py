import signal
import keyboard
import time
from roboclaw_3 import Roboclaw


baudrate = 38400#230400

rc = Roboclaw("/dev/ttyACM1", baudrate)
rc2 = Roboclaw("/dev/ttyACM0", baudrate)

rc.Open()
add1 = 0x81
rc2.Open()
add2 = 0x80


spd = 144000
acc = 144000
motmov = 46080#92160#184320/2

# rc.SpeedAccelDistanceM1(add1, 144000, 144000,200000,1)
# rc.SpeedAccelDistanceM2(add1, 144000, 144000,200000,1)
# rc.SpeedAccelDistanceM1(add2, 144000, 144000,200000,1)
# rc.SpeedAccelDistanceM2(add2, 144000, 144000,200000,1)

def move_motor(key):
    global add1, add2, motmov, acc, spd

    if key == 'up':
        rc.SpeedAccelDistanceM2(add1, spd, acc, motmov, 1)
        print("Motor 1 Plus")
    elif key == 'down':
        rc.SpeedAccelDistanceM2(add1, spd, -acc, motmov, 1)
        print("Motor 1 Minus")
    elif key == 'left':
        rc.SpeedAccelDistanceM1(add1, spd, -acc, motmov, 1)
        print("Motor 2 Plus")
    elif key == 'right':
        rc.SpeedAccelDistanceM1(add1, spd, acc, motmov, 1)
        print("Motor 2 Minus")
    elif key == 'w':
        rc2.SpeedAccelDistanceM1(add2, spd, -acc, motmov, 1)
        print("Motor 3 Plus")
    elif key == 's':
        rc2.SpeedAccelDistanceM1(add2, spd, acc, motmov, 1)
        print("Motor 3 Minus")
    elif key == 'a':
        rc2.SpeedAccelDistanceM2(add2, spd, acc, motmov, 1)
        print("Motor 4 Plus")
    elif key == 'd':
        rc2.SpeedAccelDistanceM2(add2, spd, -acc, motmov, 1)
        print("Motor 4 Minus")


print("Use arrow keys for motors 1 and 2, and WASD for motors 3 and 4.")
print("Press ESC to quit.")

try:
    while True:
        if keyboard.is_pressed("up"):
            move_motor("up")
            time.sleep(0.2)
        elif keyboard.is_pressed("down"):
            move_motor("down")
            time.sleep(0.2)
        elif keyboard.is_pressed("left"):
            move_motor("left")
            time.sleep(0.2)
        elif keyboard.is_pressed("right"):
            move_motor("right")
            time.sleep(0.2)
        elif keyboard.is_pressed("w"):
            move_motor("w")
            time.sleep(0.2)
        elif keyboard.is_pressed("s"):
            move_motor("s")
            time.sleep(0.2)
        elif keyboard.is_pressed("a"):
            move_motor("a")
            time.sleep(0.2)
        elif keyboard.is_pressed("d"):
            move_motor("d")
            time.sleep(0.2)
        elif keyboard.is_pressed("esc"):
            print("Exiting...")
            break
except KeyboardInterrupt:
    print("Program stopped by user.")