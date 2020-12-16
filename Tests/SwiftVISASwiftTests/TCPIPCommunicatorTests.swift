import XCTest
@testable import SwiftVISASwift

/// Tests for communicating with a Keysight E36103B Oscilliscope over TCPIP.
final class TCPIPCommunicatorTests: XCTestCase {
	/// The communicator to use for the tests.
	static var communicator: TCPIPInstrument!
	/// The LAN information for the instrument.
	static var lanInfo = (address: "169.254.10.1", port: 5025)
	
	override class func setUp() {
		communicator = try? .init(address: Self.lanInfo.address,
															port: Self.lanInfo.port,
															timeout: 5.0)
	}
	
	/// Tests writing to the instrument.
	///
	/// The write command sould not throw an error. Further, the instrument's output should turn on.
	func testWrite() {
		// A sample write-only command.
		let command = "OUTPUT ON"
		
		do {
			try Self.communicator.write(command)
		} catch {
			XCTFail("Failed to write \"\(command)\" with error: \(error)")
		}
	}
	
	/// Tests reading from the instrument.
	///
	/// The write and read commands should not throw an error.
	func testRead() {
		// A sample write-read command.
		let command = "VOLTAGE?"
		
		do {
			try Self.communicator.write(command)
			_ = try Self.communicator.read()
		} catch {
			XCTFail("Failed to read \"\(command)\" with error: \(error)")
		}
	}
	
	/// Tests reading from the instrument when it should not be able to.
	///
	/// The command specified is write-only, so the read operation should fail and throw an error. The write operation should not throw an error.
	func testCantRead() {
		// A sample write-only command.
		let command = "OUTPUT OFF"
		
		do {
			try Self.communicator.write(command)
		} catch {
			XCTFail("Failed to write \"\(command)\" with error: \(error)")
		}
		do {
			_ = try Self.communicator.read()
			XCTFail("Read when no text returned \"\(command)\"")
		} catch {
			// We want this to throw
			return
		}
	}
	
	static var allTests = [
		("testWrite", testWrite),
		("testRead", testRead),
		("testCantRead", testCantRead)
	]
}
