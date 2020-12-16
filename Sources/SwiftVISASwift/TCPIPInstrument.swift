//
//  TCPIPInstrument.swift
//  
//
//  Created by Connor Barnes on 9/13/20.
//

import Foundation
import Socket

/// An instrument connected over TCP-IP.
public final class TCPIPInstrument {
	/// The socket used for communicating with the instrument.
	internal let socket: Socket
	/// Attributes to control the communication with the instrument.
	public var attributes = InstrumentAttributes()
	/// Tries to create an instance from the specified address, and port of the instrument. A timeout value must also be specified.
	///
	/// - Parameters:
	///   - address: The IPV4 address of the instrument in dot notation.
	///   - port: The port of the instrument.
	///   - timeout: The maximum time to wait before timing out when communicating with the instrument.
	///
	/// - Throws: An error if a socket could not be created, connected, or configured properly.
	public init(address: String, port: Int, timeout: TimeInterval) throws {
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
	}
	
	deinit {
		// Close the connection to the socket because we will no longer need it.
		socket.close()
	}
}

// MARK: Communicator
extension TCPIPInstrument: MessageBasedInstrument {
	public func read(
		until terminator: String,
		strippingTerminator: Bool,
		encoding: String.Encoding,
		chunkSize: Int
	) throws -> String {
		// The message may not fit in a single chunk. To overcome this, we continue to request data until we are at the end of the message.
		// Continue until `string` ends in the terminator.
		var string = String()
		var chunk = Data(capacity: chunkSize)
		
		socket.readBufferSize = chunkSize
		
		repeat {
			do {
				let bytesRead = try socket.read(into: &chunk)
				
				guard let substring = String(bytes: chunk[..<bytesRead], encoding: encoding)
				else {
					throw Error.couldNotDecode
				}
				
				string += substring
				
				if bytesRead == 0 {
					// No more data to read (even if we aren't at the terminator)
					if string.count == 0 {
						// No data read at all
						throw Error.failedReadOperation
					}
					
					break
				}
			}
			// TODO: don't check the whole string for containing the terminator, only check the last chunk and enough characters before in case the terminator is split over multiple chunks
		} while !string.contains(terminator)
		
		if let terminatorRange = string.range(of: terminator, options: .backwards) {
			if strippingTerminator {
				return String(string[..<terminatorRange.lowerBound])
			} else {
				return String(string[..<terminatorRange.upperBound])
			}
		}
		
		return string
	}
	
	public func readBytes(length: Int, chunkSize: Int) throws -> Data {
		var data = Data(capacity: max(length, chunkSize))
		var chunk = Data(capacity: chunkSize)
		
		socket.readBufferSize = chunkSize
		
		repeat {
			do {
				let bytesRead = try socket.read(into: &chunk)
				
				data.append(chunk)
				
				if bytesRead == 0 {
					// No more data to read
					return data
				}
			}
		} while data.count < length
		
		return data[..<length]
	}
	
	public func readBytes(
		maxLength: Int?,
		until terminator: Data,
		strippingTerminator: Bool,
		chunkSize: Int
	) throws -> Data {
		var data = Data(capacity: max(maxLength ?? chunkSize, chunkSize))
		var chunk = Data(capacity: chunkSize)
		
		socket.readBufferSize = chunkSize
		
		repeat {
			do {
				let bytesRead = try socket.read(into: &chunk)
				
				data.append(chunk)
				
				if bytesRead == 0 {
					// No more data to read (even if we aren't at the terminator)
					return data
				}
			}
			// TODO: Don't need to search all of the held data, only need to seach the last chunk and some extra in case the terminator data falls over multiple chunks.
		} while data.range(of: terminator, options: .backwards) == nil
			&& data.count < (maxLength ?? .max)
		
		if let range = data.range(of: terminator, options: .backwards) {
			let distance = data.distance(
				from: data.startIndex,
				to: strippingTerminator ? range.startIndex : range.endIndex)
			let endIndex = min(maxLength ?? .max, distance)
			return data[..<endIndex]
		}
		
		if data.count > (maxLength ?? .max) {
			return data[..<maxLength!]
		}
		
		return data
	}
	
	public func write(_ string: String,
										appending terminator: String?,
										encoding: String.Encoding
	) throws {
		try (string + (terminator ?? ""))
			.cString(using: encoding)?
			.withUnsafeBufferPointer() { buffer -> () in
				// The C String includes a null terminated byte -- we will discard this
				try socket.write(from: buffer.baseAddress!, bufSize: buffer.count - 1)
			}
	}
	
	public func writeBytes(_ data: Data, appending terminator: Data?) throws {
		let data = data + (terminator ?? Data())
		try socket.write(from: data)
	}
}

// MARK:- Error
extension TCPIPInstrument {
	/// An error associated with a `TCPIPCommunicator`.
	///
	/// - `couldNotCreateSocket`: The socket to communicate with the instrument could not be created.
	/// - `couldNotConnect`: The instrument could not be connected to. The instrument may not be connected, or could have a different address/port than the one specified.
	/// - `couldNotSetTimeout`: The timeout value could not be set.
	/// - `couldNotEnableBlocking`: The socket was unable to enable blocking.
	/// - `failedWriteOperation`: The communicator could not write to the instrument.
	/// - `failedReadOperation`: The communicator could not read from the instrument.
	/// - `couldNotDecode`: The communicator could not decode the data sent from the instrument.
	public enum Error: Swift.Error {
		case couldNotCreateSocket
		case couldNotConnect
		case couldNotSetTimeout
		case couldNotEnableBlocking
		case failedWriteOperation
		case failedReadOperation
		case couldNotDecode
	}
}

// MARK: Error Descriptions
extension TCPIPInstrument.Error {
	public var localizedDescription: String {
		switch self {
		case .couldNotConnect:
			return "Could not connect"
		case .couldNotCreateSocket:
			return "Could not create socket"
		case .couldNotSetTimeout:
			return "Could not set timeout"
		case .couldNotEnableBlocking:
			return "Could not enable blocking"
		case .failedWriteOperation:
			return "Failed write operation"
		case .failedReadOperation:
			return "Failed read operation"
		case .couldNotDecode:
			return "Could not decode"
		}
	}
}

// MARK: Instrument Manager
extension InstrumentManager {
	/// Returns the instrument at the specified network address.
		/// - Parameters:
		///   - address: The network address (IPv4 or IPv6).
		///   - port: The port the instrument is connected on.
		///   - timeout: The maximum wait time when first connecting to this instrument.
		/// - Throws: If the instrument could not be found or connected to.
		/// - Returns: The instrument at the specified address.
		public func instrumentAt(
			address: String,
			port: Int, timeout:
				TimeInterval? = nil
		) throws -> MessageBasedInstrument {
			return try TCPIPInstrument(address: address,
																 port: port,
																 timeout: timeout ?? connectionTimeout)
		}
}
