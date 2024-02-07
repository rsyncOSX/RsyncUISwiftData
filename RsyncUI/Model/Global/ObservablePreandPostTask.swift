//
//  ObservablePreandPostTask.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 03/06/2021.
//

import Foundation
import Observation

@Observable
final class ObservablePreandPostTask {
    var enablepre: Bool = false
    var enablepost: Bool = false
    var pretask: String = ""
    var posttask: String = ""
    var haltshelltasksonerror: Bool = false
    var configuration: SynchronizeConfiguration?
    // Alerts
    var alerterror: Bool = false
    var error: Error = Validatedpath.noerror

    /*
     func updateconfig(_ profile: String?, _ configurations: [SynchronizeConfiguration]?) -> [SynchronizeConfiguration]? {
         // Append default config data to the update,
         // only post and pretask is new
         let updateddata = AppendTask(configuration?.task ?? "",
                                      configuration?.localCatalog ?? "",
                                      configuration?.offsiteCatalog ?? "",
                                      false,
                                      configuration?.offsiteUsername,
                                      configuration?.offsiteServer,
                                      configuration?.backupID,
                                      enablepre,
                                      pretask,
                                      enablepost,
                                      posttask,
                                      haltshelltasksonerror,
                                      configuration?.hiddenID ?? -1)
         if let updatedconfig = VerifyConfiguration().verify(updateddata) {
             let updateconfigurations =
                 UpdateConfigurations(profile: profile,
                                      configurations: configurations)
             updateconfigurations.updateconfiguration(updatedconfig, false)
             resetform()
             return updateconfigurations.configurations
         }
         return configurations
     }

      func validateandupdate(_ profile: String?, _ configurations: [SynchronizeConfigurationJSON]?) -> [SynchronizeConfigurationJSON]? {
          // Validate not a snapshot task
          do {
              let validated = try validatenotsnapshottask()
              if validated {
                  return updateconfig(profile, configurations)
              }
          } catch let e {
              error = e
              alerterror = true
          }
          return configurations
      }
     */
    func reset() {
        enablepre = false
        pretask = ""
        enablepost = false
        posttask = ""
        haltshelltasksonerror = false
        configuration = nil
    }

    func updateview(_ config: SynchronizeConfiguration?) {
        configuration = config
        if let config = configuration {
            // pre task
            pretask = config.pretask ?? ""
            if config.pretask != nil {
                if config.executepretask == 1 {
                    enablepre = true
                } else {
                    enablepre = false
                }
            } else {
                enablepre = false
            }

            // post task
            posttask = config.posttask ?? ""
            if config.posttask != nil {
                if config.executeposttask == 1 {
                    enablepost = true
                } else {
                    enablepost = false
                }
            } else {
                enablepost = false
            }

            if config.posttask != nil {
                if config.haltshelltasksonerror == 1 {
                    haltshelltasksonerror = true
                } else {
                    haltshelltasksonerror = false
                }
            } else {
                haltshelltasksonerror = false
            }
        } else {
            reset()
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
}
