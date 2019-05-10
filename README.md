#Feature
  1. Temperature: Yes
  2. Huminity: No
  3. Communication Error indicator: Yes 
  4. Display: 7segments Leds
  5. Temp resolution: 14bit
  6. dspclk: 100Mhz 
  7. Sensor clock: 100Khz
  8. Measurement frequency: Button base trigger
  9. Status register access: No (Default operating mode)

# sht10_fpga

[I] Issue status: 
  CLOSED: 4, 5, 7, 8, 9
  OPENED: 1, 2, 3, 6 
  TOTAL/OPENED/CLOSED: 9/4/5
  
[II] Issue list: 
1. Power supply. [AI] 
Supply Voltage (VDD) and Ground (GND) must be decoupled with a 100 nF capacitor. 

2. FPGA must only drive LOW to DATA pin. DATA pin should have pull-up.[Done] setup pullup mode for output pin of FPGA.
[QA] What is the resistor on module ? what happen if there are 2 pullup places for DATA pin ?

To avoid signal contention the microcontroller must only drive DATA low. An external pull-up resistor (e.g. 10kV) is required to pull the signal high – it should be noted that pull-up resistors may be included in I/O circuits of microcontrollers. See Table 2 for detailed I/O characteristic of the sensor.

3. Wiring awareness. [AI] Same as [1]
1.9 Wiring Considerations and Signal Integrity: 
Carrying the SCK and DATA signal parallel and in close proximity (e.g. in wires) for more than 10cm may result in cross talk and loss of communication. This may be resolved by routing VDD and/or GND between the two data signals and/or using shielded cables. Furthermore, slowing down SCK frequency will possibly improve signal integrity. Power supply pins (VDD, GND) must be decoupled with a 100nF capacitor if wires are used. Capacitor should be placed as close to the sensor as possible. Please see the Application Note “ESD, Latchup and EMC” for more information.

4. Add reset sequence. [AI] --> Change code.
It is unsured that the device can operate normally after starting from system reset. It should be "transmission reset" from beginning of a data communication.

5. Thold and Tsetup of data from FPGA: [AI]
--> check again the code to make sure it follow the timing specification of the spec to the IC.

6. Timing violation of RH calculation logic.
--> when we have the temperature done, we will fix the RH.

7. communication error logic: [AI]
--> detect the Non-ACK from Sensor. If there is one, turn the Erorr indicator led on.

8. DATA timing. 
--> Write Data from FPGA is available same timing with clock pulse. Notice about the Tsu and Thd
--> Read Data from Sensor is available 1 pusle later. Take note when capturing data from sensor.

9. ACK1 has wrong level .
--> It should be LOW instead of HIGH.
