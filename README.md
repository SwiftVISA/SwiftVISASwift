<img src="https://github.com/SwiftVISA/CoreSwiftVISA/blob/master/SwiftVISA%20Logo.png" width="512" height="512">

# SwiftVISASwift

SwiftVISASwift allows for message based communication over the VISA protocol for TCPIP instruments. SwiftVISASwift is a native backend and does not require the user to have NI-VISA installed.

## Requirements

- Swift 5.5+
- macOS 12.0+
- Linux *may* work, but it has not been tested.

## Installation

Installation can be done through the [Swift Package Manager](https://swift.org/package-manager/). To use SwiftVISASwift in your project, include the following dependency in your `Package.swift` file.
```swift
dependencies: [
    .package(url: "https://github.com/SwiftVISA/SwiftVISASwift.git", .branch("actor"))
]
```

SwiftVISASwift automatically exports [CoreSwiftVISA](https://github.com/SwiftVISA/CoreSwiftVISA), so `import SwiftVISASwift` is sufficient for importing CoreSwiftVISA.
