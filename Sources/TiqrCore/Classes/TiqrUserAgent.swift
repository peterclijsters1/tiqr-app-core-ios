//
//  TiqrUserAgent.swift
//
//  Generates a User-Agent header value which has the following format:
//  tiqr/3.0.1 (tiqr 3.0.1/27; iOS 15.4.1/19E258; iPhone10,1)
//
//  Code is based on the following Gist file:
//  https://gist.github.com/bryanburgers/daa09d5d8c3b61c6d98a
//
//  Also contains snippets from: https://stackoverflow.com/a/60504236/1395437
//
//  Created by Dániel Zolnai on 2022. 05. 06..
//

import Foundation
import UIKit

@objc public final class TiqrUserAgent : NSObject  {
    @objc public static func getUserAgent() -> String {
        let bundleDict = Bundle.main.infoDictionary!
        let appName = bundleDict["CFBundleName"] as! String
        let appVersion = bundleDict["CFBundleShortVersionString"] as! String
        let appDescriptor = appName + "/" + appVersion
        
        let buildNr = bundleDict["CFBundleVersion"] as! String
        let buildDescriptor = appName + " " + appVersion + "/" + buildNr

        let currentDevice = UIDevice.current
        let osDescriptor = "iOS " + currentDevice.systemVersion + "/" + (getSystemBuild() ?? "UNKNOWN")

        let hardwareString = self.getHardwareString()

        return appDescriptor + " (" + buildDescriptor + "; " + osDescriptor + "; " + hardwareString + ")"
    }
    
    /**
     * Returns the iOS build number. Code taken from: https://stackoverflow.com/a/65858410/1395437
     */
    private static func getSystemBuild() -> String? {
        var mib: [Int32] = [CTL_KERN, KERN_OSVERSION]
        let namelen = u_int(MemoryLayout.size(ofValue: mib) / MemoryLayout.size(ofValue: mib[0]))
        var bufferSize: size_t = 0
        
        // Get the size for the buffer
        sysctl(&mib, namelen, nil, &bufferSize, nil, 0)
        
        var buildBuffer: [u_char] = .init(repeating: 0, count: bufferSize)
        
        let result = sysctl(&mib, namelen, &buildBuffer, &bufferSize, nil, 0)
        
        if result >= 0 && bufferSize > 0 {
            return String(bytesNoCopy: &buildBuffer, length: bufferSize - 1, encoding: .utf8, freeWhenDone: false)
        }
        
        return nil
    }
    
    private static func getHardwareString() -> String {
        var name: [Int32] = [CTL_HW, HW_MACHINE]
        var localname: [Int32] = [CTL_HW, HW_MACHINE]
        var size: Int = 2
        localname = name
        sysctl(&name, 2, nil, &size, &localname, 0)
        var hw_machine = [CChar](repeating: 0, count: Int(size))
        sysctl(&name, 2, &hw_machine, &size, &localname, 0)

        let hardware: String = String(cString: hw_machine)
        return hardware
    }

}
