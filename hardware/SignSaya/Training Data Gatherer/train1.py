import serial, time

# Configure the serial port
ser = serial.Serial(
    port='COM6',  # Replace 'COM6' with the actual port your ESP32-S3 is connected to
    baudrate=115200,  # Standard ESP32 baudrate
    timeout=3  # Adjust timeout if needed
)

# Check if the port is open
if ser.isOpen():
    print("Serial port is open.")
    filename = input("Please Type the filename: ")
    filename += "COM6"+"_" + str(time.time())
    print(f"saving the file as {filename}.csv")
    with open(f"{filename}.csv",'a') as currentFile:
        currentFile.write("timestamp,thumb,index,middle,ring,pinky,quaternionX,quaternionY,quaternionZ,quaternionW") 
        currentFile.write("\n")
    while True:
        try:
            # Read data from the serial port
            data = ser.readline().decode('utf-8').rstrip()

            # Only process if data is received
            if data: 
                with open(f"{filename}.csv",'a') as currentFile:
                    currentFile.write(str(time.time()))
                    currentFile.write(data) 
                    currentFile.write("\n")

        except KeyboardInterrupt:
            print("Exiting")
            break

else:
    print("Error: Could not open serial port.")

# Close the serial port
ser.close()
