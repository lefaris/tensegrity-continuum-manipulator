from Phidget22.Phidget import *
from Phidget22.Devices.VoltageRatioInput import *
import time

gain0 = 56230
offset0 = 2.8131
gain1 = 56251
offset1 = 5.1885
gain2 = 56145
offset2 = 0.3451
gain3 = 56145
offset3 = 1.2198
#calibrated = False


def onVoltageRatioInput0_VoltageRatioChange(self, voltageRatio):
	#print("VoltageRatio [0]: " + str(voltageRatio))
	weight0 = voltageRatio*gain0 - offset0 #weight = (voltageRatio - offset0)*gain0
	print("Force [0]: " + str(weight0))

def onVoltageRatioInput1_VoltageRatioChange(self, voltageRatio):
	#print("VoltageRatio [1]: " + str(voltageRatio))
	weight1 = voltageRatio*gain1 - offset1 #weight = (voltageRatio - offset0)*gain0
	print("Force [1]: " + str(weight1))

def onVoltageRatioInput2_VoltageRatioChange(self, voltageRatio):
	#print("VoltageRatio [2]: " + str(voltageRatio))
	weight2 = voltageRatio*gain2 - offset2 #weight = (voltageRatio - offset0)*gain0
	print("Force [2]: " + str(weight2))

def onVoltageRatioInput3_VoltageRatioChange(self, voltageRatio):
	#print("VoltageRatio [3]: " + str(voltageRatio))
	weight3 = voltageRatio*gain3 - offset3 #weight = (voltageRatio - offset0)*gain0
	print("Force [3]: " + str(weight3))

def main():
	#Create your Phidget channels
	voltageRatioInput0 = VoltageRatioInput()
	voltageRatioInput1 = VoltageRatioInput()
	voltageRatioInput2 = VoltageRatioInput()
	voltageRatioInput3 = VoltageRatioInput()

	#Set addressing parameters to specify which channel to open (if any)
	voltageRatioInput0.setChannel(0)
	voltageRatioInput1.setChannel(1)
	voltageRatioInput2.setChannel(2)
	voltageRatioInput3.setChannel(3)

	#Assign any event handlers you need before calling open so that no events are missed.
	voltageRatioInput0.setOnVoltageRatioChangeHandler(onVoltageRatioInput0_VoltageRatioChange)
	voltageRatioInput1.setOnVoltageRatioChangeHandler(onVoltageRatioInput1_VoltageRatioChange)
	voltageRatioInput2.setOnVoltageRatioChangeHandler(onVoltageRatioInput2_VoltageRatioChange)
	voltageRatioInput3.setOnVoltageRatioChangeHandler(onVoltageRatioInput3_VoltageRatioChange)

	#Open your Phidgets and wait for attachment
	voltageRatioInput0.openWaitForAttachment(5000)
	voltageRatioInput1.openWaitForAttachment(5000)
	voltageRatioInput2.openWaitForAttachment(5000)
	voltageRatioInput3.openWaitForAttachment(5000)

	#Do stuff with your Phidgets here or in your event handlers.

	try:
		input("Press Enter to Stop\n")
	except (Exception, KeyboardInterrupt):
		pass

	#Close your Phidgets once the program is done.
	voltageRatioInput0.close()
	voltageRatioInput1.close()
	voltageRatioInput2.close()
	voltageRatioInput3.close()

main()