//
//  EstimateTasks.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 20/10/2022.
//

import Foundation

class EstimateTasks {
    var localconfigurations: [SynchronizeConfiguration]
    var stackoftasktobeestimated: [Int]?
    weak var localestimateprogressdetails: EstimateProgressDetails?

    func getconfig(_ hiddenID: Int, _ configurations: [SynchronizeConfiguration]) -> SynchronizeConfiguration? {
        if let index = configurations.firstIndex(where: { $0.hiddenID == hiddenID }) {
            return configurations[index]
        }
        return nil
    }

    @MainActor
    func startestimation() async {
        guard stackoftasktobeestimated?.count ?? 0 > 0 else {
            localestimateprogressdetails?.asyncestimationcomplete()
            return
        }
        if let localhiddenID = stackoftasktobeestimated?.removeLast() {
            if let config = getconfig(localhiddenID, localconfigurations) {
                let arguments = Argumentsforrsync().argumentsforrsync(config: config, argtype: .argdryRun)
                guard arguments.count > 0 else { return }
                // Used to display details of configuration in estimation
                localestimateprogressdetails?.configurationtobestimated = config.id
                let process = RsyncProcessAsync(arguments: arguments,
                                                config: config,
                                                processtermination: processtermination)
                await process.executeProcess()
            }
        }
    }

    init(configurations: [SynchronizeConfiguration],
         estimateprogressdetails: EstimateProgressDetails?,
         uuids: Set<UUID>,
         filter: String)
    {
        localconfigurations = configurations
        localestimateprogressdetails = estimateprogressdetails
        let filteredconfigurations = localconfigurations.filter { filter.isEmpty ? true : $0.backupID.contains(filter) }
        stackoftasktobeestimated = [Int]()
        // Estimate selected configurations
        if uuids.count > 0 {
            let configurations = filteredconfigurations.filter { uuids.contains($0.id) }
            for i in 0 ..< configurations.count {
                stackoftasktobeestimated?.append(configurations[i].hiddenID)
            }
        } else {
            // Or estimate all tasks
            for i in 0 ..< filteredconfigurations.count {
                stackoftasktobeestimated?.append(configurations[i].hiddenID)
            }
        }
    }
}

extension EstimateTasks {
    func processtermination(outputfromrsync: [String]?, hiddenID: Int?) {
        if let config = getconfig(hiddenID ?? -1, localconfigurations) {
            let record = RemoteDataNumbers(hiddenID: hiddenID,
                                           outputfromrsync: outputfromrsync,
                                           config: config)
            localestimateprogressdetails?.appendrecordestimatedlist(record)
            if Int(record.transferredNumber) ?? 0 > 0 || Int(record.deletefiles) ?? 0 > 0 {
                localestimateprogressdetails?.appenduuid(config.id)
            }
        }
        Task {
            await self.startestimation()
        }
    }
}
