//
//  MyTimer.swift
//  CRAttributes
//
//  Created by Mateusz Lapsa-Malawski on 21/11/2021.
//

import Foundation
import Combine


struct DispatchTimerConfiguration {
    // 1
    let queue: DispatchQueue?
    // 2
    let interval: DispatchTimeInterval
    // 3
    let leeway: DispatchTimeInterval
    // 4
    let times: Subscribers.Demand
}

extension Publishers {
    struct DispatchTimer: Publisher {
        // 5
        typealias Output = DispatchTime
        typealias Failure = Never
        
        // 6
        let configuration: DispatchTimerConfiguration
        
        init(configuration: DispatchTimerConfiguration) {
            self.configuration = configuration
        }
        
        // 7
        func receive<S: Subscriber>(subscriber: S)
        where Failure == S.Failure,
              Output == S.Input {
                  // 8
                  let subscription = DispatchTimerSubscription(
                    subscriber: subscriber,
                    configuration: configuration
                  )
                  // 9
                  subscriber.receive(subscription: subscription)
              }
    }
}

private final class DispatchTimerSubscription<S: Subscriber>: Subscription
where S.Input == DispatchTime {
    // 10
    let configuration: DispatchTimerConfiguration
    // 11
    var times: Subscribers.Demand
    // 12
    var requested: Subscribers.Demand = .none
    // 13
    var source: DispatchSourceTimer? = nil
    // 14
    var subscriber: S?
    
    init(subscriber: S,
         configuration: DispatchTimerConfiguration) {
        self.configuration = configuration
        self.subscriber = subscriber
        self.times = configuration.times
    }
    
    // 15
    func request(_ demand: Subscribers.Demand) {
        // 16
        guard times > .none else {
            // 17
            subscriber?.receive(completion: .finished)
            return
        }
        
        // 18
        requested += demand
        
        // 19
        if source == nil, requested > .none {
            // 20
            let source = DispatchSource.makeTimerSource(queue: configuration.queue)
            // 21
            source.schedule(deadline: .now() + configuration.interval,
                            repeating: configuration.interval,
                            leeway: configuration.leeway)
            
            // 22
            source.setEventHandler { [weak self] in
                // 23
                guard let self = self,
                      self.requested > .none else { return }
                
                // 24
                self.requested -= .max(1)
                self.times -= .max(1)
                // 25
                _ = self.subscriber?.receive(.now())
                // 26
                if self.times == .none {
                    self.subscriber?.receive(completion: .finished)
                }
            }
            
            self.source = source
            source.activate()
        }
    }
    
    func cancel() {
        source = nil
        subscriber = nil
    }
}

extension Publishers {
    static func timer(queue: DispatchQueue? = nil,
                      interval: DispatchTimeInterval,
                      leeway: DispatchTimeInterval = .nanoseconds(0),
                      times: Subscribers.Demand = .unlimited)
    -> Publishers.DispatchTimer {
        return Publishers.DispatchTimer(
            configuration: .init(queue: queue,
                                 interval: interval,
                                 leeway: leeway,
                                 times: times)
        )
    }
}
