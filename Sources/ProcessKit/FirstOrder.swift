//
//  VelocityFirstOrder.swift
//  TunerSimulator
//
//  Created by Rick Street on 6/23/16.
//  Copyright © 2016 Rick Street. All rights reserved.
//
// Calculates First Order Response as Velocity (deltas)
// All in scaled math (no unites, fraction of range)


import Foundation

public class FirstOrder {
    var inputLast = 0.0
    var outputLast = 0.0
    public var gain = 1.0 {
        didSet {
            print("set 1st order gain to \(gain)")
        }
    }
    public var tau = 1.0  // In minutes
    public var execFreq: Double = 1.0 // Process Exicution Frequency in Seconds
    
    var tauAtFrequency: Double {
        get {
            return tau * 60.0 / execFreq
        }
    }
    
    public var output = 0.0
    
    public var input: Double = 0.0 {
        didSet {
            output = gain * ((1.0 - exp(-execFreq / tauAtFrequency)) * inputLast)
            + exp(-execFreq / tauAtFrequency) * outputLast
            inputLast = input
            outputLast = output
        }
    }
        
    public func initialize() {
        input = 0.0
        inputLast = 0.0
        outputLast = 0.0
    }
    
    public init() {
        // Empty ConfigParam
    }
    
    
}
