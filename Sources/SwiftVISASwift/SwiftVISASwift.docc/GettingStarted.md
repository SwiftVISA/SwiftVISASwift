# Getting Started

Connect to an instrument over TCPIP and read and write data to/from the instrument.

## Setup

The first step is to connect the VISA instrument to your computer over TCPIP. You will need to know the IP address and port of the instrument. For this article we will assume that the IP address is `169.254.10.1` and the port is `5025`. 

## Connecting to the Instrument

The following will try to connect to the instrument:

```swift
func connectToInstrument() async throws -> MessageBasedInstrument {
  return try await InstrumentManager.shared.instrumentAt(
    address: "169.254.10.1",
    port: 5025
  )
}
```

This function is marked async, as connecting to the instrument may take some time. Further, the function can throw as the instrument may fail when trying to connect.  Check ``TCPIPInstrument/Error`` for information about the thrown error.

## Writing to the Instrument

We are using a Keysight E36103B DC Power Supply. You may follow along with another instrument, however the commands we send to our instrument may not work with other instruments. If you have another instrument try sending commands you know work with your instrument.

We will send the command `"OUTPUT ON"` to our instrument, which will turn on our instrument's display. Before we do this, we will turn off the display so that we know if the connection to our instrument is working. The following should turn our instrument's display on:

```swift
// Note: This must be called in an async throws environment 
try await instrument.write("OUTPUT ON")
```

## Reading from the Instrument

We will now try to read some data from our instrument. We will send the `"VOLTAGE?"` command which should return the voltage:

```swift
try await instrument.write("VOLTAGE?")
let voltage = try await instrument.read()
```

In the example above, `voltage` will be set to a `String` of the data returned by the instrument. 

## Querying

A common pattern in communication with instruments is querying. This is when you send a command to the instrument and immediately read back data from the instrument after. As above, we can accomplish this with a call to `write` followed by a call to `read`. `SwiftVISA` however provides a convenience method for this called `query`. `query` takes the message you would like to send, writes it to the instrument, and then reads back the data from the instrument. You can also specify a type to decode the message to:

```swift
let voltage = try await instrument.query("VOLTAGE?" as: Double.self)
```

## Conclusion

You have now seen how to connect to, write to, and read from an instrument that is connected over TCPIP. 
