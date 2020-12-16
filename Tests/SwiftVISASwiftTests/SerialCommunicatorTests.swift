import XCTest
@testable import SwiftVISASwift

/// Tests for communicating with a Keysight E36103B Oscilliscope over Serial.
final class SerialCommunicatorTests: XCTestCase {
	/// The communicator to use for the tests.
	static var communicator: USBInstrument!
	
	func testList() {
		USBInstrument.listPorts()
	}
	
	static var allTests = [
		("testList", testList)
	]
}

