//
//  EstimationInProgressView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 19/12/2023.
//

import SwiftData
import SwiftUI

struct EstimationInProgressView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var configurations: [SynchronizeConfiguration]

    @Bindable var executeprogressdetails: ExecuteProgressDetails
    @Bindable var estimateprogressdetails: EstimateProgressDetails
    @Binding var selecteduuids: Set<SynchronizeConfiguration.ID>
    @Binding var nodatatosynchronize: Bool

    var body: some View {
        VStack {
            if let config = config {
                Text("Estimating now: " + "\(config.backupID)")
            }

            progressviewestimateasync
        }
        .onAppear {
            estimateprogressdetails.resetcounts()
            executeprogressdetails.estimatedlist = nil
            estimateprogressdetails.estimatealltasksasync = true
        }
        .padding()
    }

    var config: SynchronizeConfiguration? {
        if let uuid = estimateprogressdetails.configurationtobestimated {
            if let index = configurations.firstIndex(
                where: { $0.id == uuid })
            {
                return configurations[index]
            }
        }
        return nil
    }

    var progressviewestimateasync: some View {
        ProgressView("",
                     value: estimateprogressdetails.numberofconfigurationsestimated,
                     total: Double(configurations.count))
            .onAppear {
                Task {
                    // Either is there some selceted tasks or if not
                    // the EstimateTasksAsync selects all tasks to be estimated.
                    let estimate = EstimateTasksAsync(configurations: configurations,
                                                      estimateprogressdetails: estimateprogressdetails,
                                                      uuids: selecteduuids,
                                                      filter: "")
                    await estimate.startestimation()
                }
            }
            .onDisappear {
                executeprogressdetails.estimatedlist = nil
                executeprogressdetails.estimatedlist = estimateprogressdetails.getestimatedlist()
                nodatatosynchronize = {
                    if let data = estimateprogressdetails.getestimatedlist()?.filter({
                        $0.datatosynchronize == true })
                    {
                        return data.isEmpty
                    } else {
                        return false
                    }
                }()
            }
            .progressViewStyle(.circular)
    }
}
