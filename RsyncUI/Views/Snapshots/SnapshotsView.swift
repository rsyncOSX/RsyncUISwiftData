//
//  SnapshotsView.swift
//  RsyncSwiftUI
//
//  Created by Thomas Evensen on 23/02/2021.
//

import SwiftData
import SwiftUI

struct SnapshotsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var configurations: [SynchronizeConfiguration]
    @Query private var logrecords: [LogRecords]

    @State private var snapshotdata = SnapshotData()
    @State private var selectedconfig: SynchronizeConfiguration?
    @State private var snapshotrecords: SnapshotLogRecords?
    @State private var selectedconfiguuid = Set<SynchronizeConfiguration.ID>()
    // If not a snapshot
    @State private var notsnapshot = false
    // Plan for tagging and administrating snapshots
    @State private var snaplast: String = PlanSnapshots.Last.rawValue
    @State private var snapdayofweek: String = StringDayofweek.Sunday.rawValue
    // Update plan and snapday
    @State private var updated: Bool = false
    // Confirm delete
    @State private var confirmdeletesnapshots = false
    // Alert for delete
    @State private var showAlertfordelete = false
    // Focus buttons from the menu
    @State private var focustagsnapshot: Bool = false
    @State private var focusaborttask: Bool = false
    // Delete
    @State private var confirmdelete: Bool = false
    // Delete is completed and reload of data
    @State private var deleteiscompleted: Bool = false
    // Filter
    @State private var filterstring: String = ""

    var body: some View {
        ZStack {
            HStack {
                ListofTasksLightView(selecteduuids: $selectedconfiguuid)
                    .onChange(of: selectedconfiguuid) {
                        if let index = configurations.firstIndex(where: { $0.id == selectedconfiguuid.first }) {
                            selectedconfig = configurations[index]
                            getdata()
                        } else {
                            selectedconfig = nil
                            snapshotdata.setsnapshotdata(nil)
                            filterstring = ""
                        }
                    }

                SnapshotListView(snapshotdata: $snapshotdata,
                                 snapshotrecords: $snapshotrecords,
                                 filterstring: $filterstring,
                                 selectedconfig: $selectedconfig)
                    .onChange(of: deleteiscompleted) {
                        if deleteiscompleted == true {
                            getdata()
                            deleteiscompleted = false
                        }
                    }
            }

            if snapshotdata.snapshotlist { AlertToast(displayMode: .alert, type: .loading) }
            if notsnapshot == true { notasnapshottask }
            if snapshotdata.inprogressofdelete == true { progressdelete }
        }

        if focustagsnapshot == true { labeltagsnapshot }
        if focusaborttask { labelaborttask }

        HStack {
            VStack(alignment: .leading) {
                pickersnaplast

                pickersnapdayoffweek
            }

            labelnumberoflogs

            Spacer()
        }
        .focusedSceneValue(\.tagsnapshot, $focustagsnapshot)
        .focusedSceneValue(\.aborttask, $focusaborttask)
        .toolbar(content: {
            ToolbarItem {
                Button {
                    updateplansnapshot()
                } label: {
                    Image(systemName: "square.and.arrow.down.fill")
                        .foregroundColor(Color(.blue))
                }
                .help("Update plan snapshot")
            }

            ToolbarItem {
                Button {
                    focusaborttask = true
                } label: {
                    Image(systemName: "stop.fill")
                }
                .help("Abort (⌘K)")
            }
        })
        .searchable(text: $filterstring)
        .padding()
    }

    var labelnumberoflogs: some View {
        VStack(alignment: .leading) {
            Text(NSLocalizedString("Number of logrecords", comment: "") +
                ": " + "\(snapshotdata.logrecordssnapshot?.count ?? 0)")
            Text(NSLocalizedString("Selected logrecords for delete", comment: "") +
                ": " + "\(snapshotdata.snapshotuuidsfordelete.count)")
        }
    }

    var notasnapshottask: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 15).fill(Color.gray.opacity(0.1))
            Text("Not a snapshot task")
                .font(.title3)
                .foregroundColor(Color.accentColor)
        }
        .frame(width: 200, height: 20, alignment: .center)
        .background(RoundedRectangle(cornerRadius: 25).stroke(Color.gray, lineWidth: 2))
    }

    var pickersnapdayoffweek: some View {
        Picker("",
               selection: $snapdayofweek)
        {
            ForEach(StringDayofweek.allCases) { Text($0.description)
                .tag($0)
            }
        }
        .pickerStyle(DefaultPickerStyle())
        .frame(width: 100)
    }

    var pickersnaplast: some View {
        Picker("",
               selection: $snaplast)
        {
            ForEach(PlanSnapshots.allCases) { Text($0.description)
                .tag($0)
            }
        }
        .pickerStyle(DefaultPickerStyle())
        .frame(width: 100)
    }

    var labeltagsnapshot: some View {
        Label("", systemImage: "play.fill")
            .onAppear(perform: {
                focustagsnapshot = false
                tagsnapshots()
            })
    }

    var labelaborttask: some View {
        Label("", systemImage: "play.fill")
            .onAppear(perform: {
                focusaborttask = false
                abort()
            })
    }

    var progressdelete: some View {
        ProgressView("Deleting snapshots",
                     value: Double(snapshotdata.remainingsnapshotstodelete),
                     total: Double(snapshotdata.maxnumbertodelete))
            .frame(width: 200, alignment: .center)
            .onDisappear(perform: {
                deleteiscompleted = true
            })
    }
}

