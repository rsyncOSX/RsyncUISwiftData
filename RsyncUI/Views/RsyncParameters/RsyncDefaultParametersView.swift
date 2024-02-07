//
//  RsyncDefaultParametersView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 20/11/2023.
//

import SwiftData
import SwiftUI

struct RsyncDefaultParametersView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var configurations: [SynchronizeConfiguration]

    @Binding var path: [ParametersTasks]

    @State private var parameters = ObservableParametersDefault()
    @State private var selectedconfig: SynchronizeConfiguration?
    @State private var selectedrsynccommand = RsyncCommand.synchronize
    @State private var valueselectedrow: String = ""
    @State private var selecteduuids = Set<SynchronizeConfiguration.ID>()

    var body: some View {
        VStack {
            HStack {
                VStack(alignment: .leading) {
                    Section(header: headerremove) {
                        VStack(alignment: .leading) {
                            ToggleViewDefault("-e ssh", $parameters.removessh)
                                .onChange(of: parameters.removessh) {
                                    parameters.deletessh(parameters.removessh)
                                }
                            ToggleViewDefault("--compress", $parameters.removecompress)
                                .onChange(of: parameters.removecompress) {
                                    parameters.deletecompress(parameters.removecompress)
                                }
                            ToggleViewDefault("--delete", $parameters.removedelete)
                                .onChange(of: parameters.removedelete) {
                                    parameters.deletedelete(parameters.removedelete)
                                }
                        }
                    }

                    Section(header: headerdaemon) {
                        ToggleViewDefault("daemon", $parameters.daemon)
                    }

                    Spacer()
                }

                ListofTasksLightView(selecteduuids: $selecteduuids)
                    .frame(maxWidth: .infinity)
                    .onChange(of: selecteduuids) {
                        let selected = configurations.filter { config in
                            selecteduuids.contains(config.id)
                        }
                        if selected.count == 1 {
                            selectedconfig = configurations[0]
                            parameters.setvalues(selectedconfig)
                        } else {
                            selectedconfig = nil
                            parameters.setvalues(selectedconfig)
                        }
                    }
            }

            Spacer()

            RsyncCommandView(config: $parameters.configuration, selectedrsynccommand: $selectedrsynccommand)
        }
        .padding()
    }

    // Header remove
    var headerremove: some View {
        Text("Remove default rsync parameters")
    }

    // Daemon header
    var headerdaemon: some View {
        Text("Enable rsync daemon")
    }
}
