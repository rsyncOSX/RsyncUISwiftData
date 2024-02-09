//
//  WriteConfigurationJSON.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 27/04/2021.
//

import Combine
import Foundation
import OSLog

class WriteConfigurationJSON: NamesandPaths {
    var subscriptons = Set<AnyCancellable>()
    // Filename for JSON file
    var filename = "configurations.json"

    private func writeJSONToPersistentStore(_ data: String?) {
        if let atpath = documentscatalog {
            do {
                let folder = try Folder(path: atpath)
                let file = try folder.createFile(named: filename)
                if let data = data {
                    try file.write(data)
                    Logger.process.info("WriteConfigurationJSON: write configurations to permanent storage")
                }
            } catch let e {
                let error = e
                propogateerror(error: error)
            }
        }
    }

    // We have to remove UUID and computed properties ahead of writing JSON file
    // done in the .map operator
    @discardableResult
    init(_: String?, _ configurations: [SynchronizeConfiguration]?) {
        super.init()
        configurations.publisher
            .map { configurations -> [DecodeConfiguration] in
                var data = [DecodeConfiguration]()
                for i in 0 ..< configurations.count {
                    data.append(DecodeConfiguration(configurations[i]))
                }
                return data
            }
            .encode(encoder: JSONEncoder())
            .sink(receiveCompletion: { completion in
                switch completion {
                case .finished:
                    return
                case let .failure(error):
                    self.propogateerror(error: error)
                }
            }, receiveValue: { [unowned self] result in
                let jsonfile = String(data: result, encoding: .utf8)
                writeJSONToPersistentStore(jsonfile)
                subscriptons.removeAll()
            })
            .store(in: &subscriptons)
    }
}
