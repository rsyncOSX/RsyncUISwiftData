//
//  UserConfiguration.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 06/02/2024.
//
// swiftlint:disable line_length

import Foundation
import SwiftData

@Model
final class UserConfiguration {
    var rsyncversion3: Int = -1
    // Detailed logging
    var detailedlogging: Int = 1
    // Logging to logfile
    var minimumlogging: Int = -1
    var fulllogging: Int = -1
    var nologging: Int = 1
    // Montor network connection
    var monitornetworkconnection: Int = -1
    // local path for rsync
    var localrsyncpath: String?
    // temporary path for restore
    var pathforrestore: String?
    // days for mark days since last synchronize
    var marknumberofdayssince: String = "5"
    // Global ssh keypath and port
    var sshkeypathandidentityfile: String?
    var sshport: Int?
    // Environment variable
    var environment: String?
    var environmentvalue: String?
    // Check for error in output from rsync
    var checkforerrorinrsyncoutput: Int = -1
    // Automatic execution
    var confirmexecute: Int?

    init(rsyncversion3: Int, detailedlogging: Int, minimumlogging: Int, fulllogging: Int, nologging: Int, monitornetworkconnection: Int, localrsyncpath: String? = nil, pathforrestore: String? = nil, marknumberofdayssince: String, sshkeypathandidentityfile: String? = nil, sshport: Int? = nil, environment: String? = nil, environmentvalue: String? = nil, checkforerrorinrsyncoutput: Int, confirmexecute: Int? = nil) {
        self.rsyncversion3 = rsyncversion3
        self.detailedlogging = detailedlogging
        self.minimumlogging = minimumlogging
        self.fulllogging = fulllogging
        self.nologging = nologging
        self.monitornetworkconnection = monitornetworkconnection
        self.localrsyncpath = localrsyncpath
        self.pathforrestore = pathforrestore
        self.marknumberofdayssince = marknumberofdayssince
        self.sshkeypathandidentityfile = sshkeypathandidentityfile
        self.sshport = sshport
        self.environment = environment
        self.environmentvalue = environmentvalue
        self.checkforerrorinrsyncoutput = checkforerrorinrsyncoutput
        self.confirmexecute = confirmexecute
    }

    // Default values user configuration
    @discardableResult
    init() {
        if SharedReference.shared.rsyncversion3 {
            rsyncversion3 = 1
        } else {
            rsyncversion3 = -1
        }
        if SharedReference.shared.detailedlogging {
            detailedlogging = 1
        } else {
            detailedlogging = -1
        }
        if SharedReference.shared.minimumlogging {
            minimumlogging = 1
        } else {
            minimumlogging = -1
        }
        if SharedReference.shared.fulllogging {
            fulllogging = 1
        } else {
            fulllogging = -1
        }
        if SharedReference.shared.nologging {
            nologging = 1
        } else {
            nologging = -1
        }
        if SharedReference.shared.monitornetworkconnection {
            monitornetworkconnection = 1
        } else {
            monitornetworkconnection = -1
        }
        if SharedReference.shared.localrsyncpath != nil {
            localrsyncpath = SharedReference.shared.localrsyncpath
        } else {
            localrsyncpath = nil
        }
        if SharedReference.shared.pathforrestore != nil {
            pathforrestore = SharedReference.shared.pathforrestore
        } else {
            pathforrestore = nil
        }
        marknumberofdayssince = String(SharedReference.shared.marknumberofdayssince)
        if SharedReference.shared.sshkeypathandidentityfile != nil {
            sshkeypathandidentityfile = SharedReference.shared.sshkeypathandidentityfile
        }
        if SharedReference.shared.sshport != nil {
            sshport = SharedReference.shared.sshport
        }
        if SharedReference.shared.environment != nil {
            environment = SharedReference.shared.environment
        }
        if SharedReference.shared.environmentvalue != nil {
            environmentvalue = SharedReference.shared.environmentvalue
        }
        if SharedReference.shared.checkforerrorinrsyncoutput == true {
            checkforerrorinrsyncoutput = 1
        } else {
            checkforerrorinrsyncoutput = -1
        }
        if SharedReference.shared.confirmexecute == true {
            confirmexecute = 1
        } else {
            confirmexecute = -1
        }
    }
}

// swiftlint:enable line_length
