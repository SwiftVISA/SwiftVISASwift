//
//  File.swift
//  
//
//  Created by Connor Barnes on 12/28/20.
//

import Foundation
import CoreSwiftVISA
import Socket

/// A class representing a connection over TCPIP.
class TCPIPSession {
	/// The socket used for communicating with the instrument.
	var socket: Socket
	/// The address of the instrument.
	let address: String
	/// The port of the instrument.
	let port: Int
	
	typealias Error = TCPIPInstrument.Error
	/// Creates a session to an instrument at the given address and port.
	///
	/// The function will throw a timeout error after `timeout` number of seconds have elapsed.
	/// - Parameters:
	///   - address: The IPv4 or IPv6 address of the instrument to connect to.
	///   - port: The port to connect to.
	///   - timeout: The maximum amout of time to try to connect to the instrument.
	/// - Throws: If an error occured while establishing the session.
	init(address: String, port: Int, timeout: TimeInterval) throws {
		try socket = Self.rawSocket(atAddress: address, port: port, timeout: timeout)
		
		self.address = address
		self.port = port
	}
}

// MARK:- Raw Sockets
extension TCPIPSession {
	private static func rawSocket(
		atAddress address: String,
		port: Int,
		timeout: TimeInterval
	) throws -> Socket {
		var socket: Socket
		
		do {
			// TODO: Support IVP6 addresses (family: .net6)
			socket = try Socket.create(family: .inet, type: .stream, proto: .tcp)
		} catch { throw Error.couldNotCreateSocket }
		
		// TODO: XPSQ8 sent data in packets of 1024. What size packets does VISA use?
		socket.readBufferSize = 1024
		
		do {
			// TODO: We might need to specify a timeout value here. It says adding a timeout can put it into non-blocking mode, and I'm not sure What that will do.
			try socket.connect(to: address, port: Int32(port))
		} catch { throw Error.couldNotConnect }
		
		do {
			// Timeout is set as an integer in milliseconds, but it is clearer to pass in a TimeInterval into the function because TimeInterval is used
			// thoughout Foundation to represent time in seconds.
			let timeoutInMilliseconds = UInt(timeout * 1_000.0)
			try socket.setReadTimeout(value: timeoutInMilliseconds)
			try socket.setWriteTimeout(value: timeoutInMilliseconds)
		} catch { throw Error.couldNotSetTimeout }
		
		do {
			// We want to user to manage multithreding, so use blocking.
			try socket.setBlocking(mode: true)
		} catch { throw Error.couldNotEnableBlocking }
		
		return socket
	}
}

// MARK:- Session
extension TCPIPSession: Session {
	func close() {
		// Close the connection to the socket because we will no longer need it.
		socket.close()
	}
	
	func reconnect(timeout: TimeInterval) throws {
		socket.close()
		try socket = Self.rawSocket(atAddress: address, port: port, timeout: timeout)
	}
}
