//
//  ExecuteMultipleTasks.swift
//  RsyncSwiftUI
//
//  Created by Thomas Evensen on 22/01/2021.
//
// swiftlint:disable line_length

import Foundation
import OSLog

typealias Typelogdata = (Int, String)

final class ExecuteMultipleTasks {
    private var localconfigurations: [SynchronizeConfiguration]
    private var stackoftasktobeexecuted: [Int]?
    private var setabort = false

    weak var multipletaskstate: ExecuteMultipleTasksState?
    weak var executeprogressdetails: ExecuteProgressDetails?
    // Collect loggdata for later save to permanent storage (hiddenID, log)
    private var configrecords = [Typelogdata]()
    private var schedulerecords = [Typelogdata]()
    // Report progress to caller
    var localfilehandler: (Int) -> Void
    // Update configigurations and logrecords
    var localupdatedates: ([Typelogdata]) -> Void
    var localupdatelogrecords: ([Typelogdata]) -> Void

    private func prepareandstartexecutetasks(configurations: [SynchronizeConfiguration]?) {
        stackoftasktobeexecuted = [Int]()
        if let configurations = configurations {
            for i in 0 ..< configurations.count {
                stackoftasktobeexecuted?.append(configurations[i].hiddenID)
            }
        }
    }

    private func startexecution() {
        guard (stackoftasktobeexecuted?.count ?? 0) > 0 else { return }
        if let hiddenID = stackoftasktobeexecuted?.remove(at: 0) {
            executeprogressdetails?.hiddenIDatwork = hiddenID
            let execute = ExecuteOneTask(hiddenID: hiddenID,
                                         configurations: localconfigurations,
                                         termination: processtermination,
                                         filehandler: localfilehandler)
            execute.startexecution()
        }
    }

    @discardableResult
    init(uuids: Set<UUID>,
         configurations: [SynchronizeConfiguration],
         multipletaskstateDelegate: ExecuteMultipleTasksState?,
         executeprogressdetailsDelegate: ExecuteProgressDetails?,
         filehandler: @escaping (Int) -> Void,
         updatedates: @escaping ([Typelogdata]) -> Void,
         updatelogrecords: @escaping ([Typelogdata]) -> Void)

    {
        localconfigurations = configurations
        multipletaskstate = multipletaskstateDelegate
        executeprogressdetails = executeprogressdetailsDelegate
        localfilehandler = filehandler
        localupdatedates = updatedates
        localupdatelogrecords = updatelogrecords

        guard uuids.count > 0 else {
            Logger.process.warning("class ExecuteMultipleTasks, guard uuids.count > 0: \(uuids.count, privacy: .public)")
            multipletaskstate?.updatestate(state: .completed)
            return
        }
        let taskstosynchronize = configurations.filter { uuids.contains($0.id) }
        guard taskstosynchronize.count > 0 else {
            Logger.process.warning("class ExecuteMultipleTasks, guard uuids.contains($0.id): \(uuids.count, privacy: .public)")
            multipletaskstate?.updatestate(state: .completed)
            return
        }
        prepareandstartexecutetasks(configurations: taskstosynchronize)
        startexecution()
    }

    deinit {
        self.stackoftasktobeexecuted = nil
    }

    func abort() {
        stackoftasktobeexecuted = nil
        setabort = true
    }
}

extension ExecuteMultipleTasks {
    func processtermination(_ data: [String]?, _ hiddenID: Int?) {
        guard setabort == false else { return }
        // Log records
        // If snahost task the snapshotnum is increased when updating the configuration.
        // When creating the logrecord, decrease the snapshotum by 1
        if let hiddenID = hiddenID, let data = data {
            configrecords.append((hiddenID, Date().en_us_string_from_date()))
            schedulerecords.append((hiddenID, Numbers(data).stats()))
        }

        guard stackoftasktobeexecuted?.count ?? 0 > 0 else {
            // Update time stamps configurations and logrecords
            localupdatedates(configrecords)
            localupdatelogrecords(schedulerecords)
            // Run is completed
            multipletaskstate?.updatestate(state: .completed)
            return
        }
        if let hiddenID = stackoftasktobeexecuted?.remove(at: 0) {
            executeprogressdetails?.hiddenIDatwork = hiddenID
            let execution = ExecuteOneTask(hiddenID: hiddenID,
                                           configurations: localconfigurations,
                                           termination: processtermination,
                                           filehandler: localfilehandler)
            execution.startexecution()
        }
    }
}

// swiftlint:enable line_length
