//
//  ReadConfigurationJSON.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 19/04/2021.
//

import Combine
import Foundation
import OSLog

class ReadConfigurationJSON: NamesandPaths {
    var configurations: [SynchronizeConfiguration]?
    var filenamedatastore = ["configurations.json"]
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
            .decode(type: [DecodeConfiguration].self, decoder: JSONDecoder())
            .sink { completion in
                switch completion {
                case .finished:
                    return
                case .failure:
                    return
                }
            } receiveValue: { [unowned self] data in
                let configurations = [SynchronizeConfiguration]()
                for i in 0 ..< data.count {
                    let configuration = SynchronizeConfiguration(data[i])
                }
                self.configurations = configurations
                subscriptons.removeAll()
                Logger.process.info("ReadConfigurationJSON: read configurations from permanent storage")
            }.store(in: &subscriptons)
    }
}
