//
//  DeleteLogsView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 17/03/2021.
//

import SwiftData
import SwiftUI

struct DeleteLogsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var logrecords: [LogRecords]
    @Environment(\.dismiss) var dismiss

    @Binding var selectedloguuids: Set<UUID>

    var body: some View {
        VStack {
            header

            Spacer()

            HStack {
                Button("Delete") { deletelogs(selectedloguuids) }
                    .buttonStyle(ColorfulRedButtonStyle())

                Button("Cancel") { dismiss() }
                    .buttonStyle(ColorfulButtonStyle())
            }
            .padding()
        }
        .padding()
    }

    var header: some View {
        HStack {
            let message = NSLocalizedString("Delete", comment: "")
                + " \(selectedloguuids.count) "
                + "log(s)?"
            Text(message)
                .font(.title2)
        }
        .padding()
    }

    func deletelogs(_ uuids: Set<UUID>) {
        var indexset = IndexSet()
        for i in 0 ..< logrecords.count {
            for j in 0 ..< uuids.count {
                if let index = logrecords[i].records?.firstIndex(
                    where: { $0.id == uuids[uuids.index(uuids.startIndex, offsetBy: j)] })
                {
                    indexset.insert(index)
                }
            }
            logrecords[i].records?.remove(atOffsets: indexset)
            indexset.removeAll()
        }
        dismiss()
    }
}
