//
//  Profilenames.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 06/02/2024.
//

import Foundation
import Observation

struct Profiles: Hashable, Identifiable {
    var profile: String
    let id = UUID()

    init(_ name: String) {
        profile = name
    }
}

@Observable
final class Profilenames {
    var profiles: [Profiles] = .init()

    func setprofilenames(_ configurations: [SynchronizeConfiguration]) {
        for i in 0 ..< configurations.count {
            if profiles.filter({ $0.profile == configurations[i].profile }).isEmpty {
                profiles.append(Profiles(configurations[i].profile))
            }
        }
    }

    init(_ configurations: [SynchronizeConfiguration]) {
        setprofilenames(configurations)
    }
}
