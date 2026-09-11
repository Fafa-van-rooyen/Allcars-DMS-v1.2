import Foundation

enum SouthAfricanIDDecoder {

    static func decode(
        _ payload: String
    ) -> IDScanResult {

        print("")
        print("==================================")
        print("LOCAL SOUTH AFRICAN ID DECODER")
        print("==================================")
        print("RAW ID PAYLOAD START")
        print(payload)
        print("RAW ID PAYLOAD END")
        print("==================================")
        print("")

        /*
         First version:
         only safely detect a 13-digit SA ID number
         if it appears as readable text.

         We will expand this once we see the
         actual payload format from your ID card.
        */

        var result = IDScanResult()

        let pattern = #"\b\d{13}\b"#

        if let range =
            payload.range(
                of: pattern,
                options: .regularExpression
            ) {

            result.idNumber =
                String(payload[range])
        }

        return result
    }
}
//
//  SouthAfricanIDDecoder.swift
//  Allcars DMS
//
//  Created by Fafa Van Rooyen on 2026/08/25.
//

