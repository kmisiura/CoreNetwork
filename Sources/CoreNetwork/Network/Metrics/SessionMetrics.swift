//
//  Tumbleweed.swift
//  NRK
//
//  Created by Johan Sørensen on 06/04/2017.
//  Copyright © 2017 NRK. All rights reserved.
//

import Foundation

/// An object that is capable of collection metrics based on a given set of URLSessionTaskMetrics
@available(iOS 10.0, macOS 10.12, tvOS 10.0, *)
public struct SessionMetrics {
    public let metrics: [Metric]
    public let redirectCount: Int
    public let taskInterval: DateInterval
    
    public init(source sessionTaskMetrics: URLSessionTaskMetrics) {
        self.redirectCount = sessionTaskMetrics.redirectCount
        self.taskInterval = sessionTaskMetrics.taskInterval
        self.metrics = sessionTaskMetrics.transactionMetrics.map(Metric.init(transactionMetrics:))
    }
}
