//
//  VelocityIntegrator.swift
//  TunerSimulator
//
//  Created by Rick Street on 7/11/16.
//  Copyright © 2016 Rick Street. All rights reserved.
//

import Foundation

public class Integrator {
    
     //var deltaMV = 0.0
    var mV = 0.0
    public var gain = 1.0
    public var execFreq: Double = 1.0 // Process Exicution Frequency in Seconds
    
    var gainAtFrequency: Double {
        get {
            return gain / (60.0 * execFreq)
        }
    }
    
    public var output = 0.0
    var outputLast = 0.0

    public var input: Double = 0.0 {
        didSet {
            output = gainAtFrequency * input * execFreq + outputLast
            // output = gainAtFrequency * input + outputLast
           outputLast = output
        }
    }
    
    /*
    func deltaCv(_ deltaMV: Double) -> Double {
        mV += deltaMV
        return gainAtFrequency * mV * execFreq
    }
    */
    
    public func initialize() {
        // deltaMV = 0.0
        mV = 0.0
    }
    
    public init() {
    }


    
}
