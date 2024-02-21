//
//  Sidebar.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 12/12/2023.
//

import SwiftData
import SwiftUI

enum Sidebaritems: String, Identifiable, CaseIterable {
    case synchronize, tasks, rsync_parameters, log_listings, restore
    var id: String { rawValue }
}

struct Sidebar: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var configurations: [SynchronizeConfiguration]

    @Binding var selecteduuids: Set<SynchronizeConfiguration.ID>
    @Bindable var errorhandling: AlertError
    @State private var selectedview: Sidebaritems = .synchronize

    var body: some View {
        NavigationSplitView {
            Divider()

            List(Sidebaritems.allCases, selection: $selectedview) { selectedview in
                NavigationLink(value: selectedview) {
                    SidebarRow(sidebaritem: selectedview)
                }

                if selectedview == .tasks { Divider() }
            }

        } detail: {
            selectView(selectedview)
        }
        .alert(isPresented: errorhandling.presentalert, content: {
            if let error = errorhandling.activeError {
                Alert(localizedError: error)
            } else {
                Alert(title: Text("No error"))
            }
        })
    }

    @ViewBuilder
    func selectView(_ view: Sidebaritems) -> some View {
        switch view {
        case .tasks:
            AddTaskView()
        case .log_listings:
            LogsbyConfigurationView()
        case .rsync_parameters:
            RsyncParametersView()
        case .restore:
            NavigationStack {
                RestoreTableView()
            }
        case .synchronize:
            SidebarTasksView(selecteduuids: $selecteduuids)
        }
    }
}

struct SidebarRow: View {
    var sidebaritem: Sidebaritems

    var body: some View {
        Label(sidebaritem.rawValue.localizedCapitalized.replacingOccurrences(of: "_", with: " "),
              systemImage: systemimage(sidebaritem))
    }

    func systemimage(_ view: Sidebaritems) -> String {
        switch view {
        case .tasks:
            return "text.badge.plus"
        case .log_listings:
            return "text.alignleft"
        case .rsync_parameters:
            return "command.circle.fill"
        case .restore:
            return "arrowshape.turn.up.forward"
        case .synchronize:
            return "arrowshape.turn.up.backward"
        }
    }
}
