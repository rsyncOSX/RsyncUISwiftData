//
//  DecodeLogRecords.swift
//  RsyncOSX
//
//  Created by Thomas Evensen on 18/10/2020.
//  Copyright © 2020 Thomas Evensen. All rights reserved.
//
//	Model file generated using JSONExport: https://github.com/Ahmed-Ali/JSONExport

import Foundation

struct DecodeLog: Codable, Hashable {
    var dateExecuted: String?
    var resultExecuted: String?

    enum CodingKeys: String, CodingKey {
        case dateExecuted
        case resultExecuted
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        dateExecuted = try values.decodeIfPresent(String.self, forKey: .dateExecuted)
        resultExecuted = try values.decodeIfPresent(String.self, forKey: .resultExecuted)
    }

    // This init is used in WriteConfigurationJSON
    init(_ dateExcuted: String, _ resultExecuted: String) {
        dateExecuted = dateExcuted
        self.resultExecuted = resultExecuted
    }
}

struct DecodeLogRecords: Codable {
    let dateStart: String?
    let hiddenID: Int?
    var records: [DecodeLog]?
    let offsiteserver: String?

    enum CodingKeys: String, CodingKey {
        case dateStart
        case hiddenID
        case records
        case offsiteserver
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        dateStart = try values.decodeIfPresent(String.self, forKey: .dateStart)
        hiddenID = try values.decodeIfPresent(Int.self, forKey: .hiddenID)
        records = try values.decodeIfPresent([DecodeLog].self, forKey: .records)
        offsiteserver = try values.decodeIfPresent(String.self, forKey: .offsiteserver)
    }

    init(_ data: LogRecords) {
        dateStart = data.dateStart
        hiddenID = data.hiddenID
        offsiteserver = data.offsiteserver
        for i in 0 ..< (data.records?.count ?? 0) {
            if i == 0 { records = [DecodeLog]() }
            let log = DecodeLog(data.records?[i].dateExecuted ?? "", data.records?[i].resultExecuted ?? "")
            records?.append(log)
        }
    }
}
