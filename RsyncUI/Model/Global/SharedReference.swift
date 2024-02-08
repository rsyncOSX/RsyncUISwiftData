//
//  SharedReference.swift
//  RsyncOSX
//
//  Created by Thomas Evensen on 05.09.2017.
//  Copyright © 2017 Thomas Evensen. All rights reserved.
//

import Foundation
import Observation

@Observable
class SharedReference {
    // Creates a singelton of this class
    class var shared: SharedReference {
        struct Singleton {
            static let instance = SharedReference()
        }
        return Singleton.instance
    }

    var settingsischanged: Bool = false

    @ObservationIgnored var rsyncversion3: Bool = false {
        didSet {
            settingsischanged = true
        }
    }

    // Optional path to rsync
    @ObservationIgnored var localrsyncpath: String? {
        didSet {
            settingsischanged = true
        }
    }

    // No valid rsyncPath - true if no valid rsync is found
    @ObservationIgnored var norsync: Bool = false
    // Path for restore
    @ObservationIgnored var pathforrestore: String? {
        didSet {
            settingsischanged = true
        }
    }

    // Detailed logging
    @ObservationIgnored var detailedlogging: Bool = true {
        didSet {
            settingsischanged = true
        }
    }

    // Logging to logfile
    @ObservationIgnored var minimumlogging: Bool = false {
        didSet {
            settingsischanged = true
        }
    }

    @ObservationIgnored var fulllogging: Bool = false {
        didSet {
            settingsischanged = true
        }
    }

    @ObservationIgnored var nologging: Bool = true {
        didSet {
            settingsischanged = true
        }
    }

    // Mark number of days since last backup
    @ObservationIgnored var marknumberofdayssince: Int = 5 {
        didSet {
            settingsischanged = true
        }
    }

    @ObservationIgnored var environment: String? {
        didSet {
            settingsischanged = true
        }
    }

    @ObservationIgnored var environmentvalue: String? {
        didSet {
            settingsischanged = true
        }
    }

    // Global SSH parameters
    @ObservationIgnored var sshport: Int? {
        didSet {
            settingsischanged = true
        }
    }

    @ObservationIgnored var sshkeypathandidentityfile: String? {
        didSet {
            settingsischanged = true
        }
    }

    // Check for error in output from rsync
    @ObservationIgnored var checkforerrorinrsyncoutput: Bool = false {
        didSet {
            settingsischanged = true
        }
    }

    // Check for network changes
    @ObservationIgnored var monitornetworkconnection: Bool = false {
        didSet {
            settingsischanged = true
        }
    }

    // Confirm execution
    // A safety rule
    @ObservationIgnored var confirmexecute: Bool = false {
        didSet {
            settingsischanged = true
        }
    }

    // Download URL if new version is avaliable
    @ObservationIgnored var URLnewVersion: String?
    // rsync command
    let rsync: String = "rsync"
    let usrbin: String = "/usr/bin"
    let usrlocalbin: String = "/usr/local/bin"
    let usrlocalbinarm: String = "/opt/homebrew/bin"
    @ObservationIgnored var macosarm: Bool = false
    // RsyncUI config files and path
    let logname: String = "rsyncui.txt"
    // String tasks
    let synchronize: String = "synchronize"
    let snapshot: String = "snapshot"
    let syncremote: String = "syncremote"
    @ObservationIgnored var synctasks: Set<String>
    // rsync version string
    @ObservationIgnored var rsyncversionstring: String?
    // rsync short version
    @ObservationIgnored var rsyncversionshort: String?
    // filsize logfile warning
    let logfilesize: Int = 100_000
    // Mac serialnumer
    @ObservationIgnored var macserialnumber: String?
    // Reference to the active process
    @ObservationIgnored var process: Process?
    // Object for propogate errors to views
    @ObservationIgnored var errorobject: AlertError?
    // Used when starting up RsyncUI
    // Default profile
    let defaultprofile = "Default profile"
    // If firstime use
    @ObservationIgnored var firsttime = false

    private init() {
        synctasks = Set<String>()
        synctasks = [synchronize, snapshot, syncremote]
    }
}
