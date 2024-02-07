//
//  Usersettings.swift
//  RsyncSwiftUI
//
//  Created by Thomas Evensen on 10/02/2021.
//
// swiftlint:disable line_length

import OSLog
import SwiftData
import SwiftUI

struct Usersettings: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var userconfiguration: [UserConfiguration]

    @Environment(AlertError.self) private var alerterror
    @State private var usersettings = ObservableUsersetting()
    @State private var rsyncversion = Rsyncversion()
    // Rsync paths
    @State private var defaultpathrsync = SetandValidatepathforrsync().getpathforrsync()

    var body: some View {
        HStack {
            // Column 1
            VStack(alignment: .leading) {
                Section(header: headerrsync) {
                    HStack {
                        ToggleViewDefault(NSLocalizedString("Rsync v3.x", comment: ""),
                                          $usersettings.rsyncversion3)
                            .onChange(of: usersettings.rsyncversion3) {
                                SharedReference.shared.rsyncversion3 = usersettings.rsyncversion3
                                Task {
                                    await rsyncversion.getrsyncversion()
                                }
                                defaultpathrsync = SetandValidatepathforrsync().getpathforrsync()
                            }

                        ToggleViewDefault(NSLocalizedString("Apple Silicon", comment: ""),
                                          $usersettings.macosarm)
                            .onChange(of: usersettings.macosarm) {
                                SharedReference.shared.macosarm = usersettings.macosarm
                            }
                            .disabled(true)
                    }
                }

                if usersettings.localrsyncpath.isEmpty == true {
                    setrsyncpathdefault
                } else {
                    setrsyncpathlocalpath
                }

                Section(header: headerpathforrestore) {
                    setpathforrestore
                }

                setmarkdays
            }

            // Column 2
            VStack(alignment: .leading) {
                HStack {
                    VStack(alignment: .leading) {
                        Section(header: headerloggingtofile) {
                            ToggleViewDefault(NSLocalizedString("None", comment: ""),
                                              $usersettings.nologging)
                                .onChange(of: usersettings.nologging) {
                                    if usersettings.nologging == true {
                                        usersettings.minimumlogging = false
                                        usersettings.fulllogging = false
                                    } else {
                                        usersettings.minimumlogging = true
                                        usersettings.fulllogging = false
                                    }
                                    SharedReference.shared.fulllogging = usersettings.fulllogging
                                    SharedReference.shared.minimumlogging = usersettings.minimumlogging
                                    SharedReference.shared.nologging = usersettings.nologging
                                }

                            ToggleViewDefault(NSLocalizedString("Min", comment: ""),
                                              $usersettings.minimumlogging)
                                .onChange(of: usersettings.minimumlogging) {
                                    if usersettings.minimumlogging == true {
                                        usersettings.nologging = false
                                        usersettings.fulllogging = false
                                    }
                                    SharedReference.shared.fulllogging = usersettings.fulllogging
                                    SharedReference.shared.minimumlogging = usersettings.minimumlogging
                                    SharedReference.shared.nologging = usersettings.nologging
                                }

                            ToggleViewDefault(NSLocalizedString("Full", comment: ""),
                                              $usersettings.fulllogging)
                                .onChange(of: usersettings.fulllogging) {
                                    if usersettings.fulllogging == true {
                                        usersettings.nologging = false
                                        usersettings.minimumlogging = false
                                    }
                                    SharedReference.shared.fulllogging = usersettings.fulllogging
                                    SharedReference.shared.minimumlogging = usersettings.minimumlogging
                                    SharedReference.shared.nologging = usersettings.nologging
                                }
                        }
                    }

                    VStack(alignment: .leading) {
                        Section(header: othersettings) {
                            ToggleViewDefault(NSLocalizedString("Detailed log level", comment: ""), $usersettings.detailedlogging)
                                .onChange(of: usersettings.detailedlogging) {
                                    SharedReference.shared.detailedlogging = usersettings.detailedlogging
                                }

                            ToggleViewDefault(NSLocalizedString("Monitor network", comment: ""), $usersettings.monitornetworkconnection)
                                .onChange(of: usersettings.monitornetworkconnection) {
                                    SharedReference.shared.monitornetworkconnection = usersettings.monitornetworkconnection
                                }
                            ToggleViewDefault(NSLocalizedString("Check for error in output", comment: ""), $usersettings.checkforerrorinrsyncoutput)
                                .onChange(of: usersettings.checkforerrorinrsyncoutput) {
                                    SharedReference.shared.checkforerrorinrsyncoutput = usersettings.checkforerrorinrsyncoutput
                                }

                            ToggleViewDefault(NSLocalizedString("Confirm execute", comment: ""), $usersettings.confirmexecute)
                                .onChange(of: usersettings.confirmexecute) {
                                    SharedReference.shared.confirmexecute = usersettings.confirmexecute
                                }
                        }
                    }
                }
            }
        }
        .lineSpacing(2)
        .alert(isPresented: $usersettings.alerterror,
               content: { Alert(localizedError: usersettings.error)
               })
        .toolbar {
            ToolbarItem {
                Button {
                    _ = Backupconfigfiles()
                } label: {
                    Image(systemName: "wrench.adjustable.fill")
                        .foregroundColor(Color(.blue))
                        .imageScale(.large)
                }
                .help("Backup configurations")
            }

            ToolbarItem {
                if SharedReference.shared.settingsischanged && usersettings.ready { thumbsupgreen }
            }
        }
        .onAppear(perform: {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                Logger.process.info("Usersettings is DEFAULT")
                SharedReference.shared.settingsischanged = false
                usersettings.ready = true
            }
        })
        .onChange(of: SharedReference.shared.settingsischanged) {
            guard SharedReference.shared.settingsischanged == true,
                  usersettings.ready == true else { return }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                // _ = WriteUserConfigurationJSON(UserConfiguration())
                SharedReference.shared.settingsischanged = false
                let userconfig = UserConfiguration()
                if userconfiguration.count == 0 {
                    modelContext.insert(userconfig)
                } else {
                    do {
                        try modelContext.delete(model: UserConfiguration.self)
                        modelContext.insert(userconfig)
                    } catch {
                        fatalError(error.localizedDescription)
                    }
                }
                Logger.process.info("Usersettings is SAVED")
            }
        }
    }

    var thumbsupgreen: some View {
        Label("", systemImage: "hand.thumbsup")
            .foregroundColor(Color(.green))
            .padding()
    }

    // Rsync
    var headerrsync: some View {
        Text("Rsync version and path")
    }

    var setrsyncpathlocalpath: some View {
        EditValue(250, nil, $usersettings.localrsyncpath)
            .onAppear(perform: {
                usersettings.localrsyncpath = SetandValidatepathforrsync().getpathforrsync()
            })
    }

    var setrsyncpathdefault: some View {
        EditValue(250, defaultpathrsync, $usersettings.localrsyncpath)
            .onChange(of: usersettings.localrsyncpath) {
                usersettings.setandvalidatepathforrsync(usersettings.localrsyncpath)
            }
    }

    // Restore path
    var headerpathforrestore: some View {
        Text("Path for restore")
    }

    var setpathforrestore: some View {
        EditValue(250, NSLocalizedString("Path for restore", comment: ""),
                  $usersettings.temporarypathforrestore)
            .onAppear(perform: {
                if let pathforrestore = SharedReference.shared.pathforrestore {
                    usersettings.temporarypathforrestore = pathforrestore
                }
            })
            .onChange(of: usersettings.temporarypathforrestore) {
                usersettings.setandvalidapathforrestore(usersettings.temporarypathforrestore)
            }
    }

    // Logging
    var headerloggingtofile: some View {
        Text("Log to file")
    }

    // Detail of logging
    var othersettings: some View {
        Text("Other settings")
    }

    // Header user setting
    var headerusersetting: some View {
        Text("Save settings")
    }

    var setmarkdays: some View {
        HStack {
            Text("Mark days :")

            TextField("",
                      text: $usersettings.marknumberofdayssince)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .frame(width: 45)
                .lineLimit(1)
                .onChange(of: usersettings.marknumberofdayssince) {
                    usersettings.markdays(days: usersettings.marknumberofdayssince)
                }
        }
    }
}

// swiftlint:enable line_length
