//
//  ExecuteTasksNOEstimation.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 22/10/2022.
//

import Foundation
import OSLog

final class ExecuteTasksNOEstimation {
    var localconfigurations: [SynchronizeConfiguration]
    var stackoftasktobeestimated: [Int]?
    weak var localexecuteasyncnoestimation: ExecuteAsyncNoEstimation?
    // Collect loggdata for later save to permanent storage
    // (hiddenID, log)
    private var configrecords = [Typelogdata]()
    private var schedulerecords = [Typelogdata]()
    // Update configigurations and logrecords
    var localupdatedates: ([Typelogdata]) -> Void
    var localupdatelogrecords: ([Typelogdata]) -> Void

    func getconfig(_ hiddenID: Int, _ configurations: [SynchronizeConfiguration]) -> SynchronizeConfiguration? {
        if let index = configurations.firstIndex(where: { $0.hiddenID == hiddenID }) {
            return configurations[index]
        }
        return nil
    }

    func startexecution() {
        guard stackoftasktobeestimated?.count ?? 0 > 0 else {
            // Update time stamps configurations and logrecords
            localupdatedates(configrecords)
            localupdatelogrecords(schedulerecords)
            localexecuteasyncnoestimation?.asyncexecutealltasksnoestiamtioncomplete()
            Logger.process.info("class ExecuteTasksAsync: async execution is completed")
            return
        }
        if let localhiddenID = stackoftasktobeestimated?.removeLast() {
            if let config = getconfig(localhiddenID, localconfigurations) {
                let arguments = Argumentsforrsync().argumentsforrsync(config: config, argtype: .arg)
                guard arguments.count > 0 else { return }
                let process = RsyncProcessNOFilehandler(arguments: arguments,
                                                        config: config,
                                                        processtermination: processterminationexecute)
                process.executeProcess()
            }
        }
    }

    init(configurations: [SynchronizeConfiguration],
         executeasyncnoestimation: ExecuteAsyncNoEstimation?,
         uuids: Set<UUID>,
         filter: String,
         updatedates: @escaping ([Typelogdata]) -> Void,
         updatelogrecords: @escaping ([Typelogdata]) -> Void)
    {
        localconfigurations = configurations
        localexecuteasyncnoestimation = executeasyncnoestimation
        localupdatedates = updatedates
        localupdatelogrecords = updatelogrecords
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
                stackoftasktobeestimated?.append(filteredconfigurations[i].hiddenID)
            }
        }
    }
}

extension ExecuteTasksNOEstimation {
    func processterminationexecute(outputfromrsync: [String]?, hiddenID: Int?) {
        // Log records
        // If snahost task the snapshotnum is increased when updating the configuration.
        // When creating the logrecord, decrease the snapshotum by 1
        if let hiddenID = hiddenID, let data = outputfromrsync {
            configrecords.append((hiddenID, Date().en_us_string_from_date()))
            schedulerecords.append((hiddenID, Numbers(data).stats()))
        }
        if let config = getconfig(hiddenID ?? -1, localconfigurations) {
            let record = RemoteDataNumbers(hiddenID: hiddenID,
                                           outputfromrsync: outputfromrsync,
                                           config: config)
            localexecuteasyncnoestimation?.appendrecordexecutedlist(record)
            localexecuteasyncnoestimation?.appenduuid(config.id)
        }
        startexecution()
    }
}
