//
//  ShowSSHCopyKeysView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 24/01/2024.
//

import SwiftData
import SwiftUI

struct ShowSSHCopyKeysView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var userconfiguration: [UserConfiguration]
    @Query private var configurations: [SynchronizeConfiguration]

    @State private var selectedlogin: UniqueserversandLogins?

    var body: some View {
        HStack {
            List(selection: $selectedlogin) {
                ForEach(getuniqueserversandlogins ?? []) { record in
                    ServerRow(record: record)
                        .tag(record)
                }
            }
            .frame(width: 250, height: 100)

            if selectedlogin == nil {
                defaultstrings
            } else {
                strings
            }
        }
    }

    // Copy strings
    var strings: some View {
        VStack(alignment: .leading) {
            Text("Test SSH connection:\n" + SshKeys().verifyremotekey(remote: selectedlogin))
            Text("Copy public SSH key:\n" + SshKeys().copylocalpubrsakeyfile(remote: selectedlogin))
        }
        .textSelection(.enabled)
        .frame(width: 400, height: 200)
    }

    // Default strings

    var defaultstrings: some View {
        VStack(alignment: .leading) {
            Text("Test SSH connection: \n select a login and server")
            Text("Copy public SSH key:")
        }
        .frame(width: 400, height: 100)
    }

    var getuniqueserversandlogins: [UniqueserversandLogins]? {
        let configs = configurations.filter {
            SharedReference.shared.synctasks.contains($0.task)
        }
        guard configurations.count > 0 else { return nil }
        var uniqueserversandlogins = [UniqueserversandLogins]()
        for i in 0 ..< configurations.count {
            if configurations[i].offsiteUsername.isEmpty == false, configurations[i].offsiteServer.isEmpty == false {
                let record = UniqueserversandLogins(configurations[i].offsiteUsername, configurations[i].offsiteServer)
                if uniqueserversandlogins.filter({ ($0.offsiteUsername == record.offsiteUsername) &&
                        ($0.offsiteServer == record.offsiteServer)
                }).count == 0 {
                    uniqueserversandlogins.append(record)
                }
            }
        }
        return uniqueserversandlogins
    }
}

struct ServerRow: View {
    var record: UniqueserversandLogins

    var body: some View {
        HStack {
            Text(record.offsiteUsername ?? "")
                .modifier(FixedTag(80, .leading))
            Text(record.offsiteServer ?? "")
                .modifier(FixedTag(80, .leading))
        }
    }
}

struct UniqueserversandLogins: Hashable, Identifiable {
    var id = UUID()
    var offsiteUsername: String?
    var offsiteServer: String?

    init(_ username: String,
         _ servername: String)
    {
        offsiteServer = servername
        offsiteUsername = username
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(offsiteUsername)
        hasher.combine(offsiteServer)
    }
}
