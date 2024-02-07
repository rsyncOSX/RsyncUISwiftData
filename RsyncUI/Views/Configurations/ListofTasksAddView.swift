//
//  ListofTasksAddView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 25/08/2023.
//

import SwiftData
import SwiftUI

struct ListofTasksAddView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var configurations: [SynchronizeConfiguration]
    @Query private var logrecords: [LogRecords]

    @Binding var selecteduuids: Set<SynchronizeConfiguration.ID>

    @State private var confirmdelete: Bool = false

    var body: some View {
        tabledata
    }

    var tabledata: some View {
        Table(configurations, selection: $selecteduuids) {
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
                Text(String(format: "%.2f", seconds / (60 * 60 * 24)))
            }
            .width(max: 50)
            TableColumn("Last") { data in
                Text(data.dateRun ?? "")
            }
            .width(max: 120)
        }
        .confirmationDialog(
            NSLocalizedString("Delete configuration(s)", comment: "")
                + "?",
            isPresented: $confirmdelete
        ) {
            Button("Delete") {
                delete()
                confirmdelete = false
            }
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
    }
}
