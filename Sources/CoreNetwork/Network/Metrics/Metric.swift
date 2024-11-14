//
//  Metric.swift
//  Tumbleweed
//
//  Created by Johan Sørensen on 06/04/2017.
//  Copyright © 2017 NRK. All rights reserved.
//

import Foundation

@available(iOS 10.0, macOS 10.12, tvOS 10.0, *)
protocol Measurable {
    var request: URLRequest { get }
    var response: URLResponse? { get }
    
    var networkProtocolName: String? { get }
    var isProxyConnection: Bool { get }
    var isReusedConnection: Bool { get }
    var resourceFetchType: URLSessionTaskMetrics.ResourceFetchType { get }
    
    var domainLookupStartDate: Date? { get }
    var domainLookupEndDate: Date? { get }
    
    var connectStartDate: Date? { get }
    var connectEndDate: Date? { get }
    var secureConnectionStartDate: Date? { get }
    var secureConnectionEndDate: Date? { get }
    
    var requestStartDate: Date? { get }
    var requestEndDate: Date? { get }
    var responseStartDate: Date? { get }
    var responseEndDate: Date? { get }
}

@available(iOS 10.0, macOS 10.12, tvOS 10.0, *)
extension URLSessionTaskTransactionMetrics: Measurable {}

@available(iOS 10.0, macOS 10.12, tvOS 10.0, *)
extension URLSessionTaskMetrics.ResourceFetchType {
    var name: String {
        switch self {
            case .unknown:
                return "unknown"
            case .networkLoad:
                return "network-load"
            case .serverPush:
                return "server-push"
            case .localCache:
                return "local-cache"
            @unknown default:
                return "unknown"
        }
    }
}

private extension Array where Element == Metric.Duration {
    func find(type: Metric.DurationType) -> Element? {
        return self.filter({ $0.type == type }).first
    }
}

@available(iOS 10.0, macOS 10.12, tvOS 10.0, *)
struct Metric {
    let transactionMetrics: Measurable
    let durations: [Duration]
    
    init(transactionMetrics metrics: Measurable) {
        self.transactionMetrics = metrics
        
        func check(type: DurationType, _ start: Date?, _ end: Date?) -> Duration? {
            guard let start = start, let end = end, start <= end else { return nil }
            return Duration(type: type, interval: DateInterval(start: start, end: end))
        }
        
        var durations: [Duration] = []
        // domain, {secure}connect is nil f a persistent connection was used or it was retrieved from local cache
        if let duration = check(type: .domainLookup, metrics.domainLookupStartDate, metrics.domainLookupEndDate) {
            durations.append(duration)
        }
        if let duration = check(type: .connect, metrics.connectStartDate, metrics.connectEndDate) {
            durations.append(duration)
        }
        if let duration = check(type: .secureConnection, metrics.secureConnectionStartDate, metrics.secureConnectionEndDate) {
            durations.append(duration)
        }
        if let duration = check(type: .request, metrics.requestStartDate, metrics.requestEndDate) {
            durations.append(duration)
        }
        if let duration = check(type: .response, metrics.responseStartDate, metrics.responseEndDate) {
            durations.append(duration)
        }
        if let duration = check(type: .total, metrics.domainLookupStartDate, metrics.responseEndDate) {
            durations.append(duration)
        }
        
        // Calculate how long the server spent processing the request
        if let request = durations.find(type: .request),
           let response = durations.find(type: .response),
           let index = durations.firstIndex(of: response),
           request.interval.duration > 0 {
            let interval: DateInterval
            /// Adding safe cehck. Because there are crashes for this.
            /// That could only occure if start date is later then end date.
            if request.interval.end <= response.interval.start {
                interval = DateInterval(start: request.interval.end, end: response.interval.start)
            } else {
                interval = DateInterval(start: request.interval.end, duration: 0)
            }
            let duration = Duration(type: .server, interval: interval)
            durations.insert(duration, at: index)
        }
        
        self.durations = durations
    }
    
    internal init(transactionMetrics metrics: Measurable, durations: [Duration]) {
        self.transactionMetrics = metrics
        self.durations = durations
    }
    
    enum DurationType {
        case domainLookup
        case connect
        case secureConnection
        case request
        case server
        case response
        case total
        
        var name: String {
            switch self {
                case .domainLookup:
                    return "domain lookup"
                case .connect:
                    return "connect"
                case .secureConnection:
                    return "secure connection"
                case .request:
                    return "request"
                case .server:
                    return "server"
                case .response:
                    return "response"
                case .total:
                    return "total"
            }
        }
    }
    
    struct Duration {
        let type: DurationType
        let interval: DateInterval
    }
}

@available(iOS 10.0, macOS 10.12, tvOS 10.0, *)
extension Metric.Duration: Equatable {
    static func ==(lhs: Metric.Duration, rhs: Metric.Duration) -> Bool {
        return rhs.type == lhs.type && rhs.interval == rhs.interval
    }
}
