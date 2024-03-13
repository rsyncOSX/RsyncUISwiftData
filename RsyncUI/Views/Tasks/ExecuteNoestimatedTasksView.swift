//
//  ExecuteNoestimatedTasksView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 11/11/2023.
//

import OSLog
import SwiftData
import SwiftUI

struct ExecuteNoestimatedTasksView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var configurations: [SynchronizeConfiguration]
    @Query private var logrecords: [LogRecords]

    @Binding var selecteduuids: Set<UUID>
    @Binding var path: [Tasks]

    // Must be stateobject
    @State private var executeasyncnoestimation = ExecuteAsyncNoEstimation()
    @State private var filterstring: String = ""
    @State private var progressviewshowinfo: Bool = true
    @State private var executealltasksasync: ExecuteTasksNOEstimation?
    @State private var confirmdelete = false
    @State private var focusaborttask: Bool = false

    var body: some View {
        ZStack {
            ListofTasksView(selecteduuids: $selecteduuids,
                            filterstring: $filterstring)

            if executeasyncnoestimation.executeasyncnoestimationcompleted == true { labelcompleted }
            if progressviewshowinfo { AlertToast(displayMode: .alert, type: .loading) }
            if focusaborttask { labelaborttask }
        }
        .onAppear(perform: {
            Task {
                await executeallnoestimationtasks()
            }
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
        Label("", systemImage: "play.fill")
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

extension ExecuteNoestimatedTasksView {
    func completed() {
        progressviewshowinfo = false
        executeasyncnoestimation.reset()
    }

    func abort() {
        selecteduuids.removeAll()
        _ = InterruptProcess()
        progressviewshowinfo = false
        executeasyncnoestimation.reset()
    }

    func executeallnoestimationtasks() async {
        Logger.process.info("ExecuteallNOtestimatedtasks() : \(selecteduuids, privacy: .public)")
        executeasyncnoestimation.startasyncexecutealltasksnoestimation()
        executealltasksasync =
            ExecuteTasksNOEstimation(configurations: configurations,
                                     executeasyncnoestimation: executeasyncnoestimation,
                                     uuids: selecteduuids,
                                     filter: filterstring,
                                     updatedates: updatedates,
                                     updatelogrecords: updatelogrecords)
        await executealltasksasync?.startexecution()
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
            Logger.process.info("ExecuteNoestimatedTasksView: added logrecord existing task")
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
        Logger.process.info("ExecuteNoestimatedTasksView: added logrecord new task")
        return true
    }
}
