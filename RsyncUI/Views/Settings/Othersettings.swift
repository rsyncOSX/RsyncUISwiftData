//
//  Othersettings.swift
//  RsyncSwiftUI
//
//  Created by Thomas Evensen on 03/03/2021.
//

import OSLog
import SwiftData
import SwiftUI

struct Othersettings: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var userconfiguration: [UserConfiguration]

    @State private var environmentvalue: String = ""
    @State private var environment: String = ""
    // Settings are changed
    @State var settings: Bool = false

    var body: some View {
        VStack(alignment: .leading) {
            setenvironment

            setenvironmenvariable
        }
        .toolbar {
            ToolbarItem {
                if SharedReference.shared.settingsischanged { thumbsupgreen }
            }
        }
        .lineSpacing(2)
        .onAppear(perform: {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                Logger.process.info("Othersettings is DEFAULT")
                SharedReference.shared.settingsischanged = false
                settings = true
            }
        })
        .onChange(of: SharedReference.shared.settingsischanged) {
            guard SharedReference.shared.settingsischanged == true else { return }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
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
                Logger.process.info("Othersettings is SAVED")
            }
        }
    }

    var thumbsupgreen: some View {
        Label("", systemImage: "hand.thumbsup")
            .foregroundColor(Color(.green))
            .padding()
    }

    var setenvironment: some View {
        EditValue(350, NSLocalizedString("Environment", comment: ""), $environment)
            .onAppear(perform: {
                if let environmentstring = SharedReference.shared.environment {
                    environment = environmentstring
                }
            })
            .onChange(of: environment) {
                SharedReference.shared.environment = environment
            }
    }

    var setenvironmenvariable: some View {
        EditValue(350, NSLocalizedString("Environment variable", comment: ""), $environmentvalue)
            .onAppear(perform: {
                if let environmentvaluestring = SharedReference.shared.environmentvalue {
                    environmentvalue = environmentvaluestring
                }
            })
            .onChange(of: environmentvalue) {
                SharedReference.shared.environmentvalue = environmentvalue
            }
    }
}
