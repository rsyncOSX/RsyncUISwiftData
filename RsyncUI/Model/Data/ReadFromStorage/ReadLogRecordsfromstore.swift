//
//  ReadLogRecordsfromstore.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 18/01/2024.
//

import Foundation

struct ReadLogRecordsfromstore {
    var logs: [LogJSON]?
    var logrecords: [LogRecordsJSON]?

    init(_ profile: String?, _ validhiddenIDs: Set<Int>?) {
        guard validhiddenIDs != nil else { return }
        var logdatafromstore: ReadLogRecordsJSON?
        if profile == SharedReference.shared.defaultprofile || profile == nil {
            logdatafromstore = ReadLogRecordsJSON(nil, validhiddenIDs ?? Set())
        } else {
            logdatafromstore = ReadLogRecordsJSON(profile, validhiddenIDs ?? Set())
        }
        logrecords = logdatafromstore?.logrecords?.sorted { log1, log2 in
            log1.dateStart > log2.dateStart
        }
        logs = logdatafromstore?.logs
    }
}
