//
//  RsyncUIView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 17/06/2021.
//

import OSLog
import SwiftData
import SwiftUI

struct RsyncUIView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var userconfigurations: [UserConfiguration]

    @State private var rsyncversion = Rsyncversion()
    @State private var start: Bool = true
    @State var selecteduuids = Set<SynchronizeConfiguration.ID>()

    var body: some View {
        VStack {
            if start {
                VStack {
                    Text("RsyncUI a GUI for rsync")
                        .font(.largeTitle)
                    Text("https://rsyncui.netlify.app")
                        .font(.title2)
                }
                .onAppear(perform: {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                        start = false
                    }
                })
            } else {
                Sidebar(selecteduuids: $selecteduuids,
                        errorhandling: errorhandling)
            }
        }
        .padding()
        .task {
            if userconfigurations.count > 0 {
                update(userconfigurations[0])
            }
            rsyncversion.getrsyncversion()
        }
    }

    var errorhandling: AlertError {
        SharedReference.shared.errorobject = AlertError()
        return SharedReference.shared.errorobject ?? AlertError()
    }

    func update(_ userconfiguration: UserConfiguration) {
        if userconfiguration.rsyncversion3 == 1 {
            SharedReference.shared.rsyncversion3 = true
        } else {
            SharedReference.shared.rsyncversion3 = false
        }
        if userconfiguration.detailedlogging == 1 {
            SharedReference.shared.detailedlogging = true
        } else {
            SharedReference.shared.detailedlogging = false
        }
        if userconfiguration.minimumlogging == 1 {
            SharedReference.shared.minimumlogging = true
        } else {
            SharedReference.shared.minimumlogging = false
        }
        if userconfiguration.fulllogging == 1 {
            SharedReference.shared.fulllogging = true
        } else {
            SharedReference.shared.fulllogging = false
        }
        if userconfiguration.nologging == 1 {
            SharedReference.shared.nologging = true
        } else {
            SharedReference.shared.nologging = false
        }
        if userconfiguration.monitornetworkconnection == 1 {
            SharedReference.shared.monitornetworkconnection = true
        } else {
            SharedReference.shared.monitornetworkconnection = false
        }
        if userconfiguration.localrsyncpath != nil {
            SharedReference.shared.localrsyncpath = userconfiguration.localrsyncpath
        } else {
            SharedReference.shared.localrsyncpath = nil
        }
        if userconfiguration.pathforrestore != nil {
            SharedReference.shared.pathforrestore = userconfiguration.pathforrestore
        } else {
            SharedReference.shared.pathforrestore = nil
        }
        if Int(userconfiguration.marknumberofdayssince) ?? 0 > 0 {
            SharedReference.shared.marknumberofdayssince = Int(userconfiguration.marknumberofdayssince) ?? 0
        }
        if userconfiguration.sshkeypathandidentityfile != nil {
            SharedReference.shared.sshkeypathandidentityfile = userconfiguration.sshkeypathandidentityfile
        }
        if userconfiguration.sshport != nil {
            SharedReference.shared.sshport = userconfiguration.sshport
        }
        if userconfiguration.environment != nil {
            SharedReference.shared.environment = userconfiguration.environment
        }
        if userconfiguration.environmentvalue != nil {
            SharedReference.shared.environmentvalue = userconfiguration.environmentvalue
        }
        if userconfiguration.checkforerrorinrsyncoutput == 1 {
            SharedReference.shared.checkforerrorinrsyncoutput = true
        } else {
            SharedReference.shared.checkforerrorinrsyncoutput = false
        }
        if userconfiguration.confirmexecute == 1 {
            SharedReference.shared.confirmexecute = true
        } else {
            SharedReference.shared.confirmexecute = false
        }
    }
}
