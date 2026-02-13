"""
Lauren Ervin
REACH manipulator end effector workspace generation

This script is for generating end effector workspace positions for 
Vicon data collection. The user will initially align the manipulator
in an upright orientation using the Xbox controller as the starting 
position, then the script will generate the workspace.

Usage:
Initially move the manipulator into an upright position by manually
controlling it with A, B, X, and Y tightening and the D-pad loosening.
Once the manipulator is upright and the inline load cells are balanced,
press the left trigger to begin workspace generation. 
"""

import signal
from xbox360controller import Xbox360Controller
import time
from roboclaw_3 import Roboclaw
from Phidget22.Phidget import *
from Phidget22.Devices.VoltageRatioInput import *
import csv

baudrate = 230400

# Roboclaw 1 controls motors 1–2
rc1 = Roboclaw("/dev/ttyACM0", baudrate)
# Roboclaw 2 controls motors 3–4
rc2 = Roboclaw("/dev/ttyACM1", baudrate)

rc1.Open()
rc2.Open()

# Addresses
add1 = 0x80
add2 = 0x81

spd = 144000
acc = 144000
motmov = 46080
longitudinal_path = 5

# Four load cell parameters from calibration
gain0 = 56230
offset0 = 2.8131
gain1 = 56251
offset1 = 5.1885
gain2 = 56145
offset2 = 0.3451
gain3 = 56145
offset3 = 1.2198

# Load cell CSV filename
csv_file = 'reach_load_cell.csv'


# Motor Control Functions
def check_motor_movement(rc, address, motor, send_command_fn, 
                         settle_time=0.05, move_time=0.2, encoder_threshold=50):

    # Encoder State before
    if motor == 1:
        _, enc_before, _ = rc.ReadEncM1(address)
    else:
        _, enc_before, _ = rc.ReadEncM2(address)

    # Send command
    send_command_fn()
    time.sleep(settle_time)

    # Read buffer
    _, buf1, buf2 = rc.ReadBuffers(address)
    buf = buf1 if motor == 1 else buf2

    # Read speed
    if motor == 1:
        _, speed, _ = rc.ReadSpeedM1(address)
    else:
        _, speed, _ = rc.ReadSpeedM2(address)

    time.sleep(move_time)

    # Encoder State after
    if motor == 1:
        _, enc_after, _ = rc.ReadEncM1(address)
    else:
        _, enc_after, _ = rc.ReadEncM2(address)

    encoder_delta = abs(enc_after - enc_before)

    # Check movement success
    success = (encoder_delta >= encoder_threshold) or (speed != 0)

    diagnostics = {
        "enc_before": enc_before,
        "enc_after": enc_after,
        "encoder_delta": encoder_delta,
        "buffer": buf,
        "speed": speed
    }

    return success, diagnostics


def send_and_verify(rc, address, motor, command_fn, retries = 3):
    if rc == rc1:
        if motor == 1:
            motor_print = 2
        else:
            motor_print = 1
    else:
        if motor == 1:
            motor_print = 3
        else:
            motor_print = 4

    for attempt in range(1, retries + 1):
        success, diag = check_motor_movement(rc, address, motor, command_fn)

        if success:
            print(f"[OK] Motor {motor_print} moved successfully. Diagnostics: {diag}")
            return True

        print(f"[WARNING] Motor {motor_print} failed attempt {attempt}: {diag}")
        time.sleep(0.1)

    print(f"[ERROR] Motor {motor_print} failed to move after {retries} attempts")
    return False


def move_one_plus(button=None):
    def cmd():
        rc1.SpeedAccelDistanceM2(add1, spd, acc, motmov, 1)

    send_and_verify(rc1, add1, motor=2, command_fn=cmd)
    print("Motor 1 Plus")
    time.sleep(3)
    voltageChange()


def move_two_plus(button=None):
    def cmd():
        rc1.SpeedAccelDistanceM1(add1, spd, -acc, motmov, 1)

    send_and_verify(rc1, add1, motor=1, command_fn=cmd)
    print("Motor 2 Plus")
    time.sleep(3)
    voltageChange()


