//
//  USBInstrument.swift
//  
//
//  Created by Connor Barnes on 9/13/20.
//

import Foundation
import SwiftSerial


public final class USBInstrument {
	static func listPorts() {
		#if canImport(IOKit)
		let ports = comports()
		print(ports)
		#endif
	}
}

#if canImport(IOKit)
import IOKit

extension USBInstrument {
	internal struct Interface {
		var name: String
		var id: Int
	}
	
	internal struct ListPortInfo {
		var device: String
		var name: String {
			return device.components(separatedBy: "/").last ?? ""
		}
		var description: String?
		var hwid: String?
		// USB Specific data
		var vid: Int16?
		var pid: Int16?
		var serialNumber: String?
		var location: String?
		var manufacturer: String?
		var product: String?
		var interface: String?
	}
	
	internal static let vendorString = "USB Vendor Name"
	internal static let serialNumberString = "USB Serial Number"
	internal static let ioNameSize = 128
	
	static func getIOServices(type: String) -> [io_object_t] {
		let matching = IOServiceMatching(type)
		
		var serialPortIterator: io_iterator_t = 0
		
		IOServiceGetMatchingServices(kIOMasterPortDefault,
																 matching,
																 &serialPortIterator)
		
		var services: [io_object_t] = []
		
		while IOIteratorIsValid(serialPortIterator) > 0 {
			let service = IOIteratorNext(serialPortIterator)
			if service == 0 {
				break
			}
			services.append(service)
		}
		
		IOObjectRelease(serialPortIterator)
		return services
	}
	
	static func createStringBuffer(size: Int) -> UnsafeMutablePointer<CChar> {
		let buffer = UnsafeMutableBufferPointer<CChar>.allocate(capacity: size)
		return buffer.baseAddress!
	}
	
	static func getStringProperty(type: io_registry_entry_t, property: String) -> String? {
		let key = CFStringCreateWithCString(kCFAllocatorDefault,
																				property,
																				CFStringBuiltInEncodings.UTF8.rawValue)
		
		guard let cfContainer = IORegistryEntryCreateCFProperty(type,
																														key,
																														kCFAllocatorDefault,
																														0)
			else { return nil }
		
		// TODO: Working with unmanaged -- make sure this is memory safe
		let string = cfContainer.takeRetainedValue() as! CFString
		
		if let output = CFStringGetCStringPtr(string, 0) {
			return String(cString: output, encoding: .utf8)
		} else {
			let buffer = createStringBuffer(size: ioNameSize)
			let success = CFStringGetCString(string,
																			 buffer,
																			 ioNameSize,
																			 CFStringBuiltInEncodings.UTF8.rawValue)
			
			if success {
				return String(cString: buffer, encoding: .utf8)
			} else {
				return nil
			}
		}
	}
	
	static func getIntProperty<N: BinaryInteger>(type: io_registry_entry_t, property: String, numberType: N.Type) -> N? {
		let key = CFStringCreateWithCString(kCFAllocatorDefault,
																				property,
																				CFStringBuiltInEncodings.UTF8.rawValue)
		
		guard let cfContainer = IORegistryEntryCreateCFProperty(type,
																											key,
																											kCFAllocatorDefault,
																											0)
			else { return nil }
		
		let cfNumber = cfContainer.takeRetainedValue() as! CFNumber
		
		var value: N = .zero
		let valueType: CFNumberType
		
		switch numberType {
		case is Int32.Type:
			valueType = .sInt32Type
		case is Int16.Type:
			valueType = .sInt16Type
		default:
			return nil
		}
		
		CFNumberGetValue(cfNumber, valueType, &value)
		
		return value
	}
	
	static func getIOClass(device: io_object_t) -> String {
		let className = createStringBuffer(size: ioNameSize)
		IOObjectGetClass(device, className)
		return String(cString: className, encoding: .utf8)!
	}
	
