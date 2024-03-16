//
//  ObservableAddConfigurations.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 03/06/2021.
//

import Foundation
import Observation

enum CannotUpdateSnaphotsError: LocalizedError {
    case cannotupdate

    var errorDescription: String? {
        switch self {
        case .cannotupdate:
            return "Only synchronize ID can be changed on a Snapshot task"
        }
    }
}

@Observable
final class ObservableAddConfigurations {
    var profile: String = ""
    var localcatalog: String = ""
    var remotecatalog: String = ""
    var donotaddtrailingslash: Bool = false
    var remoteuser: String = ""
    var remoteserver: String = ""
    var backupID: String = ""
    var selectedrsynccommand = TypeofTask.synchronize
    var selectedprofile: String?
    var deletedefaultprofile: Bool = false

    var deleted: Bool = false
    var created: Bool = false

    var confirmdeleteselectedprofile: Bool = false
    var showAlertfordelete: Bool = false

    var assistlocalcatalog: String = ""

    // alert about error
    var error: Error = Validatedpath.noerror
    var alerterror: Bool = false

    // Set true if remote storage is a local attached Volume
    var remotestorageislocal: Bool = false
    var configuration: SynchronizeConfiguration?
    var localhome: String {
        return NamesandPaths().userHomeDirectoryPath ?? ""
    }

    var copyandpasteconfigurations: [SynchronizeConfiguration]?

    func addconfig() -> SynchronizeConfiguration? {
        let getdata = AppendTask(profile,
                                 selectedrsynccommand.rawValue,
                                 localcatalog,
                                 remotecatalog,
                                 donotaddtrailingslash,
                                 remoteuser,
                                 remoteserver,
                                 backupID)
        if let newconfig = VerifyConfiguration().verify(getdata) {
            reset()
            return newconfig
        } else {
            return nil
        }
    }

    func reset() {
        localcatalog = ""
        remotecatalog = ""
        donotaddtrailingslash = false
        remoteuser = ""
        remoteserver = ""
        backupID = ""
        configuration = nil
        profile = ""
    }

    func updateview(_ config: SynchronizeConfiguration?) {
        configuration = config
        if let config = configuration {
            localcatalog = config.localCatalog
            remotecatalog = config.offsiteCatalog
            remoteuser = config.offsiteUsername
            remoteserver = config.offsiteServer
            backupID = config.backupID
            profile = config.profile
        } else {
            configuration = nil
            localcatalog = ""
            remotecatalog = ""
            remoteuser = ""
            remoteserver = ""
            backupID = ""
            profile = ""
        }
    }

    private func validatenotsnapshottask() throws -> Bool {
        if let config = configuration {
            if config.task == SharedReference.shared.snapshot {
                throw CannotUpdateSnaphotsError.cannotupdate
            } else {
                return true
            }
        }
        return false
    }

    func verifyremotestorageislocal() -> Bool {
        do {
            _ = try Folder(path: remotecatalog)
            return true
        } catch {
            return false
        }
    }

    func assistfunclocalcatalog(_ localcatalog: String) {
        guard localcatalog.isEmpty == false else { return }
        if let mounted = attachedVolumes() {
            let urlcomponent = mounted[0]
            remotecatalog = urlcomponent.path() + localcatalog
        } else {
            remotecatalog = "/mounted_Volume/" + localcatalog
        }
        self.localcatalog = localhome + "/" + localcatalog
        backupID = "Backup of: " + localcatalog
    }

    func assistfuncremoteuser(_ remoteuser: String) {
        guard remoteuser.isEmpty == false else { return }
        self.remoteuser = remoteuser
    }

    func assistfuncremoteserver(_ remoteserver: String) {
        guard remoteserver.isEmpty == false else { return }
        self.remoteserver = remoteserver
    }

    // Prepare for Copy and Paste tasks
    func preparecopyandpastetasks(_: [CopyItem], _ maxhiddenID: Int, _ selectedcopy: SynchronizeConfiguration?) {
        if let selectedcopy = selectedcopy {
            copyandpasteconfigurations = nil
            copyandpasteconfigurations = [SynchronizeConfiguration]()
            let copy = SynchronizeConfiguration()
            copy.profile = selectedcopy.profile
            copy.backupID = "COPY " + selectedcopy.backupID
            copy.dateRun = nil
            copy.hiddenID = maxhiddenID + 1
            copy.task = selectedcopy.task
            copy.localCatalog = selectedcopy.localCatalog
            copy.offsiteCatalog = selectedcopy.offsiteCatalog
            copy.parameter1 = selectedcopy.parameter1
            copy.parameter2 = selectedcopy.parameter2
            copy.parameter3 = selectedcopy.parameter3
            copy.parameter4 = selectedcopy.parameter4
            copy.parameter5 = selectedcopy.parameter5
            copy.parameter6 = selectedcopy.parameter6
            copyandpasteconfigurations?.append(copy)
        }
    }

    func attachedVolumes() -> [URL]? {
        let keys: [URLResourceKey] = [.volumeNameKey, .volumeIsRemovableKey, .volumeIsEjectableKey]
        let paths = FileManager().mountedVolumeURLs(includingResourceValuesForKeys: keys, options: [])
        var volumesarray = [URL]()
        if let urls = paths {
            for url in urls {
                let components = url.pathComponents
                if components.count > 1, components[1] == "Volumes" {
                    volumesarray.append(url)
                }
            }
        }
        if volumesarray.count > 0 {
            return volumesarray
        } else {
            return nil
        }
    }
}

// Compute max hiddenID as part of copy and paste function..
struct MaxhiddenID {
    func computemaxhiddenID(_ configurations: [SynchronizeConfiguration]) -> Int {
        // Reading Configurations from memory
        var setofhiddenIDs = Set<Int>()
        // Fill set with existing hiddenIDS
        for i in 0 ..< configurations.count {
            setofhiddenIDs.insert(configurations[i].hiddenID)
        }
        if setofhiddenIDs.count == 0 {
            return 1
        } else {
            if let max = setofhiddenIDs.max() {
                return max + 1
            }
            return 1
        }
    }
}
