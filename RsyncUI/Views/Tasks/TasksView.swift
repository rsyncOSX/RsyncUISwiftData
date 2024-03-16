//
//  TasksView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 10/11/2023.
//

import Observation
import OSLog
import SwiftData
import SwiftUI

struct CopyItem: Identifiable, Codable, Transferable {
    let id: UUID
    let hiddenID: Int
    let task: String

    static var transferRepresentation: some TransferRepresentation {
        CodableRepresentation(contentType: .data)
    }
}

enum TypeofTask: String, CaseIterable, Identifiable, CustomStringConvertible {
    case synchronize, syncremote, snapshot

    var id: String { rawValue }
    var description: String { rawValue.localizedLowercase }
}

@Observable
final class Selectedconfig {
    var config: SynchronizeConfiguration?
}

struct TasksView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var configurations: [SynchronizeConfiguration]
    // The object holds the progressdata for the current estimated task
    // which is executed. Data for progressview.
    @Bindable var executeprogressdetails: ExecuteProgressDetails
    @Bindable var estimateprogressdetails: EstimateProgressDetails
    @Binding var selecteduuids: Set<SynchronizeConfiguration.ID>
    // Navigation path
    @Binding var path: [Tasks]

    @State private var estimatingstate = EstimatingState()
    // Focus buttons from the menu
    @State private var focusstartestimation: Bool = false
    @State private var focusstartexecution: Bool = false
    // Filterstring
    @State private var filterstring: String = ""
    // Local data for present local and remote info about task
    @State private var localdata: [String] = []
    @State var selectedconfig = Selectedconfig()
    @State private var doubleclick: Bool = false
    // Alert button
    @State private var showingAlert = false
    // Progress synchronizing
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
            .frame(maxWidth: .infinity)
            .onChange(of: selecteduuids) {
                if let index = configurations.firstIndex(where: { $0.id == selecteduuids.first }) {
                    selectedconfig.config = configurations[index]
                } else {
                    selectedconfig.config = nil
                }
                estimateprogressdetails.uuids = selecteduuids
            }

            Group {
                if focusstartestimation { labelstartestimation }
                if focusstartexecution { labelstartexecution }
                if doubleclick { doubleclickaction }
            }
        }
        .focusedSceneValue(\.startestimation, $focusstartestimation)
        .focusedSceneValue(\.startexecution, $focusstartexecution)
        .toolbar(content: {
            ToolbarItem {
                profilepicker
            }

            ToolbarItem {
                Button {
                    // Filterstring is active, no selections. Select tasks by filterstring
                    if filterstring.isEmpty == false, selectedconfig.config == nil, selecteduuids.isEmpty == true {
                        for i in 0 ..< configurations.count where configurations[i].profile.contains(filterstring) {
                            selecteduuids.insert(configurations[i].id)
                        }
                        Logger.process.info("DryRun filter is active, select tasks by filter")
                    }
                    path.append(Tasks(task: .estimatedview))
                } label: {
                    Image(systemName: "wand.and.stars")
                        .foregroundColor(Color(.blue))
                }
                .help("Estimate (⌘E)")
            }

            ToolbarItem {
                Button {
                    execute()
                } label: {
                    Image(systemName: "arrowshape.turn.up.left.fill")
                        .foregroundColor(Color(.blue))
                }
                .help("Synchronize (⌘R)")
            }

            ToolbarItem {
                Button {
                    selecteduuids.removeAll()
                    reset()
                } label: {
                    Image(systemName: "clear")
                        .foregroundColor(Color(.red))
                }
                .help("Reset estimates")
            }

            ToolbarItem {
                Button {
                    guard selecteduuids.count > 0 else { return }
                    guard selecteduuids.count == 1 else {
                        path.append(Tasks(task: .estimatedview))
                        return
                    }
                    if estimateprogressdetails.tasksareestimated(selecteduuids) {
                        path.append(Tasks(task: .dryrunonetaskalreadyestimated))
                    } else {
                        path.append(Tasks(task: .dryrunonetask))
                    }
                } label: {
                    Image(systemName: "info")
                }
                .help("Rsync output estimated task")
            }

            ToolbarItem {
                Button {
                    path.append(Tasks(task: .viewlogfile))
                } label: {
                    Image(systemName: "doc.plaintext")
                }
                .help("View logfile")
            }

            ToolbarItem {
                Button {
                    path.append(Tasks(task: .quick_synchronize))
                } label: {
                    Image(systemName: "hare")
                }
                .help("Quick synchronize")
            }
        })
        .alert(isPresented: $showingAlert) {
            Alert(
                title: Text("Synchronize all tasks with NO estimating first?"),
                primaryButton: .default(Text("Synchronize")) {
                    path.append(Tasks(task: .executenoestimatetasksview))
                },
                secondaryButton: .cancel()
            )
        }
    }

    var profilepicker: some View {
        HStack {
            Picker("Filter", selection: $filterstring) {
                Text("").tag("")
                ForEach(profilenames.profiles, id: \.self) { profile in
                    Text(profile.profile)
                        .tag(profile.profile)
                }
            }
            .frame(width: 180)
            .onChange(of: filterstring) {
                // selecteduuids.removeAll()
            }
        }
    }

    var profilenames: Profilenames {
        return Profilenames(configurations)
    }

    var doubleclickaction: some View {
        Label("", systemImage: "play.fill")
            .foregroundColor(.black)
            .onAppear(perform: {
                doubleclickactionfunction()
                doubleclick = false
            })
    }

    var labelstartestimation: some View {
        Label("", systemImage: "play.fill")
            .foregroundColor(.black)
            .onAppear(perform: {
                path.append(Tasks(task: .estimatedview))
                focusstartestimation = false
            })
    }

    var labelstartexecution: some View {
        Label("", systemImage: "play.fill")
            .foregroundColor(.black)
            .onAppear(perform: {
                execute()
                focusstartexecution = false
            })
    }
}

