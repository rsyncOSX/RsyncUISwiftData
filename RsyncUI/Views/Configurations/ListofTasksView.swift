//
//  ListofTasksView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 18/05/2023.
//

import SwiftData
import SwiftUI

struct ListofTasksView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var configurations: [SynchronizeConfiguration]
    @Binding var selecteduuids: Set<SynchronizeConfiguration.ID>
    @Binding var filterstring: String

    var body: some View {
        VStack {
            tabledata
        }
        .searchable(text: $filterstring)
    }

    var tabledata: some View {
        Table(configurations.filter {
            filterstring.isEmpty ? true : $0.backupID.contains(filterstring)
        }, selection: $selecteduuids) {
            TableColumn("%") { _ in
                Text("")
            }
            .width(max: 50)
            TableColumn("Profile", value: \.profile)
                .width(min: 50, max: 200)
            TableColumn("Synchronize ID", value: \.backupID)
                .width(min: 50, max: 200)
            TableColumn("Local catalog", value: \.localCatalog)
                .width(min: 80, max: 300)
            TableColumn("Remote catalog", value: \.offsiteCatalog)
                .width(min: 80, max: 300)
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
    }
}
