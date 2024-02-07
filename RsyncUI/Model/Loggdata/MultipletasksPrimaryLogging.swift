//
//  MultipletasksPrimaryLogging.swift
//  RsyncSwiftUI
//
//  Created by Thomas Evensen on 24/01/2021.
//

import Foundation

final class MultipletasksPrimaryLogging: SingletaskPrimaryLogging {
    func setCurrentDateonConfiguration(configrecords: [Typelogdata]) -> [SynchronizeConfigurationJSON] {
        for i in 0 ..< configrecords.count {
            let hiddenID = configrecords[i].0
            let date = configrecords[i].1
            if let index = structconfigurations?.firstIndex(where: { $0.hiddenID == hiddenID }) {
                // Caution, snapshotnum already increased before logrecord
                if structconfigurations?[index].task == SharedReference.shared.snapshot {
                    increasesnapshotnum(index: index)
                }
                structconfigurations?[index].dateRun = date
            }
        }
        WriteConfigurationJSON(localeprofile, structconfigurations)
        return structconfigurations ?? []
    }

    // Caution, the snapshotnum is alrady increased in
    // setCurrentDateonConfiguration(configrecords: [Typelogdata]).
    // Must set -1 to get correct num in log
    func addlogpermanentstore(schedulerecords: [Typelogdata]) {
        if SharedReference.shared.detailedlogging {
            for i in 0 ..< schedulerecords.count {
                let hiddenID = schedulerecords[i].0
                let stats = schedulerecords[i].1
                let currendate = Date()
                let date = currendate.en_us_string_from_date()
                if let config = getconfig(hiddenID: hiddenID) {
                    var resultannotaded: String?
                    if config.task == SharedReference.shared.snapshot {
                        if let snapshotnum = config.snapshotnum {
                            resultannotaded = "(" + String(snapshotnum - 1) + ") " + stats
                        } else {
                            resultannotaded = "(" + "1" + ") " + stats
                        }
                    } else {
                        resultannotaded = stats
                    }
                    var inserted: Bool = addlogexisting(hiddenID: hiddenID,
                                                        result: resultannotaded ?? "",
                                                        date: date)
                    // Record does not exist, create new Schedule (not inserted)
                    if inserted == false {
                        inserted = addlognew(hiddenID: hiddenID, result: resultannotaded ?? "", date: date)
                    }
                }
            }
            WriteLogRecordsJSON(localeprofile, logrecords)
        }
    }
}
