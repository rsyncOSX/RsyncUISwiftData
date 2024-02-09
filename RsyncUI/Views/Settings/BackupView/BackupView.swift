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
        Text(/*@START_MENU_TOKEN@*/"Hello, World!"/*@END_MENU_TOKEN@*/)
    }
}