def move_three_plus(button=None):
    def cmd():
        rc2.SpeedAccelDistanceM1(add2, spd, -acc, motmov, 1)

    send_and_verify(rc2, add2, motor=1, command_fn=cmd)
    print("Motor 3 Plus")
    time.sleep(3)
    voltageChange()


def move_four_plus(button=None):
    def cmd():
        rc2.SpeedAccelDistanceM2(add2, spd, acc, motmov, 1)

    send_and_verify(rc2, add2, motor=2, command_fn=cmd)
    print("Motor 4 Plus")
    time.sleep(3)
    voltageChange()


def move_one_minus(button=None):
    def cmd():
        rc1.SpeedAccelDistanceM2(add1, spd, -acc, motmov, 1)

    send_and_verify(rc1, add1, motor=2, command_fn=cmd)
    print("Motor 1 Minus")
    time.sleep(3)
    voltageChange()


def move_two_minus(button=None):
    def cmd():
        rc1.SpeedAccelDistanceM1(add1, spd, acc, motmov, 1)

    send_and_verify(rc1, add1, motor=1, command_fn=cmd)
    print("Motor 2 Minus")
    time.sleep(3)
    voltageChange()


def move_three_minus(button=None):
    def cmd():
        rc2.SpeedAccelDistanceM1(add2, spd, acc, motmov, 1)
    
    send_and_verify(rc2, add2, motor=1, command_fn=cmd)
    print("Motor 3 Minus")
    time.sleep(3)
    voltageChange()


def move_four_minus(button=None):
    def cmd():
        rc2.SpeedAccelDistanceM2(add2, spd, -acc, motmov, 1)
    
    send_and_verify(rc2, add2, motor=2, command_fn=cmd)
    print("Motor 4 Minus")
    time.sleep(3)
    voltageChange()


def move_motor_minus(axis):
    if axis.x == -1 and axis.y == 0:
        def cmd():
            rc1.SpeedAccelDistanceM1(add1, spd, acc, motmov, 1)
        send_and_verify(rc1, add1, motor=1, command_fn=cmd)
        print("Motor 2 Minus")
        time.sleep(3)
        voltageChange()

    if axis.x == 0 and axis.y == -1:
        def cmd():
            rc2.SpeedAccelDistanceM1(add2, spd, acc, motmov, 1)
        send_and_verify(rc2, add2, motor=1, command_fn=cmd)
        print("Motor 3 Minus")
        time.sleep(3)
        voltageChange()

    if axis.x == 1 and axis.y == 0:
        def cmd():
            rc2.SpeedAccelDistanceM2(add2, spd, -acc, motmov, 1)
        send_and_verify(rc2, add2, motor=2, command_fn=cmd)
        print("Motor 4 Minus")
        time.sleep(3)
        voltageChange()

    if axis.x == 0 and axis.y == 1:
        def cmd():
            rc1.SpeedAccelDistanceM2(add1, spd, -acc, motmov, 1)
        send_and_verify(rc1, add1, motor=2, command_fn=cmd)
        print("Motor 1 Minus")
        time.sleep(3)
        voltageChange()


def onVoltageRatioInput0_VoltageRatioChange(self, voltageRatio):
    #print("VoltageRatio [0]: " + str(voltageRatio))
    weight0 = voltageRatio*gain0 - offset0 #weight = (voltageRatio - offset0)*gain0
    print("Force [0]: " + str(weight0))
    with open(csv_file, 'a', newline='') as csvfile:
        writer = csv.writer(csvfile)
        writer.writerow([timestamp, weight0, 0, 0, 0])

def onVoltageRatioInput1_VoltageRatioChange(self, voltageRatio):
    #print("VoltageRatio [1]: " + str(voltageRatio))
    weight1 = voltageRatio*gain1 - offset1 #weight = (voltageRatio - offset0)*gain0
    print("Force [1]: " + str(weight1))
    with open(csv_file, 'a', newline='') as csvfile:
        writer = csv.writer(csvfile)
        writer.writerow([timestamp, 0, weight1, 0, 0])

