//
//  TCPIPInstrument.swift
//  
//
//  Created by Connor Barnes on 9/13/20.
//

import Foundation
import CoreSwiftVISA
import Socket

/// An instrument connected over TCP-IP.
public final class TCPIPInstrument {
	internal let _session: TCPIPSession
	
	public var session: Session {
		return _session
	}
	/// Attributes to control the communication with the instrument.
	public var attributes = MessageBasedInstrumentAttributes()
	/// Tries to create an instance from the specified address, and port of the instrument. A timeout value must also be specified.
	///
	/// - Parameters:
	///   - address: The IPV4 address of the instrument in dot notation.
	///   - port: The port of the instrument.
	///   - timeout: The maximum time to wait before timing out when communicating with the instrument.
	///
	/// - Throws: An error if a socket could not be created, connected, or configured properly.
	public init(address: String, port: Int, timeout: TimeInterval) throws {
		try _session = TCPIPSession(address: address, port: port, timeout: timeout)
	}
	
	deinit {
		// Close the connection because we will no longer need it.
		try? session.close()
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
		usleep(useconds_t(attributes.operationDelay * 1_000_000.0))
		// The message may not fit in a single chunk. To overcome this, we continue to request data until we are at the end of the message.
		// Continue until `string` ends in the terminator.
		var string = String()
		var chunk = Data(capacity: chunkSize)
		
		_session.socket.readBufferSize = chunkSize
		
		repeat {
			do {
				let bytesRead: Int
				do {
					bytesRead = try _session.socket.read(into: &chunk)
				} catch where (error as? Socket.Error)?.errorCode == Int32(Socket.SOCKET_ERR_BAD_DESCRIPTOR) {
					throw Error.couldNotConnect
				} catch {
					throw Error.failedReadOperation
				}
				
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
		usleep(useconds_t(attributes.operationDelay * 1_000_000.0))
		
		var data = Data(capacity: max(length, chunkSize))
		var chunk = Data(capacity: chunkSize)
		
		_session.socket.readBufferSize = chunkSize
		
		repeat {
			do {
				let bytesRead: Int
				do {
					bytesRead = try _session.socket.read(into: &chunk)
				} catch where (error as? Socket.Error)?.errorCode == Int32(Socket.SOCKET_ERR_BAD_DESCRIPTOR) {
					throw Error.couldNotConnect
				} catch {
					throw Error.failedReadOperation
				}
				
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
		usleep(useconds_t(attributes.operationDelay * 1_000_000.0))
		
		var data = Data(capacity: max(maxLength ?? chunkSize, chunkSize))
		var chunk = Data(capacity: chunkSize)
		
		_session.socket.readBufferSize = chunkSize
		
		repeat {
			do {
				let bytesRead: Int
				do {
					bytesRead = try _session.socket.read(into: &chunk)
				} catch where (error as? Socket.Error)?.errorCode == Int32(Socket.SOCKET_ERR_BAD_DESCRIPTOR) {
					throw Error.couldNotConnect
				} catch {
					throw Error.failedReadOperation
				}
				
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
		usleep(useconds_t(attributes.operationDelay * 1_000_000.0))
		
		try (string + (terminator ?? ""))
			.cString(using: encoding)?
			.withUnsafeBufferPointer() { buffer -> () in
				// The C String includes a null terminated byte -- we will discard this
				do {
					try _session.socket.write(from: buffer.baseAddress!, bufSize: buffer.count - 1)
				} catch where (error as? Socket.Error)?.errorCode == Int32(Socket.SOCKET_ERR_BAD_DESCRIPTOR) {
					throw Error.couldNotConnect
				} catch {
					throw Error.failedWriteOperation
				}
			}
	}
	
	public func writeBytes(_ data: Data, appending terminator: Data?) throws {
		usleep(useconds_t(attributes.operationDelay * 1_000_000.0))
		
		let data = data + (terminator ?? Data())
		do {
			try _session.socket.write(from: data)
		} catch where (error as? Socket.Error)?.errorCode == Int32(Socket.SOCKET_ERR_BAD_DESCRIPTOR) {
			throw Error.couldNotConnect
		} catch {
			throw Error.failedReadOperation
		}
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
