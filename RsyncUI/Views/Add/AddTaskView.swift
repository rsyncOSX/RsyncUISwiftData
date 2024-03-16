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
    case homecatalogs
    var id: String { rawValue }
}

struct AddTasks: Hashable, Identifiable {
    let id = UUID()
    var task: AddTaskDestinationView
}

struct AddTaskView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var configurations: [SynchronizeConfiguration]

    @State private var newdata = ObservableAddConfigurations()
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
                                if newdata.configuration == nil { setProfile } else {
                                    EditValue(300, nil, $newdata.profile)
                                        .focused($focusField, equals: .profile)
                                        .textContentType(.none)
                                        .submitLabel(.continue)
                                        .onAppear(perform: {
                                            if let profile = newdata.configuration?.profile {
                                                newdata.profile = profile
                                            }
                                        })
                                        .onChange(of: newdata.profile) {
                                            newdata.configuration?.profile = newdata.profile
                                        }
                                }
                            }

                            if newdata.selectedrsynccommand == .syncremote {
                                VStack(alignment: .leading) { localandremotecatalogsyncremote }

                            } else {
                                VStack(alignment: .leading) { localandremotecatalog }
                            }

                            VStack(alignment: .leading) {
                                ToggleViewDefault(NSLocalizedString("Don´t add /", comment: ""),
                                                  $newdata.donotaddtrailingslash)
                            }

                            VStack(alignment: .leading) { synchronizeid }

                            VStack(alignment: .leading) { remoteuserandserver }

                            Spacer()
                        }

                        // Column 2

                        VStack(alignment: .leading) {
                            ListofTasksAddView(selecteduuids: $selecteduuids)
                                .onChange(of: selecteduuids) {
                                    if let index = configurations.firstIndex(where: { $0.id == selecteduuids.first }) {
                                        selectedconfig = configurations[index]
                                        newdata.updateview(configurations[index])
                                    } else {
                                        selectedconfig = nil
                                        newdata.updateview(nil)
                                    }
                                }
                                .copyable(copyitems.filter { selecteduuids.contains($0.id) })
                                .pasteDestination(for: CopyItem.self) { items in
                                    let maxhiddenID = MaxhiddenID().computemaxhiddenID(configurations)
                                    newdata.preparecopyandpastetasks(items,
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
                                        for i in 0 ..< (newdata.copyandpasteconfigurations?.count ?? 0) {
                                            if let copyitem = newdata.copyandpasteconfigurations?[i] {
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
                    if newdata.configuration == nil {
                        addconfig()
                    }
                    focusField = nil
                case .backupIDField:
                    if newdata.remotestorageislocal == true,
                       newdata.configuration == nil
                    {
                        addconfig()
                    } else {
                        focusField = .remoteuserField
                    }
                default:
                    return
                }
            }
            .alert(isPresented: $newdata.alerterror,
                   content: { Alert(localizedError: newdata.error)
                   })

            .navigationDestination(for: AddTasks.self) { which in
                makeView(view: which.task)
            }
            .toolbar {
                ToolbarItem {
                    Button {
                        addconfig()
                    } label: {
                        Image(systemName: "return")
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
            }
        }
    }

    @MainActor @ViewBuilder
    func makeView(view: AddTaskDestinationView) -> some View {
        switch view {
        case .homecatalogs:
            HomeCatalogsView(newdata: newdata,
                             path: $path,
                             homecatalogs: {
                                 if let atpath = NamesandPaths(nil).userHomeDirectoryPath {
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
                             }(),

                             attachedVolumes: {
                                 let keys: [URLResourceKey] = [.volumeNameKey,
                                                               .volumeIsRemovableKey,
                                                               .volumeIsEjectableKey]
                                 let paths = FileManager()
                                     .mountedVolumeURLs(includingResourceValuesForKeys: keys,
                                                        options: [])
                                 var volumesarray = [AttachedVolumes]()
                                 if let urls = paths {
                                     for url in urls {
                                         let components = url.pathComponents
                                         if components.count > 1, components[1] == "Volumes" {
                                             volumesarray.append(AttachedVolumes(url))
                                         }
                                     }
                                 }
                                 if volumesarray.count > 0 {
                                     return volumesarray
                                 } else {
                                     return []
                                 }
                             }())
                .onChange(of: newdata.assistlocalcatalog) {
                    newdata.assistfunclocalcatalog(newdata.assistlocalcatalog)
                }
        }
    }

    // Add and edit text values
    var setlocalcatalogsyncremote: some View {
        EditValue(300, NSLocalizedString("Add remote as local catalog - required", comment: ""),
                  $newdata.localcatalog)
    }

    var setremotecatalogsyncremote: some View {
        EditValue(300, NSLocalizedString("Add local as remote catalog - required", comment: ""),
                  $newdata.remotecatalog)
    }

    var setlocalcatalog: some View {
        EditValue(300, NSLocalizedString("Add local catalog - required", comment: ""),
                  $newdata.localcatalog)
            .focused($focusField, equals: .localcatalogField)
            .textContentType(.none)
            .submitLabel(.continue)
    }

    var setremotecatalog: some View {
        EditValue(300, NSLocalizedString("Add remote catalog - required", comment: ""),
                  $newdata.remotecatalog)
            .focused($focusField, equals: .remotecatalogField)
            .textContentType(.none)
            .submitLabel(.continue)
    }

    var profile: some View {
        Text("Profile")
            .modifier(FixedTag(200, .leading))
    }

    var setProfile: some View {
        EditValue(300, NSLocalizedString(SharedReference.shared.defaultprofile, comment: ""),
                  $newdata.profile)
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
                if newdata.configuration == nil { setlocalcatalog } else {
                    EditValue(300, nil, $newdata.localcatalog)
                        .focused($focusField, equals: .localcatalogField)
                        .textContentType(.none)
                        .submitLabel(.continue)
                        .onAppear(perform: {
                            if let catalog = newdata.configuration?.localCatalog {
                                newdata.localcatalog = catalog
                            }
                        })
                        .onChange(of: newdata.localcatalog) {
                            newdata.configuration?.localCatalog = newdata.localcatalog
                        }
                }
                OpencatalogView(catalog: $newdata.localcatalog, choosecatalog: choosecatalog)
            }
            HStack {
                // remotecatalog
                if newdata.configuration == nil { setremotecatalog } else {
                    EditValue(300, nil, $newdata.remotecatalog)
                        .focused($focusField, equals: .remotecatalogField)
                        .textContentType(.none)
                        .submitLabel(.continue)
                        .onAppear(perform: {
                            if let catalog = newdata.configuration?.offsiteCatalog {
                                newdata.remotecatalog = catalog
                            }
                        })
                        .onChange(of: newdata.remotecatalog) {
                            newdata.configuration?.offsiteCatalog = newdata.remotecatalog
                        }
                }
                OpencatalogView(catalog: $newdata.remotecatalog, choosecatalog: choosecatalog)
            }
        }
    }

    var localandremotecatalogsyncremote: some View {
        Section(header: headerlocalremote) {
            HStack {
                // localcatalog
                if newdata.configuration == nil { setlocalcatalogsyncremote } else {
                    EditValue(300, nil, $newdata.localcatalog)
                        .onAppear(perform: {
                            if let catalog = newdata.configuration?.localCatalog {
                                newdata.localcatalog = catalog
                            }
                        })
                }
                OpencatalogView(catalog: $newdata.localcatalog, choosecatalog: choosecatalog)
            }
            HStack {
                // remotecatalog
                if newdata.configuration == nil { setremotecatalogsyncremote } else {
                    EditValue(300, nil, $newdata.remotecatalog)
                        .onAppear(perform: {
                            if let catalog = newdata.configuration?.offsiteCatalog {
                                newdata.remotecatalog = catalog
                            }
                        })
                }
                OpencatalogView(catalog: $newdata.remotecatalog, choosecatalog: choosecatalog)
            }
        }
    }

    var setID: some View {
        EditValue(300, NSLocalizedString("Add synchronize ID", comment: ""),
                  $newdata.backupID)
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
            if newdata.configuration == nil { setID } else {
                EditValue(300, nil, $newdata.backupID)
                    .focused($focusField, equals: .backupIDField)
                    .textContentType(.none)
                    .submitLabel(.continue)
                    .onAppear(perform: {
                        if let id = newdata.configuration?.backupID {
                            newdata.backupID = id
                        }
                    })
                    .onChange(of: newdata.backupID) {
                        newdata.configuration?.backupID = newdata.backupID
                    }
            }
        }
    }

    var setremoteuser: some View {
        EditValue(300, NSLocalizedString("Add remote user", comment: ""),
                  $newdata.remoteuser)
            .focused($focusField, equals: .remoteuserField)
            .textContentType(.none)
            .submitLabel(.continue)
    }

    var setremoteserver: some View {
        EditValue(300, NSLocalizedString("Add remote server", comment: ""),
                  $newdata.remoteserver)
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
            if newdata.configuration == nil { setremoteuser } else {
                EditValue(300, nil, $newdata.remoteuser)
                    .focused($focusField, equals: .remoteuserField)
                    .textContentType(.none)
                    .submitLabel(.continue)
                    .onAppear(perform: {
                        if let user = newdata.configuration?.offsiteUsername {
                            newdata.remoteuser = user
                        }
                    })
                    .onChange(of: newdata.remoteuser) {
                        newdata.configuration?.offsiteUsername = newdata.remoteuser
                    }
            }
            // Remote server
            if newdata.configuration == nil { setremoteserver } else {
                EditValue(300, nil, $newdata.remoteserver)
                    .focused($focusField, equals: .remoteserverField)
                    .textContentType(.none)
                    .submitLabel(.return)
                    .onAppear(perform: {
                        if let server = newdata.configuration?.offsiteServer {
                            newdata.remoteserver = server
                        }
                    })
                    .onChange(of: newdata.remoteserver) {
                        newdata.configuration?.offsiteServer = newdata.remoteserver
                    }
            }
        }
    }

    var selectpickervalue: TypeofTask {
        switch newdata.configuration?.task {
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
               selection: $newdata.selectedrsynccommand)
        {
            ForEach(TypeofTask.allCases) { Text($0.description)
                .tag($0)
            }
            .onChange(of: newdata.configuration) {
                newdata.selectedrsynccommand = selectpickervalue
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
        if let newItem = newdata.addconfig() {
            newItem.hiddenID = MaxhiddenID().computemaxhiddenID(configurations)
            modelContext.insert(newItem)
        }
    }
}
