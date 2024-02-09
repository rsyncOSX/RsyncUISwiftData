//
//  ReadLogRecordsJSON.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 19/04/2021.
//

import Combine
import Foundation
import OSLog

class ReadLogRecordsJSON: NamesandPaths {
    var logrecords: [LogRecords]?
    var filenamedatastore = ["logrecords.json"]
    var subscriptons = Set<AnyCancellable>()

    override init() {
        super.init()
        filenamedatastore.publisher
            .compactMap { filenamejson -> URL in
                var filename = ""
                if let path = documentscatalog {
                    filename = path + "/" + filenamejson
                }
                return URL(fileURLWithPath: filename)
            }
            .tryMap { url -> Data in
                try Data(contentsOf: url)
            }
            .decode(type: [DecodeLogRecords].self, decoder: JSONDecoder())
            .sink { completion in
                switch completion {
                case .finished:
                    return
                case .failure:
                    Logger.process.warning("ReadLogRecordsJSON: something is wrong, could not read logdata from permanent storage")
                    return
                }
            } receiveValue: { [unowned self] data in
                logrecords = [LogRecords]()
                for i in 0 ..< data.count {
                    let onerecords = LogRecords(data[i])
                    // TODO: insert
                }
                Logger.process.info("ReadLogRecordsJSON: read logrecords from permanent storage")
                subscriptons.removeAll()
            }.store(in: &subscriptons)
    }
}
