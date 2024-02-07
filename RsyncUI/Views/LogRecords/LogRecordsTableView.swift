//
//  LogRecordsTableView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 06/02/2024.
//

import SwiftData
import SwiftUI

struct LogRecordsTableView: View {
    @Environment(\.modelContext) var modelContext
    @Query(sort: [SortDescriptor(\Log.dateExecuted, order: .reverse)])
    var records: [Log]

    @State private var selectedloguuids = Set<Log.ID>()
    // Alert for delete
    @State private var showAlertfordelete = false
    // Number of logs
    @Binding var number: Int

    var body: some View {
        Table(records, selection: $selectedloguuids) {
            TableColumn("Date") { data in
                let date = data.dateExecuted
                Text(date.en_us_date_from_string().localized_string_from_date())
            }

            TableColumn("Result") { data in
                Text(data.resultExecuted)
            }
        }
        .onAppear {
            number = records.count
        }
        .onDeleteCommand {
            showAlertfordelete = true
        }
        .overlay { if records.count == 0 {
            ContentUnavailableView {
                Label("There are no logs by this filter", systemImage: "doc.richtext.fill")
            } description: {
                Text("Try to search for other filter in Date or Result")
            }
        }
        }
        .sheet(isPresented: $showAlertfordelete) {
            DeleteLogsView(selectedloguuids: $selectedloguuids)
        }
    }

    init(sort: SortDescriptor<Log>, searchString: String, _ number: Binding<Int>) {
        _records = Query(filter: #Predicate {
            if searchString.isEmpty {
                return true
            } else {
                return $0.dateExecuted.localizedStandardContains(searchString)
            }
        }, sort: [sort])

        _number = number
    }
}
