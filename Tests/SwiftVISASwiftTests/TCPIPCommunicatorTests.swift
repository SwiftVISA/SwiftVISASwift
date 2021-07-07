import XCTest
@testable import SwiftVISASwift

/// Tests for communicating with a Keysight E36103B Oscilliscope over TCPIP.
final class TCPIPCommunicatorTests: XCTestCase {
	/// The communicator to use for the tests.
	static var communicator: MessageBasedInstrument?
  
	/// The LAN information for the instrument.
	static var lanInfo = (address: "169.254.10.1", port: 5025)
  
  override class func setUp() {
    unsafeWaitFor {
      let im = InstrumentManager.shared
      communicator = try? await im.instrumentAt(address: lanInfo.address,
                                                port: lanInfo.port,
                                                timeout: 5.0)
    }
	}
  
	/// Tests that the instrument was successfully connected to.
	func testInstrumentConnected() {
		if Self.communicator == nil {
			XCTFail("Failed to connect to instrument")
		}
	}
	
	/// Tests writing to the instrument.
	///
	/// The write command sould not throw an error. Further, the instrument's output should turn on.
	func testWrite() async {
		guard let communicator = Self.communicator else { return }
		
		// A sample write-only command.
		let command = "OUTPUT ON"
		
		do {
			try await communicator.write(command)
		} catch {
			XCTFail("Failed to write \"\(command)\" with error: \(error)")
		}
	}
	/// Tests reading from the instrument.
	///
	/// The write and read commands should not throw an error.
	func testQuery() async {
		guard let communicator = Self.communicator else { return }
		
		// A sample write-read command.
		let command = "VOLTAGE?"
		
		do {
			_ = try await communicator.query(command)
		} catch {
			XCTFail("Failed to read \"\(command)\" with error: \(error)")
		}
	}
  
	/// Tests reading from the instrument when it should not be able to.
	///
	/// The command specified is write-only, so the read operation should fail and throw an error. The write operation should not throw an error.
	func testCantQuery() async {
		guard let communicator = Self.communicator else { return }
		
		// A sample write-only command.
		let command = "OUTPUT OFF"
		
		do {
			try await communicator.write(command)
		} catch {
			XCTFail("Failed to write \"\(command)\" with error: \(error)")
		}
		
		do {
			_ = try await communicator.read()
			XCTFail("Read when no text returned \"\(command)\"")
		} catch {
			// We want this to throw
			return
		}
	}
  
	/// Test that the session is actually ended when `close()` is called.
	func testClose() async {
		guard let communicator = Self.communicator else { return }
		
		let commands = ["VOLTAGE?", "OUTPUT OFF"]
		
		defer {
			// The connection may be closed, so reset the connection
			Self.setUp()
		}
		
		do {
			try await communicator.write(commands[0])
		} catch {
			XCTFail("Failed to write \"\(commands[0])\" with error: \(error)")
		}
		
		do {
			try await communicator.session.close()
		} catch {
			XCTFail("Failed to close instrument")
		}
		
		testRead:
		do {
			_ = try await communicator.read()
			XCTFail("Successfully read from instrument after closing")
		} catch {
			guard let error = error as? TCPIPInstrument.Error else {
				XCTFail("Error was of wrong type")
				break testRead
			}
			
			XCTAssertEqual(error, .couldNotConnect)
		}
		
		do {
			try await communicator.write(commands[1])
			XCTFail("Seccessfully wrote to instrument after closing")
		} catch {
			// We want this to throw
		}
	}
	
	static var allTests = [
		("testWrite", testWrite),
		("testQuery", testQuery),
		("testCantRead", testCantQuery),
		("testClose", testClose)
	]
}

// MARK: - Unsafe Wait For
func unsafeWaitFor(_ operation: @escaping () async -> ()) {
  let semaphore = DispatchSemaphore(value: 0)
  Task {
    await operation()
    semaphore.signal()
  }
  semaphore.wait()
}
