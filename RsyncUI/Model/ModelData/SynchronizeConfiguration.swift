//
//  SynchronizeConfiguration.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 06/02/2024.
//
// swiftlint:disable line_length

import Foundation
import SwiftData

enum NumDayofweek: Int {
    case Monday = 2
    case Tuesday = 3
    case Wednesday = 4
    case Thursday = 5
    case Friday = 6
    case Saturday = 7
    case Sunday = 1
}

enum StringDayofweek: String, CaseIterable, Identifiable, CustomStringConvertible {
    case Monday
    case Tuesday
    case Wednesday
    case Thursday
    case Friday
    case Saturday
    case Sunday

    var id: String { rawValue }
    var description: String { rawValue.localizedLowercase }
}

enum PlanSnapshots: String, CaseIterable, Identifiable, CustomStringConvertible {
    case Every // keepallselcteddayofweek
    case Last // islastSelectedDayinMonth

    var id: String { rawValue }
    var description: String { rawValue.localizedLowercase }
}

@Model
final class SynchronizeConfiguration: Identifiable {
    var id = UUID()
    var hiddenID: Int
    var task: String
    var localCatalog: String
    var offsiteCatalog: String
    var offsiteUsername: String
    var parameter1: String
    var parameter2: String
    var parameter3: String
    var parameter4: String
    var parameter5: String
    var parameter6: String
    var offsiteServer: String
    var backupID: String
    var dateRun: String?
    var snapshotnum: Int?
    // parameters choosed by user
    var parameter8: String?
    var parameter9: String?
    var parameter10: String?
    var parameter11: String?
    var parameter12: String?
    var parameter13: String?
    var parameter14: String?
    var rsyncdaemon: Int?
    // SSH parameters
    var sshport: Int?
    var sshkeypathandidentityfile: String?
    // Calculated days since last backup
    var dayssincelastbackup: String?
    // Snapshots, day to save and last = 1 or every last=0
    var snapdayoffweek: String?
    var snaplast: Int?
    // Profile
    var profile: String = "Default profile"

    init(id: UUID = UUID(), hiddenID: Int, task: String, localCatalog: String, offsiteCatalog: String, offsiteUsername: String, parameter1: String, parameter2: String, parameter3: String, parameter4: String, parameter5: String, parameter6: String, offsiteServer: String, backupID: String, dateRun: String? = nil, snapshotnum: Int? = nil, parameter8: String? = nil, parameter9: String? = nil, parameter10: String? = nil, parameter11: String? = nil, parameter12: String? = nil, parameter13: String? = nil, parameter14: String? = nil, rsyncdaemon: Int? = nil, sshport: Int? = nil, sshkeypathandidentityfile: String? = nil, dayssincelastbackup: String? = nil, snapdayoffweek: String? = nil, snaplast: Int? = nil, profile: String) {
        self.id = id
        self.hiddenID = hiddenID
        self.task = task
        self.localCatalog = localCatalog
        self.offsiteCatalog = offsiteCatalog
        self.offsiteUsername = offsiteUsername
        self.parameter1 = parameter1
        self.parameter2 = parameter2
        self.parameter3 = parameter3
        self.parameter4 = parameter4
        self.parameter5 = parameter5
        self.parameter6 = parameter6
        self.offsiteServer = offsiteServer
        self.backupID = backupID
        self.dateRun = dateRun
        self.snapshotnum = snapshotnum
        self.parameter8 = parameter8
        self.parameter9 = parameter9
        self.parameter10 = parameter10
        self.parameter11 = parameter11
        self.parameter12 = parameter12
        self.parameter13 = parameter13
        self.parameter14 = parameter14
        self.rsyncdaemon = rsyncdaemon
        self.sshport = sshport
        self.sshkeypathandidentityfile = sshkeypathandidentityfile
        self.dayssincelastbackup = dayssincelastbackup
        self.snapdayoffweek = snapdayoffweek
        self.snaplast = snaplast
        self.profile = profile
    }

    // Used in Copy tasks
    init() {
        hiddenID = -1
        task = ""
        localCatalog = ""
        offsiteCatalog = ""
        offsiteUsername = ""
        parameter1 = ""
        parameter2 = ""
        parameter3 = ""
        parameter4 = ""
        parameter5 = ""
        parameter6 = ""
        offsiteServer = ""
        backupID = ""
    }
}

extension SynchronizeConfiguration: Hashable, Equatable {
    static func == (lhs: SynchronizeConfiguration, rhs: SynchronizeConfiguration) -> Bool {
        return lhs.localCatalog == rhs.localCatalog &&
            lhs.offsiteCatalog == rhs.offsiteCatalog &&
            lhs.offsiteUsername == rhs.offsiteUsername &&
            lhs.offsiteServer == rhs.offsiteServer &&
            lhs.hiddenID == rhs.hiddenID &&
            lhs.task == rhs.task &&
            lhs.parameter1 == rhs.parameter1 &&
            lhs.parameter2 == rhs.parameter2 &&
            lhs.parameter3 == rhs.parameter3 &&
            lhs.parameter4 == rhs.parameter4 &&
            lhs.parameter5 == rhs.parameter5 &&
            lhs.parameter6 == rhs.parameter6 &&
            lhs.parameter8 == rhs.parameter8 &&
            lhs.parameter9 == rhs.parameter9 &&
            lhs.parameter10 == rhs.parameter10 &&
            lhs.parameter11 == rhs.parameter11 &&
            lhs.parameter12 == rhs.parameter12 &&
            lhs.parameter13 == rhs.parameter13 &&
            lhs.parameter14 == rhs.parameter14 &&
            lhs.dateRun == rhs.dateRun &&
            lhs.profile == rhs.profile
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(localCatalog)
        hasher.combine(offsiteUsername)
        hasher.combine(offsiteServer)
        hasher.combine(String(hiddenID))
        hasher.combine(task)
        hasher.combine(parameter1)
        hasher.combine(parameter2)
        hasher.combine(parameter3)
        hasher.combine(parameter4)
        hasher.combine(parameter5)
        hasher.combine(parameter6)
        hasher.combine(parameter8)
        hasher.combine(parameter9)
        hasher.combine(parameter10)
        hasher.combine(parameter11)
        hasher.combine(parameter12)
        hasher.combine(parameter13)
        hasher.combine(parameter14)
        hasher.combine(dateRun)
        hasher.combine(profile)
    }
}

// swiftlint:enable line_length
