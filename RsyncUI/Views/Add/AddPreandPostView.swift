//
//  AddPreandPostView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 01/04/2021.
//
// swiftlint:disable line_length

import SwiftData
import SwiftUI

struct AddPreandPostView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var configurations: [SynchronizeConfiguration]

    @State private var parameters = ObservablePreandPostTask()
    @State private var selectedconfig: SynchronizeConfiguration?
    @State private var selecteduuids = Set<SynchronizeConfiguration.ID>()

    var choosecatalog = false

    enum PreandPostTaskField: Hashable {
        case pretaskField
        case posttaskField
    }

    @FocusState private var focusField: PreandPostTaskField?

    var body: some View {
        Form {
            ZStack {
                HStack {
                    // For center
                    Spacer()

                    // Column 1
                    VStack(alignment: .leading) {
                        pretaskandtoggle

                        posttaskandtoggle

                        HStack {
                            if parameters.configuration == nil { disablehaltshelltasksonerror } else {
                                ToggleViewDefault(NSLocalizedString("Halt on error", comment: ""), $parameters.haltshelltasksonerror)
                                    .onAppear(perform: {
                                        if parameters.configuration?.haltshelltasksonerror == 1 {
                                            parameters.haltshelltasksonerror = true
                                        } else {
                                            parameters.haltshelltasksonerror = false
                                        }
                                    })
                            }
                        }

                        Spacer()
                    }

                    // Column 2

                    VStack(alignment: .leading) {
                        ListofTasksLightView(selecteduuids: $selecteduuids)
                            .onChange(of: selecteduuids) {
                                if let index = configurations.firstIndex(where: { $0.id == selecteduuids.first }) {
                                    selectedconfig = configurations[index]
                                    parameters.updateview(configurations[index])
                                } else {
                                    selectedconfig = nil
                                    parameters.updateview(selectedconfig)
                                }
                            }
                    }
                }
            }
        }
        .lineSpacing(2)
        .padding()
        .onSubmit {
            switch focusField {
            case .pretaskField:
                focusField = .posttaskField
            case .posttaskField:
                parameters.enablepre = true
                parameters.enablepost = true
                parameters.haltshelltasksonerror = true
                focusField = nil
            default:
                return
            }
        }
        .alert(isPresented: $parameters.alerterror,
               content: { Alert(localizedError: parameters.error)
               })
    }

    var setpretask: some View {
        EditValue(250, NSLocalizedString("Add pretask", comment: ""), $parameters.pretask)
    }

    var setposttask: some View {
        EditValue(250, NSLocalizedString("Add posttask", comment: ""), $parameters.posttask)
    }

    var disablepretask: some View {
        ToggleViewDefault(NSLocalizedString("Enable", comment: ""), $parameters.enablepre)
    }

    var disableposttask: some View {
        ToggleViewDefault(NSLocalizedString("Enable", comment: ""), $parameters.enablepost)
    }

    var pretaskandtoggle: some View {
        VStack(alignment: .leading) {
            VStack(alignment: .leading) {
                // Enable pretask
                if parameters.configuration == nil { disablepretask } else {
                    ToggleViewDefault(NSLocalizedString("Enable", comment: ""), $parameters.enablepre)
                        .onAppear(perform: {
                            if parameters.configuration?.executepretask == 1 {
                                parameters.enablepre = true
                            } else {
                                parameters.enablepre = false
                            }
                        })
                }

                // Pretask

                HStack {
                    if parameters.configuration == nil { setpretask } else {
                        EditValue(250, nil, $parameters.pretask)
                            .focused($focusField, equals: .pretaskField)
                            .textContentType(.none)
                            .submitLabel(.continue)
                            .onAppear(perform: {
                                if let task = parameters.configuration?.pretask {
                                    parameters.pretask = task
                                }
                            })
                    }

                    OpencatalogView(catalog: $parameters.pretask, choosecatalog: choosecatalog)
                }
            }
        }
    }

    var posttaskandtoggle: some View {
        VStack(alignment: .leading) {
            VStack(alignment: .leading) {
                // Enable posttask
                if parameters.configuration == nil { disableposttask } else {
                    ToggleViewDefault(NSLocalizedString("Enable", comment: ""), $parameters.enablepost)
                        .onAppear(perform: {
                            if parameters.configuration?.executeposttask == 1 {
                                parameters.enablepost = true
                            } else {
                                parameters.enablepost = false
                            }
                        })
                }

                // Posttask

                HStack {
                    if parameters.configuration == nil { setposttask } else {
                        EditValue(250, nil, $parameters.posttask)
                            .focused($focusField, equals: .posttaskField)
                            .textContentType(.none)
                            .submitLabel(.continue)
                            .onAppear(perform: {
                                if let task = parameters.configuration?.posttask {
                                    parameters.posttask = task
                                }
                            })
                    }
                    OpencatalogView(catalog: $parameters.posttask, choosecatalog: choosecatalog)
                }
            }
        }
    }

    var disablehaltshelltasksonerror: some View {
        ToggleViewDefault(NSLocalizedString("Halt on error", comment: ""),
                          $parameters.haltshelltasksonerror)
    }
}

// swiftlint:enable line_length