extension TasksView {
    func doubleclickactionfunction() {
        if estimateprogressdetails.getestimatedlist() == nil {
            dryrun()
        } else if estimateprogressdetails.tasksareestimated(selecteduuids) {
            Logger.process.info("Doubleclick: execute a real run for one task only")
            executeprogressdetails.estimatedlist = estimateprogressdetails.getestimatedlist()
            execute()
        } else {
            dryrun()
        }
    }

    func dryrun() {
        if selectedconfig.config != nil,
           estimateprogressdetails.getestimatedlist()?.count ?? 0 == 0
        {
            Logger.process.info("DryRun: execute a dryrun for one task only")
            doubleclick = false
            path.append(Tasks(task: .dryrunonetask))
        } else if selectedconfig.config != nil,
                  estimateprogressdetails.executeanotherdryrun() == true
        {
            Logger.process.info("DryRun: new task same profile selected, execute a dryrun")
            doubleclick = false
            path.append(Tasks(task: .dryrunonetask))

        } else if selectedconfig.config != nil,
                  estimateprogressdetails.alltasksestimated() == false
        {
            Logger.process.info("DryRun: profile is changed, new task selected, execute a dryrun")
            doubleclick = false
            path.append(Tasks(task: .dryrunonetask))
        }
    }

    func execute() {
        // Filterstring is active, no selections. Select tasks by filterstring
        if filterstring.isEmpty == false, selectedconfig.config == nil, selecteduuids.isEmpty == true {
            for i in 0 ..< configurations.count where configurations[i].profile.contains(filterstring) {
                selecteduuids.insert(configurations[i].id)
            }
            Logger.process.info("Execute() filter is active, select tasks by filter")
        }
        // All tasks are estimated and ready for execution.
        if selecteduuids.count == 0,
           estimateprogressdetails.alltasksestimated() == true

        {
            Logger.process.info("Execute() all estimated tasks")
            // Execute all estimated tasks
            selecteduuids = estimateprogressdetails.getuuids()
            estimatingstate.updatestate(state: .start)
            // Change view, see SidebarTasksView
            path.append(Tasks(task: .executestimatedview))

        } else if selecteduuids.count >= 1,
                  estimateprogressdetails.tasksareestimated(selecteduuids) == true

        {
            // One or some tasks are selected and estimated
            Logger.process.info("Execute() estimated tasks only")
            // Execute estimated tasks only
            // Execute all estimated tasks
            selecteduuids = estimateprogressdetails.getuuids()
            estimatingstate.updatestate(state: .start)
            // Change view, see SidebarTasksView
            path.append(Tasks(task: .executestimatedview))
        } else {
            // Execute all tasks, no estimate
            Logger.process.info("Execute() selected or all tasks NO estimate")
            // Execute tasks, no estimate
            showingAlert = true
            // path.append(Tasks(task: .executenoestimatetasksview))
            // path.append in Showing alert
        }
    }

    func reset() {
        executeprogressdetails.estimatedlist = nil
        estimateprogressdetails.resetcounts()
        estimatingstate.updatestate(state: .start)
        selectedconfig.config = nil
    }

    func abort() {
        executeprogressdetails.estimatedlist = nil
        estimateprogressdetails.resetcounts()
        selecteduuids.removeAll()
        estimatingstate.updatestate(state: .start)
        _ = InterruptProcess()
        focusstartestimation = false
        focusstartexecution = false
    }
}
