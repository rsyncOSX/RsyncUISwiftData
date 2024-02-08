//
//  LogRecords.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 06/02/2024.
//
// swiftlint:disable line_length

import Foundation
import SwiftData

@Model
final class LogRecords: Identifiable {
    var id = UUID()
    @Attribute(.unique) var hiddenID: Int
    var offsiteserver: String?
    var dateStart: String
    @Relationship(deleteRule: .cascade, inverse: \Log.logrecord) var records: [Log]?

    init(id: UUID = UUID(), hiddenID: Int, offsiteserver: String? = nil, dateStart: String, records: [Log]? = nil) {
        self.id = id
        self.hiddenID = hiddenID
        self.offsiteserver = offsiteserver
        self.dateStart = dateStart
        self.records = records
    }

    init(_ hiddenID: Int) {
        self.hiddenID = hiddenID
        dateStart = Date().en_us_string_from_date()
    }
}

@Model
final class Log: Identifiable {
    var id = UUID()
    var dateExecuted: String
    var resultExecuted: String
    var logrecord: LogRecords?
    @Relationship(inverse: \LogRecords.records)

    init(id: UUID = UUID(), dateExecuted: String, resultExecuted: String, logrecord: LogRecords? = nil) {
        self.id = id
        self.dateExecuted = dateExecuted
        self.resultExecuted = resultExecuted
        self.logrecord = logrecord
    }
}

extension LogRecords: Hashable, Equatable {
    static func == (lhs: LogRecords, rhs: LogRecords) -> Bool {
        return lhs.hiddenID == rhs.hiddenID &&
            lhs.dateStart == rhs.dateStart &&
            lhs.offsiteserver == rhs.offsiteserver
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(String(hiddenID))
        hasher.combine(dateStart)
        hasher.combine(offsiteserver)
    }
}

extension Log: Hashable, Equatable {
    static func == (lhs: Log, rhs: Log) -> Bool {
        return lhs.dateExecuted == rhs.dateExecuted &&
            lhs.resultExecuted == rhs.resultExecuted &&
            lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(dateExecuted)
        hasher.combine(resultExecuted)
        hasher.combine(id)
    }
}

// swiftlint:enable line_length
