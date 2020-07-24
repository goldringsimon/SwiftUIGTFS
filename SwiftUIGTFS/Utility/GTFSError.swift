//
//  GTFSError.swift
//  SwiftUIGTFS
//
//  Created by Simon Goldring on 7/24/20.
//  Copyright © 2020 Simon Goldring. All rights reserved.
//

import Foundation

enum GTFSError: Error {
    case invalidFile(issue: String)
    case invalidRowFormat(issue: String)
    case missingCSVHeader(issue: String)
    case invalidRegEx(issue: String)
    case missingColumn(issue: String)
    case openMobilityApiError(issue: String)
}