def onVoltageRatioInput2_VoltageRatioChange(self, voltageRatio):
    #print("VoltageRatio [2]: " + str(voltageRatio))
    weight2 = voltageRatio*gain2 - offset2 #weight = (voltageRatio - offset0)*gain0
    print("Force [2]: " + str(weight2))
    with open(csv_file, 'a', newline='') as csvfile:
        writer = csv.writer(csvfile)
        writer.writerow([timestamp, 0, 0, weight2, 0])

def onVoltageRatioInput3_VoltageRatioChange(self, voltageRatio):
    #print("VoltageRatio [3]: " + str(voltageRatio))
    weight3 = voltageRatio*gain3 - offset3 #weight = (voltageRatio - offset0)*gain0
    print("Force [3]: " + str(weight3))
    with open(csv_file, 'a', newline='') as csvfile:
        writer = csv.writer(csvfile)
        writer.writerow([timestamp, 0, 0, 0, weight3])


def voltageChange():
    # Assign any event handlers needed before calling open so that no events are missed
    voltageRatioInput0.setOnVoltageRatioChangeHandler(onVoltageRatioInput0_VoltageRatioChange)
    voltageRatioInput1.setOnVoltageRatioChangeHandler(onVoltageRatioInput1_VoltageRatioChange)
    voltageRatioInput2.setOnVoltageRatioChangeHandler(onVoltageRatioInput2_VoltageRatioChange)
    voltageRatioInput3.setOnVoltageRatioChangeHandler(onVoltageRatioInput3_VoltageRatioChange)

    # Open Phidgets and wait for attachment
    voltageRatioInput0.openWaitForAttachment(5000)
    voltageRatioInput1.openWaitForAttachment(5000)
    voltageRatioInput2.openWaitForAttachment(5000)
    voltageRatioInput3.openWaitForAttachment(5000)


