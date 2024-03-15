//
//  ExecuteEstimatedTasksView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 11/11/2023.
//

import OSLog
import SwiftData
import SwiftUI

struct ExecuteEstimatedTasksView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var configurations: [SynchronizeConfiguration]
    @Query private var logrecords: [LogRecords]

    @Bindable var executeprogressdetails: ExecuteProgressDetails
    @Binding var selecteduuids: Set<UUID>
    @Binding var path: [Tasks]

    @State private var multipletaskstate = ExecuteMultipleTasksState()
    @State private var selectedconfig: SynchronizeConfiguration?
    @State private var filterstring: String = ""
    @State private var focusaborttask: Bool = false
    @State private var doubleclick: Bool = false
    // Progress of synchronization
    @State private var progress: Double = 0

    var body: some View {
        ZStack {
            ListofTasksMainView(
                selecteduuids: $selecteduuids,
                filterstring: $filterstring,
                doubleclick: $doubleclick,
                progress: $progress,
                executeprogressdetails: executeprogressdetails,
                max: executeprogressdetails.getmaxcountbytask()
            )

            if multipletaskstate.executionstate == .completed { labelcompleted }
            if multipletaskstate.executionstate == .execute { ProgressView() }
            if focusaborttask { labelaborttask }
        }
        .onAppear(perform: {
            executemultipleestimatedtasks()
        })
        .onDisappear(perform: {
            executeprogressdetails.estimatedlist = nil
        })
        .focusedSceneValue(\.aborttask, $focusaborttask)
        .toolbar(content: {
            ToolbarItem {
                Button {
                    abort()
                } label: {
                    Image(systemName: "stop.fill")
                }
                .help("Abort (⌘K)")
            }
        })
    }

    // When status execution is .completed, present label and execute completed.
    var labelcompleted: some View {
        Label(multipletaskstate.executionstate.rawValue, systemImage: "play.fill")
            .onAppear(perform: {
                completed()
                path.removeAll()
            })
    }

    var labelaborttask: some View {
        Label("", systemImage: "play.fill")
            .onAppear(perform: {
                focusaborttask = false
                abort()
            })
    }
}

extension ExecuteEstimatedTasksView {
    func filehandler(count: Int) {
        progress = Double(count)
    }

    func completed() {
        executeprogressdetails.hiddenIDatwork = -1
        multipletaskstate.updatestate(state: .start)
        selecteduuids.removeAll()
        path.removeAll()
    }

    func abort() {
        executeprogressdetails.hiddenIDatwork = -1
        multipletaskstate.updatestate(state: .start)
        selecteduuids.removeAll()
        _ = InterruptProcess()
        path.removeAll()
    }

    func executemultipleestimatedtasks() {
        var uuids: Set<SynchronizeConfiguration.ID>?
        if selecteduuids.count > 0 {
            uuids = selecteduuids
        } else if executeprogressdetails.estimatedlist?.count ?? 0 > 0 {
            let uuidcount = executeprogressdetails.estimatedlist?.compactMap { $0.id }
            uuids = Set<SynchronizeConfiguration.ID>()
            for i in 0 ..< (uuidcount?.count ?? 0) where
                executeprogressdetails.estimatedlist?[i].datatosynchronize == true
            {
                uuids?.insert(uuidcount?[i] ?? UUID())
            }
        }
        guard (uuids?.count ?? 0) > 0 else { return }
        if let uuids = uuids {
            multipletaskstate.updatestate(state: .execute)
            ExecuteMultipleTasks(uuids: uuids,
                                 configurations: configurations,
                                 multipletaskstateDelegate: multipletaskstate,
                                 executeprogressdetailsDelegate: executeprogressdetails,
                                 filehandler: filehandler,
                                 updatedates: updatedates,
                                 updatelogrecords: updatelogrecords)
        }
    }

    func updatedates(_ configrecords: [Typelogdata]) {
        for i in 0 ..< configrecords.count {
            let hiddenID = configrecords[i].0
            let date = configrecords[i].1
            if let index = configurations.firstIndex(where: { $0.hiddenID == hiddenID }) {
                // Caution, snapshotnum already increased before logrecord
                if configurations[index].task == SharedReference.shared.snapshot {
                    if let num = configurations[index].snapshotnum {
                        configurations[index].snapshotnum = num + 1
                    }
                }
                configurations[index].dateRun = date
            }
        }
    }

    func updatelogrecords(_ logrecords: [Typelogdata]) {
        if SharedReference.shared.detailedlogging {
            for i in 0 ..< logrecords.count {
                let hiddenID = logrecords[i].0
                let stats = logrecords[i].1
                let currendate = Date()
                let date = currendate.en_us_string_from_date()
                if let index = configurations.firstIndex(where: { $0.hiddenID == hiddenID }) {
                    var resultannotaded: String?
                    if configurations[index].task == SharedReference.shared.snapshot {
                        if let snapshotnum = configurations[index].snapshotnum {
                            resultannotaded = "(" + String(snapshotnum - 1) + ") " + stats
                        } else {
                            resultannotaded = "(" + "1" + ") " + stats
                        }
                    } else {
                        resultannotaded = stats
                    }
                    var inserted: Bool = addlogexisting(hiddenID,
                                                        resultannotaded ?? "",
                                                        date)
                    // Record does not exist, create new LogRecord (not inserted)
                    if inserted == false {
                        inserted = addlognew(hiddenID, resultannotaded ?? "", date)
                    }
                }
            }
        }
    }

    func addlogexisting(_ hiddenID: Int, _ result: String, _ date: String) -> Bool {
        if let index = logrecords.firstIndex(where: { $0.hiddenID == hiddenID }) {
            let log = Log(dateExecuted: date, resultExecuted: result)
            if logrecords[index].records == nil {
                logrecords[index].records = [Log]()
            }
            logrecords[index].records?.append(log)
            Logger.process.info("ExecuteEstimatedTasksView: added logrecord existing task")
            return true
        }
        return false
    }

    func addlognew(_ hiddenID: Int, _ result: String, _ date: String) -> Bool {
        let newrecord = LogRecords(hiddenID)
        let currendate = Date()
        newrecord.dateStart = currendate.en_us_string_from_date()
        let log = Log(dateExecuted: date, resultExecuted: result)
        newrecord.records = [Log]()
        newrecord.records?.append(log)
        modelContext.insert(newrecord)
        Logger.process.info("ExecuteEstimatedTasksView: added logrecord new task")
        return true
    }
}