extension SnapshotsView {
    func abort() {
        snapshotdata.setsnapshotdata(nil)
        snapshotdata.delete?.snapshotcatalogstodelete = nil
        // kill any ongoing processes
        _ = InterruptProcess()
    }

    func getdata() {
        snapshotdata.snapshotuuidsfordelete.removeAll()
        guard SharedReference.shared.process == nil else { return }
        if let config = selectedconfig {
            guard config.task == SharedReference.shared.snapshot else {
                notsnapshot = true
                // Show added for 1 second
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    notsnapshot = false
                }
                return
            }
            // Setting values for tagging snapshots
            if let snaplast = config.snaplast {
                if snaplast == 0 {
                    self.snaplast = PlanSnapshots.Last.rawValue
                } else {
                    self.snaplast = PlanSnapshots.Every.rawValue
                }
            }
            if let snapdayofweek = config.snapdayoffweek {
                self.snapdayofweek = snapdayofweek
            }
            snapshotdata.snapshotlist = true
            // TODO: fix
            if let config = selectedconfig {
                _ = Snapshotlogsandcatalogs(config: config,
                                            logrecords: logrecords,
                                            snapshotdata: snapshotdata)
            }
        }
    }

    func tagsnapshots() {
        if let config = selectedconfig {
            guard config.task == SharedReference.shared.snapshot else { return }
            guard (snapshotdata.getsnapshotdata()?.count ?? 0) > 0 else { return }
            /*
             var snapdayoffweek: String = ""
             var snaplast: String = ""
             plan == 1, only keep last day of week in a month
             plan == 0, keep last day of week every week
             dayofweek
             */
            var localsnaplast = 0
            if snaplast == PlanSnapshots.Last.rawValue {
                localsnaplast = 0 // keep selected day of week every week of month
            } else {
                localsnaplast = 1 // keep last selected day of week pr month
            }
            let tagged = TagSnapshots(plan: localsnaplast,
                                      snapdayoffweek: snapdayofweek,
                                      data: snapshotdata.getsnapshotdata())
            // Market data for delete
            snapshotdata.setsnapshotdata(tagged.logrecordssnapshot)
        }
    }

    func updateplansnapshot() {
        if var selectedconfig = selectedconfig {
            guard selectedconfig.task == SharedReference.shared.snapshot else { return }
            switch snaplast {
            case PlanSnapshots.Last.rawValue:
                selectedconfig.snaplast = 0
            case PlanSnapshots.Every.rawValue:
                selectedconfig.snaplast = 1
            default:
                return
            }
            selectedconfig.snapdayoffweek = snapdayofweek
            // TODO: fix
            /*
             let updateconfiguration =
                 UpdateConfigurations(profile: rsyncUIdata.profile,
                                      configurations: rsyncUIdata.getallconfigurations())
             updateconfiguration.updateconfiguration(selectedconfig, false)
             */
            updated = true
        }
    }
}