try:
    with Xbox360Controller(0, axis_threshold=0.6) as controller:

        # Initialize CSV file with header
        with open(csv_file, 'w', newline='') as csvfile:
            writer = csv.writer(csvfile)
            writer.writerow(['Timestamp', 'LoadCell1', 'LoadCell2', 'LoadCell3', 'LoadCell4'])

        # Create Phidget channels
        voltageRatioInput0 = VoltageRatioInput()
        voltageRatioInput1 = VoltageRatioInput()
        voltageRatioInput2 = VoltageRatioInput()
        voltageRatioInput3 = VoltageRatioInput()

        # Set addressing parameters to specify which channel to open
        voltageRatioInput0.setChannel(0)
        voltageRatioInput1.setChannel(1)
        voltageRatioInput2.setChannel(2)
        voltageRatioInput3.setChannel(3)

        controller.button_y.when_pressed = move_one_plus
        controller.button_x.when_pressed = move_two_plus
        controller.button_a.when_pressed = move_three_plus
        controller.button_b.when_pressed = move_four_plus
        controller.hat.when_moved = move_motor_minus

        print("Align manipulator upright and balance loads.")
        print("Press LEFT TRIGGER to begin workspace generation...")

        # Wait until left trigger is pressed
        while True:
            if controller.trigger_l.value > 0.5:
                print("Beginning workspace generation sequence...")
                break
            time.sleep(0.1)

        # M1 longitudinal line
        print("Started M1 Longitudinal Line")
        for i in range(longitudinal_path):
            move_one_plus()
            move_three_minus()
            move_two_plus()
            move_two_minus()
            move_four_plus()
            move_four_minus()
            if i == longitudinal_path - 1:
                for j in range(longitudinal_path):
                    move_two_plus()
                    move_two_minus()
                    move_four_plus()
                    move_four_minus()
                    move_one_minus()
                    move_three_plus()
        print("Finished M1 Longitudinal Line")
        time.sleep(3)

        print("Started M1 M2 Longitudinal Line")
        # M1 M2 longitudinal line
        for i in range(longitudinal_path):
            move_one_plus()
            move_two_plus()
            move_three_plus()
            move_three_minus()
            move_four_plus()
            move_four_minus()
            move_three_minus()
            move_four_minus()
            if i == longitudinal_path - 1:
                for j in range(longitudinal_path):
                    move_three_plus()
                    move_three_minus()
                    move_four_plus()
                    move_four_minus()
                    move_one_minus()
                    move_two_minus()
                    move_three_plus()
                    move_four_plus()
        print("Finished M1 M2 Longitudinal Line")
        time.sleep(3)

        print("Started M2 Longitudinal Line")
        # M2 longitudinal line
        for i in range(longitudinal_path):
            move_two_plus()
            move_three_plus()
            move_three_minus()
            move_one_plus()
            move_one_minus()
            move_four_minus()
            if i == longitudinal_path - 1:
                for j in range(longitudinal_path):
                    move_three_plus()
                    move_three_minus()
                    move_one_plus()
                    move_one_minus()
                    move_two_minus()
                    move_four_plus()
        print("Finished M2 Longitudinal Line")
        time.sleep(3)

        print("Started M2 M3 Longitudinal Line")
        # M2 M3 longitudinal line
        for i in range(longitudinal_path):
            move_two_plus()
            move_three_plus()
            move_four_plus()
            move_four_minus()
            move_one_plus()
            move_one_minus()
            move_four_minus()
            move_one_minus()
            if i == longitudinal_path - 1:
                for j in range(longitudinal_path):
                    move_four_plus()
                    move_four_minus()
                    move_one_plus()
                    move_one_minus()
                    move_three_minus()
                    move_two_minus()
                    move_one_plus()
                    move_four_plus()
        print("Finished M2 M3 Longitudinal Line")
        time.sleep(3)
        
        print("Started M3 Longitudinal Line")
        # M3 longitudinal line
        for i in range(longitudinal_path):
            move_three_plus()
            move_four_plus()
            move_four_minus()
            move_two_plus()
            move_two_minus()
            move_one_minus()
            if i == longitudinal_path - 1:
                for j in range(longitudinal_path):
                    move_four_plus()
                    move_four_minus()
                    move_two_plus()
                    move_two_minus()
                    move_three_minus()
                    move_one_plus()
        print("Finished M3 Longitudinal Line")
        time.sleep(3)
        
        print("Started M3 M4 Longitudinal Line")
        # M3 M4 longitudinal line
        for i in range(longitudinal_path):
            move_three_plus()
            move_four_plus()
            move_one_plus()
            move_one_minus()
            move_two_plus()
            move_two_minus()
            move_one_minus()
            move_two_minus()
            if i == longitudinal_path - 1:
                for j in range(longitudinal_path):
                    move_one_plus()
                    move_one_minus()
                    move_two_plus()
                    move_two_minus()
                    move_three_minus()
                    move_four_minus()
                    move_one_plus()
                    move_two_plus()
        print("Finished M3 M4 Longitudinal Line")
        time.sleep(3)

        
        print("Started M4 Longitudinal Line")
        # M4 longitudinal line
        for i in range(longitudinal_path):
            move_four_plus()
            move_one_plus()
            move_one_minus()
            move_three_plus()
            move_three_minus()
            move_two_minus()
            if i == longitudinal_path - 1:
                for j in range(longitudinal_path):
                    move_one_plus()
                    move_one_minus()
                    move_three_plus()
                    move_three_minus()
                    move_four_minus()
                    move_two_plus()
        print("Finished M4 Longitudinal Line")
        time.sleep(3)
        
        print("Started M4 M1 Longitudinal Line")
        # M4 M1 longitudinal line
        for i in range(longitudinal_path):
            move_four_plus()
            move_one_plus()
            move_two_plus()
            move_two_minus()
            move_three_plus()
            move_three_minus()
            move_two_minus()
            move_three_minus()
            if i == longitudinal_path - 1:
                for j in range(longitudinal_path):
                    move_two_plus()
                    move_two_minus()
                    move_three_plus()
                    move_three_minus()
                    move_one_minus()
                    move_four_minus()
                    move_three_plus()
                    move_two_plus()
        print("Finished M4 M1 Longitudinal Line")
        time.sleep(3)
        
        print("Workspace generation complete. Manipulator returned upright.")
        signal.pause()

except KeyboardInterrupt:
    print("Process interrupted by user.")
    # Close Phidgets devices
    voltageRatioInput0.close()
    voltageRatioInput1.close()
    voltageRatioInput2.close()
    voltageRatioInput3.close()
    pass


