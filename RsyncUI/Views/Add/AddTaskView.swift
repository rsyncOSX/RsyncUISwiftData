//
//  AddTaskView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 11/12/2023.
//
// swiftlint:disable file_length type_body_length

import SwiftData
import SwiftUI

enum AddTaskDestinationView: String, Identifiable {
    case shelltaskview, homecatalogs
    var id: String { rawValue }
}

struct AddTasks: Hashable, Identifiable {
    let id = UUID()
    var task: AddTaskDestinationView
}

struct AddTaskView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var configurations: [SynchronizeConfiguration]

    @State private var parameters = ObservableAddConfigurations()
    @State private var selectedconfig: SynchronizeConfiguration?
    @State private var selecteduuids = Set<SynchronizeConfiguration.ID>()
    // Which view to show
    @State var path: [AddTasks] = []

    var choosecatalog = true

    enum AddConfigurationField: Hashable {
        case profile
        case localcatalogField
        case remotecatalogField
        case remoteuserField
        case remoteserverField
        case backupIDField
    }

    @FocusState private var focusField: AddConfigurationField?
    // Reload and show table data
    @State private var confirmcopyandpaste: Bool = false

    var body: some View {
        NavigationStack(path: $path) {
            Form {
                ZStack {
                    HStack {
                        // For center
                        Spacer()

                        // Column 1
                        VStack(alignment: .leading) {
                            pickerselecttypeoftask

                            Section(header: profile) {
                                if parameters.configuration == nil { setProfile } else {
                                    EditValue(300, nil, $parameters.profile)
                                        .focused($focusField, equals: .profile)
                                        .textContentType(.none)
                                        .submitLabel(.continue)
                                        .onAppear(perform: {
                                            if let profile = parameters.configuration?.profile {
                                                parameters.profile = profile
                                            }
                                        })
                                        .onChange(of: parameters.profile) {
                                            parameters.configuration?.profile = parameters.profile
                                        }
                                }
                            }

                            if parameters.selectedrsynccommand == .syncremote {
                                VStack(alignment: .leading) { localandremotecatalogsyncremote }

                            } else {
                                VStack(alignment: .leading) { localandremotecatalog }
                            }

                            VStack(alignment: .leading) {
                                ToggleViewDefault(NSLocalizedString("Don´t add /", comment: ""),
                                                  $parameters.donotaddtrailingslash)
                            }

                            VStack(alignment: .leading) { synchronizeid }

                            VStack(alignment: .leading) { remoteuserandserver }

                            Spacer()
                        }

                        // Column 2

                        VStack(alignment: .leading) {
                            ListofTasksAddView(selecteduuids: $selecteduuids)
                                .onChange(of: selecteduuids) {
                                    let selected = configurations.filter { config in
                                        selecteduuids.contains(config.id)
                                    }
                                    if (selected.count) == 1 {
                                        selectedconfig = selected[0]
                                        parameters.updateview(selectedconfig)
                                    } else {
                                        selectedconfig = nil
                                        parameters.updateview(selectedconfig)
                                    }
                                }
                                .copyable(copyitems.filter { selecteduuids.contains($0.id) })
                                .pasteDestination(for: CopyItem.self) { items in
                                    let maxhiddenID = MaxhiddenID().computemaxhiddenID(configurations)
                                    parameters.preparecopyandpastetasks(items,
                                                                        maxhiddenID,
                                                                        selectedconfig)
                                    guard items.count > 0 else { return }
                                    confirmcopyandpaste = true
                                } validator: { items in
                                    items.filter { $0.task == SharedReference.shared.synchronize }
                                }
                                .confirmationDialog(
                                    NSLocalizedString("Copy configuration", comment: "")
                                        + "?",
                                    isPresented: $confirmcopyandpaste
                                ) {
                                    Button("Copy") {
                                        confirmcopyandpaste = false
                                        for i in 0 ..< (parameters.copyandpasteconfigurations?.count ?? 0) {
                                            if let copyitem = parameters.copyandpasteconfigurations?[i] {
                                                modelContext.insert(copyitem)
                                            }
                                        }
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
                case .localcatalogField:
                    focusField = .remotecatalogField
                case .remotecatalogField:
                    focusField = .backupIDField
                case .remoteuserField:
                    focusField = .remoteserverField
                case .remoteserverField:
                    if parameters.configuration == nil {
                        addconfig()
                    }
                    focusField = nil
                case .backupIDField:
                    if parameters.remotestorageislocal == true,
                       parameters.configuration == nil
                    {
                        addconfig()
                    } else {
                        focusField = .remoteuserField
                    }
                default:
                    return
                }
            }
            .alert(isPresented: $parameters.alerterror,
                   content: { Alert(localizedError: parameters.error)
                   })

            .navigationDestination(for: AddTasks.self) { which in
                makeView(view: which.task)
            }
            .toolbar {
                ToolbarItem {
                    Button {
                        addconfig()
                    } label: {
                        Image(systemName: "plus.app.fill")
                            .foregroundColor(Color(.blue))
                    }
                    .help("Add task")
                }

                ToolbarItem {
                    Button {
                        path.append(AddTasks(task: .homecatalogs))
                    } label: {
                        Image(systemName: "house.fill")
                    }
                    .help("Home catalogs")
                }

                ToolbarItem {
                    Button {
                        path.append(AddTasks(task: .shelltaskview))
                    } label: {
                        Image(systemName: "fossil.shell.fill")
                    }
                    .help("Shell commands")
                }
            }
        }
    }

    @ViewBuilder
    func makeView(view: AddTaskDestinationView) -> some View {
        switch view {
        case .shelltaskview:
            AddPreandPostView()
        case .homecatalogs:
            HomeCatalogsView(catalog: $parameters.assistlocalcatalog,
                             path: $path,
                             homecatalogs: {
                                 if let atpath = NamesandPaths(.configurations).userHomeDirectoryPath {
                                     var catalogs = [Catalognames]()
                                     do {
                                         for folders in try Folder(path: atpath).subfolders {
                                             catalogs.append(Catalognames(folders.name))
                                         }
                                         return catalogs
                                     } catch {
                                         return []
                                     }
                                 }
                                 return []
                             }())
                .onChange(of: parameters.assistlocalcatalog) {
                    parameters.assistfunclocalcatalog(parameters.assistlocalcatalog)
                }
        }
    }

    // Add and edit text values
    var setlocalcatalogsyncremote: some View {
        EditValue(300, NSLocalizedString("Add remote as local catalog - required", comment: ""),
                  $parameters.localcatalog)
    }

    var setremotecatalogsyncremote: some View {
        EditValue(300, NSLocalizedString("Add local as remote catalog - required", comment: ""),
                  $parameters.remotecatalog)
            .onChange(of: parameters.remotecatalog) {
                parameters.remotestorageislocal = parameters.verifyremotestorageislocal()
            }
    }

    var setlocalcatalog: some View {
        EditValue(300, NSLocalizedString("Add local catalog - required", comment: ""),
                  $parameters.localcatalog)
            .focused($focusField, equals: .localcatalogField)
            .textContentType(.none)
            .submitLabel(.continue)
    }

    var setremotecatalog: some View {
        EditValue(300, NSLocalizedString("Add remote catalog - required", comment: ""),
                  $parameters.remotecatalog)
            .focused($focusField, equals: .remotecatalogField)
            .textContentType(.none)
            .submitLabel(.continue)
    }

    // Headers (in sections)

    // Headers (in sections)

    var profile: some View {
        Text("Profile")
            .modifier(FixedTag(200, .leading))
    }

    var setProfile: some View {
        EditValue(300, NSLocalizedString("Default profile", comment: ""),
                  $parameters.profile)
            .focused($focusField, equals: .profile)
            .textContentType(.none)
            .submitLabel(.continue)
    }

    var headerlocalremote: some View {
        Text("Catalog parameters")
            .modifier(FixedTag(200, .leading))
    }

    var localandremotecatalog: some View {
        Section(header: headerlocalremote) {
            HStack {
                // localcatalog
                if parameters.configuration == nil { setlocalcatalog } else {
                    EditValue(300, nil, $parameters.localcatalog)
                        .focused($focusField, equals: .localcatalogField)
                        .textContentType(.none)
                        .submitLabel(.continue)
                        .onAppear(perform: {
                            if let catalog = parameters.configuration?.localCatalog {
                                parameters.localcatalog = catalog
                            }
                        })
                }
                OpencatalogView(catalog: $parameters.localcatalog, choosecatalog: choosecatalog)
            }
            HStack {
                // remotecatalog
                if parameters.configuration == nil { setremotecatalog } else {
                    EditValue(300, nil, $parameters.remotecatalog)
                        .focused($focusField, equals: .remotecatalogField)
                        .textContentType(.none)
                        .submitLabel(.continue)
                        .onAppear(perform: {
                            if let catalog = parameters.configuration?.offsiteCatalog {
                                parameters.remotecatalog = catalog
                            }
                        })
                }
                OpencatalogView(catalog: $parameters.remotecatalog, choosecatalog: choosecatalog)
            }
        }
    }

    var localandremotecatalogsyncremote: some View {
        Section(header: headerlocalremote) {
            HStack {
                // localcatalog
                if parameters.configuration == nil { setlocalcatalogsyncremote } else {
                    EditValue(300, nil, $parameters.localcatalog)
                        .onAppear(perform: {
                            if let catalog = parameters.configuration?.localCatalog {
                                parameters.localcatalog = catalog
                            }
                        })
                }
                OpencatalogView(catalog: $parameters.localcatalog, choosecatalog: choosecatalog)
            }
            HStack {
                // remotecatalog
                if parameters.configuration == nil { setremotecatalogsyncremote } else {
                    EditValue(300, nil, $parameters.remotecatalog)
                        .onAppear(perform: {
                            if let catalog = parameters.configuration?.offsiteCatalog {
                                parameters.remotecatalog = catalog
                            }
                        })
                }
                OpencatalogView(catalog: $parameters.remotecatalog, choosecatalog: choosecatalog)
            }
        }
    }

    var setID: some View {
        EditValue(300, NSLocalizedString("Add synchronize ID", comment: ""),
                  $parameters.backupID)
            .focused($focusField, equals: .backupIDField)
            .textContentType(.none)
            .submitLabel(.continue)
    }

    var headerID: some View {
        Text("Synchronize ID")
            .modifier(FixedTag(200, .leading))
    }

    var synchronizeid: some View {
        Section(header: headerID) {
            // Synchronize ID
            if parameters.configuration == nil { setID } else {
                EditValue(300, nil, $parameters.backupID)
                    .focused($focusField, equals: .backupIDField)
                    .textContentType(.none)
                    .submitLabel(.continue)
                    .onAppear(perform: {
                        if let id = parameters.configuration?.backupID {
                            parameters.backupID = id
                        }
                    })
            }
        }
    }

    var setremoteuser: some View {
        EditValue(300, NSLocalizedString("Add remote user", comment: ""),
                  $parameters.remoteuser)
            .focused($focusField, equals: .remoteuserField)
            .textContentType(.none)
            .submitLabel(.continue)
    }

    var setremoteserver: some View {
        EditValue(300, NSLocalizedString("Add remote server", comment: ""),
                  $parameters.remoteserver)
            .focused($focusField, equals: .remoteserverField)
            .textContentType(.none)
            .submitLabel(.return)
    }

    var headerremote: some View {
        Text("Remote parameters")
            .modifier(FixedTag(200, .leading))
    }

    var remoteuserandserver: some View {
        Section(header: headerremote) {
            // Remote user
            if parameters.configuration == nil { setremoteuser } else {
                EditValue(300, nil, $parameters.remoteuser)
                    .focused($focusField, equals: .remoteuserField)
                    .textContentType(.none)
                    .submitLabel(.continue)
                    .onAppear(perform: {
                        if let user = parameters.configuration?.offsiteUsername {
                            parameters.remoteuser = user
                        }
                    })
            }
            // Remote server
            if parameters.configuration == nil { setremoteserver } else {
                EditValue(300, nil, $parameters.remoteserver)
                    .focused($focusField, equals: .remoteserverField)
                    .textContentType(.none)
                    .submitLabel(.return)
                    .onAppear(perform: {
                        if let server = parameters.configuration?.offsiteServer {
                            parameters.remoteserver = server
                        }
                    })
            }
        }
    }

    var selectpickervalue: TypeofTask {
        switch parameters.configuration?.task {
        case SharedReference.shared.synchronize:
            return .synchronize
        case SharedReference.shared.syncremote:
            return .syncremote
        case SharedReference.shared.snapshot:
            return .snapshot
        default:
            return .synchronize
        }
    }

    var pickerselecttypeoftask: some View {
        Picker(NSLocalizedString("Task", comment: "") + ":",
               selection: $parameters.selectedrsynccommand)
        {
            ForEach(TypeofTask.allCases) { Text($0.description)
                .tag($0)
            }
            .onChange(of: parameters.configuration) {
                parameters.selectedrsynccommand = selectpickervalue
            }
        }
        .pickerStyle(DefaultPickerStyle())
        .frame(width: 140)
    }

    var copyitems: [CopyItem] {
        var items = [CopyItem]()
        for i in 0 ..< (configurations.count) {
            let item = CopyItem(id: configurations[i].id,
                                hiddenID: configurations[i].hiddenID,
                                task: configurations[i].task)
            items.append(item)
        }
        return items
    }
}

extension AddTaskView {
    func addconfig() {
        if let newItem = parameters.addconfig() {
            newItem.hiddenID = MaxhiddenID().computemaxhiddenID(configurations)
            modelContext.insert(newItem)
        }
    }
}
