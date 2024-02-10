//
//  BackupView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 09/02/2024.
//

import SwiftData
import SwiftUI

struct BackupView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var configurations: [SynchronizeConfiguration]
    @Query private var logrecords: [LogRecords]

    var body: some View {
        HStack {
            Button("Write data") {
                WriteConfigurationJSON(configurations)
                WriteLogRecordsJSON(logrecords)
            }
            .buttonStyle(ColorfulButtonStyle())

            Button("Read data") {
                let importconfigurations = ReadConfigurationJSON()
                let importlogrecords = ReadLogRecordsJSON()
                print(importconfigurations.configurations?.count)
                print(importlogrecords.logrecords?.count)
            }
            .buttonStyle(ColorfulButtonStyle())
        }
    }
}
