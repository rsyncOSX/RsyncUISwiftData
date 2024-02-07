//
//  ReadConfigurationJSON.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 19/04/2021.
//
// swiftlint:disable line_length cyclomatic_complexity

import Combine
import Foundation
import OSLog

class ReadConfigurationJSON: NamesandPaths {
    var configurations: [SynchronizeConfigurationJSON]?
    var filenamedatastore = [SharedReference.shared.fileconfigurationsjson]
    var subscriptons = Set<AnyCancellable>()
    var validhiddenIDs = Set<Int>()

    private func createdefaultfileconfigurations(_ profile: String?) {
        // No file, write new file with default values
        Logger.process.info("ReadConfigurationJSON - \(profile ?? "default profile", privacy: .public): Creating default file for Configurations")
        let defaultconfiguration = [SynchronizeConfigurationJSON()]
        WriteConfigurationJSON(profile, defaultconfiguration)
    }

    private func createdefaultfilelogrecords(_ profile: String?) {
        var defaultlogrecords = [LogRecordsJSON()]
        guard defaultlogrecords.count == 1 else { return }
        // No file, write new file with default values
        Logger.process.info("ReadConfigurationJSON: \(profile ?? "default profile", privacy: .public), Creating default file for LogRecords")
        defaultlogrecords[0].dateStart = Date().en_us_string_from_date()
        defaultlogrecords[0].profilename = profile
        WriteLogRecordsJSON(profile, defaultlogrecords)
    }

    init(_ profile: String?) {
        super.init(.configurations)

        filenamedatastore.publisher
            .compactMap { filenamejson -> URL in
                var filename = ""
                if let profile = profile, let path = fullpathmacserial {
                    filename = path + "/" + profile + "/" + filenamejson
                } else {
                    if let path = fullpathmacserial {
                        filename = path + "/" + filenamejson
                    }
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
                    self.createdefaultfileconfigurations(profile)
                    self.createdefaultfilelogrecords(profile)
                    // Mark first time used, only for default profile
                    if profile == nil {
                        SharedReference.shared.firsttime = true
                    }
                }
            } receiveValue: { [unowned self] data in
                var configurations = [SynchronizeConfigurationJSON]()
                for i in 0 ..< data.count {
                    var configuration = SynchronizeConfigurationJSON(data[i])
                    configuration.profile = profile
                    // Validate sync task
                    if SharedReference.shared.synctasks.contains(configuration.task) {
                        if validhiddenIDs.contains(configuration.hiddenID) == false {
                            configurations.append(configuration)
                            // Create set of validated hidden IDs, used when loading logrecords
                            validhiddenIDs.insert(configuration.hiddenID)
                        }
                    }
                }
                let sorted = configurations.sorted { conf1, conf2 in
                    if let days1 = conf1.dateRun?.en_us_date_from_string(),
                       let days2 = conf2.dateRun?.en_us_date_from_string()
                    {
                        return days1 > days2
                    }
                    return false
                }
                self.configurations = sorted
                subscriptons.removeAll()
                Logger.process.info("ReadConfigurationJSON: read configurations from permanent storage")
            }.store(in: &subscriptons)
    }
}

// swiftlint:enable line_length cyclomatic_complexity
