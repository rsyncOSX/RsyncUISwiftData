//
//  TrimTwo.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 05/05/2021.
//

import Combine
import Foundation

enum Rsyncerror: LocalizedError {
    case rsyncerror

    var errorDescription: String? {
        switch self {
        case .rsyncerror:
            return "There are errors in output"
        }
    }
}

final class TrimTwo {
    var subscriptions = Set<AnyCancellable>()
    var trimmeddata = [String]()
    var maxnumber: Int = 0
    var errordiscovered: Bool = false

    // Error handling
    func checkforrsyncerror(_ line: String) throws {
        let error = line.contains("rsync error:")
        if error {
            throw Rsyncerror.rsyncerror
        }
    }

    init(_ data: [String]) {
        data.publisher
            .sink(receiveCompletion: { completion in
                switch completion {
                case .finished:
                    return
                case let .failure(error):
                    self.propogateerror(error: error)
                }
            }, receiveValue: { [unowned self] line in
                if line.last != "/" {
                    trimmeddata.append(line)
                    if SharedReference.shared.checkforerrorinrsyncoutput {
                        do {
                            try checkforrsyncerror(line)
                        } catch let e {
                            // Only want one notification about error, not multiple
                            // Multiple can be a kind of race situation
                            if errordiscovered == false {
                                maxnumber = trimmeddata.count
                                let error = e
                                _ = Logfile(data, error: true)
                                propogateerror(error: error)
                                errordiscovered = true
                            }
                        }
                    }
                }
                maxnumber = trimmeddata.count
            })
            .store(in: &subscriptions)
    }
}

extension TrimTwo {
    func propogateerror(error: Error) {
        SharedReference.shared.errorobject?.alert(error: error)
    }
}