	static func getParent(device: io_object_t, parentType: String) -> io_object_t? {
		var device = device
		while getIOClass(device: device) != parentType {
			var parent: io_registry_entry_t = 0
			let response = IORegistryEntryGetParentEntry(device, "IOService", &parent)
			if response != KERN_SUCCESS {
				return nil
			}
			device = parent
		}
		
		return device
	}
	
	static func scanInterfaces() -> [Interface] {
		var interfaces: [Interface] = []
		for service in getIOServices(type: "IOSerialBSDClient") {
			guard getStringProperty(type: service, property: "IOCalloutDevice") != nil else { break }
			
			guard let usbDevice = getParent(device: service, parentType: "IOUSBInterface") else { break }
			
			let name = getStringProperty(type: usbDevice, property: "USB Interface Name")
			let locationID = getIntProperty(type: usbDevice,
																			property: "locationID",
																			numberType: Int32.self)
			
			interfaces.append(Interface(name: name ?? "<noname>",
																	id: Int(locationID ?? -404)))
		}
		
		return interfaces
	}
	
	static func listPortInfo(device: io_object_t) {
		
	}
	
	static func getRegistryEntryName(device: io_registry_entry_t) -> String? {
		let deviceName = UnsafeMutableBufferPointer<CChar>.allocate(capacity: ioNameSize).baseAddress!
		let result = IORegistryEntryGetName(device, deviceName)
		
		if result != KERN_SUCCESS {
			return nil
		}
		
		return String(cString: deviceName, encoding: .utf8)
	}
	
	static func locationToString(_ locationID: Int32) -> String {
		var locationID = locationID
		
		var location = ["\(locationID >> 24)-"]
		while locationID & 0xf00000 > 0 {
			if location.count > 1 {
				location.append(".")
			}
			location.append("\((locationID >> 20) & 0xf)")
			locationID <<= 4
		}
		
		return location.joined()
	}
	
	static func seachForLocationID(_ locationID: Int32, in interfaces: [Interface]) -> String? {
		return interfaces.first { $0.id == locationID }?.name
	}
	
	static func comports(includeLinks: Bool = false) -> [ListPortInfo] {
		let services = getIOServices(type: "IOSerialBSDClient")
		var ports: [ListPortInfo] = []
		let serialInterfaces = scanInterfaces()
		for service in services {
			guard let device = getStringProperty(type: service, property: "IOCalloutDevice") else { break }
			
			var info = ListPortInfo(device: device)
			
			if let usbDevice = getParent(device: service, parentType: "IOUSBDevice") {
				
				info.vid = getIntProperty(type: usbDevice,
																	property: "idVendor",
																	numberType: Int16.self)
				
				info.pid = getIntProperty(type: usbDevice,
																	property: "idProduct",
																	numberType: Int16.self)
				
				info.serialNumber = getStringProperty(type: usbDevice,
																							property: serialNumberString)
				
				info.product = getRegistryEntryName(device: usbDevice)
				
				info.manufacturer = getStringProperty(type: usbDevice,
																							property: vendorString)
				
				if let locationID = getIntProperty(type: usbDevice,
																					 property: "locationID",
																					 numberType: Int32.self) {
					info.location = locationToString(locationID)
					info.interface = seachForLocationID(locationID, in: serialInterfaces)
				}
				
				if let interface = info.interface {
					info.description = "\(info.product ?? "nil") - \(interface)"
				} else if let product = info.product {
					info.description = product
				} else {
					info.description = info.name
				}
				
				let vidHex = String.init(info.vid ?? 0, radix: 16, uppercase: false)
				let pidHex = String.init(info.vid ?? 0, radix: 16, uppercase: false)
				info.hwid = "USB VID:PID=0x\(vidHex):0x\(pidHex) SER=\(info.serialNumber ?? "") LOCATION=\(info.location ?? "")"
			}
			
			ports.append(info)
		}
		
		return ports
	}
}

#endif
