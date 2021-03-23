//
//  DateTimeUtils.swift
//  BrainCache
//
//  Created by Alexander Dittner on 01.04.2020.
//  Copyright © 2020 Alexander Dittner. All rights reserved.
//

import Foundation

// DateFormatter examples
// Wednesday, Sep 12, 2018           --> EEEE, MMM d, yyyy
// 09/12/2018                        --> MM/dd/yyyy
// 09-12-2018 14:11                  --> MM-dd-yyyy HH:mm
// Sep 12, 2:11 PM                   --> MMM d, h:mm a
// September 2018                    --> MMMM yyyy
// Sep 12, 2018                      --> MMM d, yyyy
// Wed, 12 Sep 2018 14:11:54 +0000   --> E, d MMM yyyy HH:mm:ss Z
// 2018-09-12T14:11:54+0000          --> yyyy-MM-dd'T'HH:mm:ssZ
// 12.09.18                          --> dd.MM.yy
// 10:41:02.112                      --> HH:mm:ss.SSS

class DateTimeUtils {

    private static let defaultDateFormatter: DateFormatter = {
        var formatter = DateFormatter()
        formatter.dateFormat = "dd.MM.yyyy"
        formatter.locale = Locale(identifier: "de_DE")
        return formatter
    }()

    public class func localize(_ date: Date) -> String {
        return defaultDateFormatter.string(from: date)
    }
}
