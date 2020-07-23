//
//  GTFSDownloadDelegate.swift
//  SwiftUIGTFS
//
//  Created by Simon Goldring on 7/23/20.
//  Copyright © 2020 Simon Goldring. All rights reserved.
//

import Foundation

class GTFSDownloadDelegate: NSObject, URLSessionDownloadDelegate {
    weak var gtfsManager: GTFSManager?
    
    init(gtfsManager: GTFSManager) {
        super.init()
        self.gtfsManager = gtfsManager
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        gtfsManager?.downloadDelegate(didFinishDownloadingTo: location)
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        let amountDownloaded: Double = Double(totalBytesWritten) / Double(totalBytesExpectedToWrite)
        gtfsManager?.downloadDelegate(amountDownloaded: amountDownloaded)
    }
}
