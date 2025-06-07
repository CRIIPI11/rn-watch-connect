//
//  Validation.swift
//  RnWatchConnect
//
//  Created by Cristhian Molina on 6/6/25.
//

import Foundation

func validateBase64(_ string: String) throws -> Data {
    // Check for valid base64 characters
    let base64Regex = "^[A-Za-z0-9+/]*={0,2}$"
    guard string.range(of: base64Regex, options: .regularExpression) != nil else {
        throw MessageError.invalidBase64Format
    }
    
    // Check length
    guard string.count % 4 == 0 else {
        throw MessageError.invalidBase64Length
    }
    
    // Check padding
    if string.hasSuffix("=") {
        let paddingCount = string.components(separatedBy: "=").count - 1
        guard paddingCount <= 2 else {
            throw MessageError.invalidBase64Padding
        }
    }
    
    // Try to decode
    guard let data = Data(base64Encoded: string) else {
        throw MessageError.invalidBase64Decoding
    }
    
    return data
}
