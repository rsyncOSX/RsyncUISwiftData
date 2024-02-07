//
//  LogsbyConfigurationView.swift
//  RsyncOSXSwiftUI
//
//  Created by Thomas Evensen on 04/01/2021.
//  Copyright © 2021 Thomas Evensen. All rights reserved.
//

import Combine
import SwiftData
import SwiftUI

struct LogsbyConfigurationView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var configurations: [SynchronizeConfiguration]
    @Query private var logrecords: [LogRecords]

    @Query(sort: [SortDescriptor(\Log.dateExecuted)])
    var records: [Log]

    @State private var uuid: UUID?
    @State private var selecteduuids = Set<SynchronizeConfiguration.ID>()
    @State private var selectedloguuids = Set<Log.ID>()
    // Filterstring
    @State private var filterstring: String = ""
    @State var publisher = PassthroughSubject<String, Never>()
    @State private var debouncefilterstring: String = ""
    @State private var showindebounce: Bool = false
    // Number of logs
    @State private var numberoflogs: Int = 0

    var body: some View {
        VStack {
            HStack {
                ListofTasksLightView(selecteduuids: $selecteduuids)
                    .onChange(of: selecteduuids) {
                        if let index = configurations.firstIndex(where: { $0.id == selecteduuids.first }) {
                        } else {
                            uuid = nil
                        }

                        let selected = configurations.filter { config in
                            selecteduuids.contains(config.id)
                        }
                        if selected.count == 1 {
                            let selecteduuid = logrecords.filter { record in
                                record.hiddenID == selected[0].hiddenID
                            }
                            if selecteduuid.count == 1 {
                                uuid = selecteduuid[0].id
                            }
                        }
                    }

                if uuid == nil {
                    LogRecordsTableView(sort: SortDescriptor(\Log.dateExecuted),
                                        searchString: debouncefilterstring, $numberoflogs)
                } else {
                    LogRecordsTableByUUIDView(sort: SortDescriptor(\Log.dateExecuted),
                                              searchString: debouncefilterstring,
                                              uuid: uuid ?? UUID(),
                                              $numberoflogs)
                }
            }
            HStack {
                Text("Number of log records: ")

                if showindebounce {
                    indebounce
                } else {
                    Text("\(numberoflogs)")
                }
                Spacer()
            }
            .padding()
        }
        .onAppear {
            numberoflogs = records.count
        }
        .searchable(text: $filterstring)
        .onChange(of: filterstring) {
            showindebounce = true
            publisher.send(filterstring)
        }
        .onReceive(
            publisher.debounce(
                for: .seconds(1),
                scheduler: DispatchQueue.main
            )
        ) { filter in
            showindebounce = false
            debouncefilterstring = filter
        }
        .toolbar(content: {
            ToolbarItem {
                Button {
                    selectedloguuids.removeAll()
                    selecteduuids.removeAll()

                } label: {
                    Image(systemName: "clear")
                }
                .help("Reset selections")
            }
        })
    }

    var indebounce: some View {
        ProgressView()
            .controlSize(.small)
    }
}

/*

 @Query(filter: #Predicate<Log> { $0.dateExecuted.contains("1 feb") },
        sort: [SortDescriptor(\Log.dateExecuted)])
 var filteredlogrecords: [Log]

 @Query(sort: [SortDescriptor(\Log.dateExecuted)])
 var records: [Log]

 @Query var logrecords: [LogRecords]
 init(hiddenID: Int) {
         _logrecords = Query(filter: #Predicate { $0.hiddenID == hiddenID })
 }

 @Query var filteredlogrecords: [Log]
 init(filter: String) {
     _filteredlogrecords = Query(filter: #Predicate {($0.dateExecuted.contains(filter))})
 }
 */
