<img src="https://github.com/SwiftVISA/CoreSwiftVISA/blob/master/SwiftVISA%20Logo.png" width="512" height="512">

# SwiftVISASwift

SwiftVISASwift allows for message based communication over the VISA protocol for TCPIP instruments. SwiftVISASwift is a native backend and does not require the user to have NI-VISA installed.

## Requirements

- Swift 5.0+  (Swift 5.5+ required for `actor` branch)
- macOS 10.11.6+ (macOS 12.0+ required for `actor` branch)
- Ubuntu 16.04 (or 16.10 but only tested on 16.04)
- Other versions of Linux *may* work, but have not been tested

## Installation

Installation can be done through the [Swift Package Manager](https://swift.org/package-manager/). To use SwiftVISASwift in your project, include the following dependency in your `Package.swift` file.
```swift
dependencies: [
    .package(url: "https://github.com/SwiftVISA/SwiftVISASwift.git", .upToNextMinor(from: "0.1.0"))
]
```

SwiftVISASwift automatically exports [CoreSwiftVISA](https://github.com/SwiftVISA/CoreSwiftVISA), so `import SwiftVISASwift` is sufficient for importing CoreSwiftVISA.

Installation can also be done using Xcode's built-in support for adding Swift Package Dependencies.  An example using Xcode 14.2 is as follows:

First, navigate to the SwiftVISASwift Github page and copy the URL SwiftVISASwift source:

<img style="text-align: center;"
           src="https://github.com/SwiftVISA/SwiftVISASwift/blob/main/docs/img/Setup_1_github.png" width="748" height="640">

Second, start a new Xcode project:

<img style="text-align: center;"
           src="https://github.com/SwiftVISA/SwiftVISASwift/blob/main/docs/img/Setup_2_createNewProject.png" width="914" height="578">

Third, select the type of application.  SwiftVISASwift has been verified to work on macOS and App, Document App, and Command Line Utilites:

<img style="text-align: center;"
           src="https://github.com/SwiftVISA/SwiftVISASwift/blob/main/docs/img/Setup_3_selectAppType.png" width="756" height="506">

Fourth, navigate to the Project → Package Dependencies and select "+" to begin adding the package dependency:

<img style="text-align: center;"
           src="https://github.com/SwiftVISA/SwiftVISASwift/blob/main/docs/img/Setup_4_startPackageDependency.png" width="756" height="506">

Fifth, paste the URL to the SwiftVISASwift source copied earlier from Github into the upper-right corner's search textfield.  The SwiftVISASwift package should show up on the middle-right list.  Select this package, you can set the branch to either `main` or `actor`.  Currently, `main` branch uses a `Class` as the PrinterController while the `actor` branch uses an `Actor` as the PrinterController.  In our own work, we've switched to using the `actor` branch to better reflect sending and receiving instruments commands can be a blocking action.

<img style="text-align: center;"
           src="https://github.com/SwiftVISA/SwiftVISASwift/blob/main/docs/img/Setup_5_addSwiftVISASwiftPackage.png" width="756" height="506">

Sixth and last, check your Signings and Capabilities by navigating to Targets → Signings and Capabilities.  The easiest settings to use are **Automatically manage Signing** set to _Yes/Checked_ and **Signing Certificate** to _Sign to Run Locally_.  Other settings can be used if you have an Apple ID Developer Account and Certificate:

<img style="text-align: center;"
           src="https://github.com/SwiftVISA/SwiftVISASwift/blob/main/docs/img/Setup_6_signingAndPermissions.png" width="756" height="506">

## Usage

To create a connection to an instrument over TCPIP, pass the network details to `InstrumentManager.shared.instrumentAt(address:port:)`;
```swift
do {
  // Pass the IPv4 or IPv6 address of the instrument to "address" and the insturment's port to "port".
  let instrument = try InstrumentManager.shared.instrumentAt(address: "10.0.0.1", port: 5025)
} catch {
  // Could not connect to instrument
}
```

To write to the instrument, call `write(_:)` on the instrument:
```swift
do {
  // Pass the command as a string.
  try instrument.write("OUTPUT ON")
} catch {
  // Could not write to instrument
}
```

To read from the instrument, call `read()` on the instrument:
```swift
do {
  try instrument.write("VOLTAGE?")
  let voltage = try instrument.read() // read() will return a String
} catch {
  // Could not read from (or write to) instrument
}
```

To query the instrument, call `query(_:)` on the instrument. Query will first write the message provided to the instrument, then read from the instrument and return the given string. To decode the message from the instrument into another type, call `query(_:as:)`:
```swift
do {
  let voltage = try instrument.query("VOLTAGE?" as: Double.self) // query(_:as:) will return a Double because Double.self was passed to "as".
} catch {
  // Could not query or decode from instrument
}
```

## Customization

SwiftVISASwift supports a great deal of customization for communicating to/from instruments. To customize how SwiftVISASwift sends messages, call `write(_:appending:encoding:)`. Pass the termination character/string to "appending", and pass the string encoding you would like to use to "encoding". Both of these parameters have defualt values, so you may ommit parameters that you don't need to customize. By default, the terminating character is "/n" and the encoding is UTF8:
```swift
do {
  let voltage = try instrument.write("OUTPUT OFF", appending: "\0", encoding: .ascii)
} catch {
  // Could not write to instrument
}
```

To customize how SwiftVISASwift reads messages, call `read(until:strippingTerminator:encoding:chunkSize:)`. Pass a custom termination character/string to `until`. Pass `false` to `strippingTerminator` if you would like SwiftVISASwift to keep the terminator on the end of the sting (by default this is removed). Pass the string encoding you would like to use to `encoding`. `chunkSize` can be set to limit the number of bytes that is requested from the instrument at a time; for long messages, SwiftVISASwift breaks up the reading into multiple smaller reads. These three parameters all have default values, so you may ommit parameters that you don't need to customize. By default, the terminating character/string is "\n" and is stripped, the encoding is UTF8, and the chunk size is 1024 bytes:
```swift
do {
  try instrument.write("VOLTAGE?")
  let voltage = try instrument.read(until: "\0", strippingTerminator: false, encoding: .ascii, chunkSize: 256)
} catch {
  // Could not read from (or write to) instrument
 }
 ```
 
 To customize the defaults used for an instrument, you can set the properties on the `attributes` property of the insturment. The following values can be customized: `chunkSize`, `encoding`, `operationDelay`, `readTerminator`, and `writeTerminator`. These attributes correspond to the additional arguments above for `read()` and `write(_:)`. The attribute `operationDelay` is used to customize how much time the computer shoud wait between calls to `read()` and `write(_:)`. Some instruments will stop working correctly if messages are sent too quickly so a a small amount of time is waited before sending each message. By deault, this value is 1 ms. Each instrument can have its own custom attributes. Setting the attributes on one instrument will not change the attributes of other instruments:
```swift
// Sets the attributes to SwiftVISASwift's default values
instrument.chunkSize = 1024 // Set the default chunk size for reading long messages
instrument.encoding = .utf8 // Set the encoding to use for reading and writing messages
instrument.operationDelay = 1e-3 // Set the number of seconds to wait before sending each message
instrument.readTerminator = "\n" // Set the character/string that indicates an end of a message from the instrument
instrument.writeTermiantor = "\n" // Set the character/string that indicates an end of the message to the instrument
```

To customize how SwiftVISASwift decodes types, you can create your own custom decoders. To create a custom decoder, create a struct that conforms to the `MessageDecoder` protocol. You will need to declare the type you wish to decode to as `DeccodingType`, and you will need to implement `decode(_:)`:
```swift
// The following decoder returns an Int rounded to the nearest interger:
struct RoundingDecoder: MessageDecoder {
  typealias DecodingType = Int
  
  // Define an Error enum if you would like to throw custom errors
  enum Error: Swift.Error {
    case notANumber
     case magnitudeTooLarge
  }
  
  func decode(_ message: String) throws -> DecodingType {
    guard let number = Double(message) else {
      // If the message can't be converted into a Double, then it's not a number
      throw Error.notANumber
    }
    guard !number.isNaN else {
      // If the number is NAN, then it's not a number
      throw Error.notANumber
    }
    
    let rounded = round(number)
    
    guard let integer = Int(exactly: rounded) else {
      // If the number can't be expressed exaclty as an integer after rounding, it's magnitude is too large
      throw Error.magnitudeTooLarge
    }

    return integer
  }
}
```

Included with SwiftVISASwift (actually in CoreSwiftVISA) are four default decoders: `DefaultStringDecoder`, `DefaultIntDecoder`, `DefaultDoubleDecoder`, and `DefaultBoolDecoder`. When decoding when calling query, if no decoder is passed in, one of the decoders aboved will be automatically used (depending on which type is used). To change which decoder will be used automatically, you can set the `customDecode` property to be a custom decoding function on `DefaultStringDecoder`, `DefaultIntDecoder`, `DefaultDoubleDecoder`, or `DefaultBoolDecoder`:
```swift
// Set default decoder
DefaultIntDecoder.customDecode = RoundingDecoder().decode(_:)
do {
  let voltage = instrument.query("VOLTAGE?", as: Int.self)
  // Can also use a custom decoder without changing the default decoder
  let sameVoltage = instrument.query("VOLTAGE?", as: Int.self, using RoundingDecoder())
} catch {
  // Could not query or decode
}
```

## Example Setup Video
The SwiftVISASwift repository includes an example command-line application that connects to a Keysight E36103B Power Supply over TCP/IP.  This is a good starting point to learn the basics of setting up and using SwiftVISASwift.  Below is a link to a video showing how that project was made so you can follow along yourself.
https://www.youtube.com/watch?v=xtMUPxH92GI

### ExampleSwiftVISASwift code:
    
    import Foundation
    import SwiftVISASwift
    
    print("Starting Example")
    
    let ipAddress = "169.254.10.1"
    let port = 5025
    
    var instrumentManager: InstrumentManager?
    var instrument: MessageBasedInstrument?
    
    func makeInstrument() throws {
        if instrumentManager == nil {
            instrumentManager = InstrumentManager.shared
        }
    
        instrument = try instrumentManager?.instrumentAt(address: ipAddress, port: port)
    }
    
    func getInfo() {
        do {
            let details = try instrument?.query("*IDN?") ?? ""
            print(details)
        } catch  {
           print("Cound not get instrument information")
           print(error)
        }
    }

    func updateMeasuredVoltage() {
        do {
            let measuredVoltage = try instrument?.query("SOURCE:VOLTAGE?", as: Double.self)
            print("Measured Voltage = \(String(describing: measuredVoltage))")
        } catch  {
            print("Could not measure voltage")
            print(error)
        }
    }

    func connect() {
        do {
            try makeInstrument()
        } catch  {
            print("Could not connect to instrument at: \(ipAddress) on port: \(port)")
            print(error)
            return
        }
    
       print("instrument conenected: \(String(describing: instrument))")
        updateMeasuredVoltage()
        getInfo()
    }
    
    connect()


## Contributions and Comments
This project is a slow-moving "labor-of-love" for our group and intended additional features, such as USB support, are worked on sporatically based upon need, time, and our ability to deal with Apple's poor documentation.  We would love help and please e-mail me (or to reply to the relevant issue or open a new one).

When contributing to this repository, please first discuss the change you wish to make via issue, email, or any other method with the owner of this repository before making a change.

### All Code Changes Happen Through Pull Requests

1. Fork the repo and create your branch from `master`.
2. Make sure the syle of your code is consistent with that of the current one (indentation, etc.).
3. If you've changed any relevant functionalities, update the documentation.
4. Ensure the application is working correctly.
5. Issue that pull request.

### Code of Conduct

Use common sense (source: https://github.com/gasparl/possa/blob/master/CONTRIBUTING.md)

Examples:

* Be respectful of differing viewpoints and experiences
* Gracefully accept constructive criticism
* Focus on what is best for the community
* Have empathy towards other community members

Examples of unacceptable behavior by participants include:

* Trolling, insulting/derogatory comments, and personal or political attacks
* Public or private harassment
* Publishing others' private information without explicit permission
* Other conduct which could reasonably be considered inappropriate in a
  professional setting
  
 
### Reporting Issues or Problems
* Please submit an Issue if you have any problems with any SwiftVISA frameworks/packages
* Please submit an Issue if you need any help installing or working with any of the SwiftVISA Frameworks/Packages
