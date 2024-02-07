//
//  SnapshotLogRecords.swift
//  RsyncSwiftUI
//
//  Created by Thomas Evensen on 23/02/2021.
//
// swiftlint:disable line_length

import Foundation

struct SnapshotLogRecords: Identifiable {
    var id = UUID()
    var hiddenID: Int
    var localCatalog: String
    var remoteCatalog: String
    var offsiteServer: String
    var task: String
    var backupID: String
    var dateExecuted: String
    var date: Date
    var resultExecuted: String
    // Snapshots
    var period: String?
    var days: String?
    var snapshotCatalog: String?
    var seconds: Int = 0
}

final class SnapshotRecords {
    private var localconfigurations: RsyncUIconfigurations?
    private var alllogrecords: ReadLogRecordsfromstore?
    var loggrecordssnapshots: [SnapshotLogRecords]?
    private var localehiddenID: Int?

    private func readandsortallloggdata(hiddenID: Int?) {
        var data = [SnapshotLogRecords]()
        if let input: [LogRecordsJSON] = alllogrecords?.logrecords {
            for i in 0 ..< input.count {
                for j in 0 ..< (input[i].logrecords?.count ?? 0) {
                    if let hiddenID = alllogrecords?.logrecords?[i].hiddenID {
                        var datestring: String?
                        var date: Date?
                        if let stringdate = input[i].logrecords?[j].dateExecuted {
                            if stringdate.isEmpty == false {
                                datestring = stringdate.en_us_date_from_string().localized_string_from_date()
                                date = stringdate.en_us_date_from_string()
                            }
                        }
                        let configdata = GetConfigurationData(configurations: localconfigurations?.getallconfigurations())
                        let record =
                            SnapshotLogRecords(
                                hiddenID: hiddenID,
                                localCatalog: configdata.getconfigurationdata(hiddenID, resource: .localCatalog) ?? "",
                                remoteCatalog: configdata.getconfigurationdata(hiddenID, resource: .remoteCatalog) ?? "",
                                offsiteServer: configdata.getconfigurationdata(hiddenID, resource: .offsiteServer) ?? "",
                                task: configdata.getconfigurationdata(hiddenID, resource: .task) ?? "",
                                backupID: configdata.getconfigurationdata(hiddenID, resource: .backupid) ?? "",
                                dateExecuted: datestring ?? "",
                                date: date ?? Date(),
                                resultExecuted: input[i].logrecords?[j].resultExecuted ?? ""
                            )
                        data.append(record)
                    }
                }
            }
        }
        if hiddenID != nil { data = data.filter { $0.hiddenID == hiddenID } }
        loggrecordssnapshots = data.sorted(by: \.date, using: >)
    }

    init(hiddenID: Int?,
         profile: String?,
         configurations: RsyncUIconfigurations?)
    {
        localehiddenID = hiddenID
        localconfigurations = configurations
        alllogrecords = ReadLogRecordsfromstore(profile, localconfigurations?.validhiddenIDs ?? Set())
        if loggrecordssnapshots == nil {
            readandsortallloggdata(hiddenID: hiddenID)
        }
    }
}

extension SnapshotLogRecords: Hashable, Equatable {
    static func == (lhs: SnapshotLogRecords, rhs: SnapshotLogRecords) -> Bool {
        return lhs.dateExecuted == rhs.dateExecuted &&
            lhs.resultExecuted == rhs.resultExecuted &&
            lhs.snapshotCatalog == rhs.snapshotCatalog &&
            lhs.period == rhs.period &&
            lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(dateExecuted)
        hasher.combine(resultExecuted)
        hasher.combine(id)
        hasher.combine(snapshotCatalog)
        hasher.combine(period)
    }
}

// swiftlint:enable line_length
