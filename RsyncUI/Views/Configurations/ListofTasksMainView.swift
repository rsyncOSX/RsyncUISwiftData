//
//  ListofTasksMainView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 11/11/2023.
//

import SwiftData
import SwiftUI

struct ListofTasksMainView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var configurations: [SynchronizeConfiguration]
    @Query private var logrecords: [LogRecords]

    @Binding var selecteduuids: Set<SynchronizeConfiguration.ID>
    @Binding var filterstring: String
    @Binding var doubleclick: Bool
    // Progress of synchronization
    @Binding var progress: Double

    @State private var confirmdelete: Bool = false

    let executeprogressdetails: ExecuteProgressDetails
    let max: Double

    var body: some View {
        tabledata
            .overlay {
                if configurations.filter(
                    { filterstring.isEmpty ? true : $0.backupID.contains(filterstring) ||
                        filterstring.isEmpty ? true : $0.profile.contains(filterstring) }).isEmpty
                {
                    ContentUnavailableView {
                        Label("There are no tasks by this profile or Synchronize ID", systemImage: "doc.richtext.fill")
                    } description: {
                        Text("Try to search for other filter in profile or Synchronize ID \n If new user, add Tasks.")
                    }
                }
            }
            .searchable(text: $filterstring)
    }

    var tabledata: some View {
        Table(configurations.filter {
            filterstring.isEmpty ? true : $0.backupID.contains(filterstring) ||
                filterstring.isEmpty ? true : $0.profile.contains(filterstring)
        }, selection: $selecteduuids) {
            TableColumn("%") { data in
                if data.hiddenID == executeprogressdetails.hiddenIDatwork, max > 0 {
                    ProgressView("",
                                 value: progress,
                                 total: max)
                        .frame(alignment: .center)
                }
            }
            .width(min: 50, ideal: 50)
            TableColumn("Profile", value: \.profile)
                .width(min: 50, max: 200)
            TableColumn("Synchronize ID", value: \.backupID)
                .width(min: 50, max: 200)
            TableColumn("Task", value: \.task)
                .width(max: 80)
            TableColumn("Local catalog", value: \.localCatalog)
                .width(min: 80, max: 300)
            TableColumn("Remote catalog", value: \.offsiteCatalog)
                .width(min: 80, max: 300)
            TableColumn("Server") { data in
                if data.offsiteServer.count > 0 {
                    Text(data.offsiteServer)
                } else {
                    Text("localhost")
                }
            }
            .width(min: 50, max: 80)
            TableColumn("Days") { data in
                var seconds: Double {
                    if let date = data.dateRun {
                        let lastbackup = date.en_us_date_from_string()
                        return lastbackup.timeIntervalSinceNow * -1
                    } else {
                        return 0
                    }
                }
                if markconfig(seconds) {
                    Text(String(format: "%.2f", seconds / (60 * 60 * 24)))
                        .foregroundColor(.red)
                } else {
                    Text(String(format: "%.2f", seconds / (60 * 60 * 24)))
                }
            }
            .width(max: 50)
            TableColumn("Last") { data in
                if data.dateRun?.isEmpty == false {
                    Text(data.dateRun ?? "")
                } else {
                    if executeprogressdetails.taskisestimatedbyUUID(data.id) {
                        Text("Verified")
                            .foregroundColor(.green)
                    } else {
                        Text("Not verified")
                            .foregroundColor(.red)
                    }
                }
            }
            .width(max: 120)
        }
        .confirmationDialog(
            Text("Delete ^[\(selecteduuids.count) configuration](inflect: true)"),
            isPresented: $confirmdelete
        ) {
            Button("Delete") {
                delete()
                confirmdelete = false
            }
        }
        .contextMenu(forSelectionType: SynchronizeConfiguration.ID.self) { _ in
            // ...
        } primaryAction: { _ in
            doubleclick = true
        }
        .onDeleteCommand {
            confirmdelete = true
        }
    }

    func delete() {
        var indexset = IndexSet()
        var indexsetlogrecord = IndexSet()
        var hiddenIDfordelete: Int = -1

        if let index = configurations.firstIndex(
            where: { selecteduuids.contains($0.id) })
        {
            indexset.insert(index)
        }
        for index in indexset {
            hiddenIDfordelete = configurations[index].hiddenID
            modelContext.delete(configurations[index])
        }

        if let index = logrecords.firstIndex(
            where: { $0.hiddenID == hiddenIDfordelete })
        {
            indexsetlogrecord.insert(index)
            modelContext.delete(logrecords[index])
        }

        selecteduuids.removeAll()
    }

    func markconfig(_ seconds: Double) -> Bool {
        return seconds / (60 * 60 * 24) > Double(SharedReference.shared.marknumberofdayssince)
    }
}
