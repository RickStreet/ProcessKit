//
//  VelocityPIDController.swift
//  TunerSimulator
//
//  Created by Rick Street on 6/24/16.
//  Copyright © 2016 Rick Street. All rights reserved.
//
// Velocity Form
// set deltaSetpoint and then call deltaMV()

import Foundation

public class PID {
    public var execFreq: Double = 1.0 // Process Exicution Frequency in Seconds
    
    public var gain = 0.0 // Scaled Gain
    public var integralTime = 0.0 // minutes
    public var derivativeTime = 0.0 // minutes
    var alpha: Double {
        return execFreq / 10.0
    }
    // public var deltaSetpoint = 0.0
    // fileprivate var setpoint = 0.0
    // fileprivate var setpointLast = 0.0
    fileprivate var errorLast = 0.0
    fileprivate var cVLast1 = 0.0
    fileprivate var cVLast2 = 0.0
    fileprivate var bkLast = 0.0
    fileprivate var ykLast = 0.0
    fileprivate var ekLast = 0.0
    
    public var pidMode: PIDMode = .PID {
        didSet {
            // initialize()
        }
    }
    public var pidForm: PIDForm = .Parallel {
        didSet {
            // initialize()
        }
    }
    
    public var ready: Bool {
        print("checking if controller Ready from PID")
        print("pid ready?")
        print("gain \(gain)")
        print("intTime \(integralTime)")
        return gain != 0.0 && integralTime != 0.0
    }
    
    var integralTimeAtFrequency: Double {
        get {
            return integralTime * 60.0 / execFreq
        }
        
    }
    
    var derivativeTimeAtFrequency: Double {
        get {
            return derivativeTime * 60.0 / execFreq
        }
        
    }
    
    public var output = 0.0 
    
    public var input: Double = 0.0 {
        didSet {
            output = deltaMV(input)
        }
    }
    
    public var setpoint = 0.0
    
    // var setpointLast = 0.0
    // var deltaSetpoint = 0.0

    func deltaMV(_ deltaCV: Double) -> Double {
        var td: Double  // derivative time for control mode
        switch pidMode {
        case .PID:
            td = derivativeTimeAtFrequency
        case .PI:
            td = 0.0
        }
        // deltaSetpoint = setpoint - setpointLast
        let deltaError = setpoint - deltaCV
        let error = errorLast + deltaError
        let cV = cVLast1 + deltaCV
        
        //print("deltaError \(deltaError)")
        //print("error \(error)")
        //print("setpoint \(setpoint)")
        //print("cv \(cV)")
        var deltaMV: Double
        
        switch pidForm {
        case .Parallel:
            let bk = ((alpha * td) / (execFreq + alpha * td)) * bkLast
                   - (td / (execFreq + alpha * td)) * (cV - 2.0 * cVLast1 + cVLast2)
            
            deltaMV = gain * (error - errorLast + (execFreq/integralTimeAtFrequency) * (error + errorLast)/2 + bk)
            bkLast = bk
        case .Series:
            let yk = (alpha * td / (execFreq + alpha * td)) * ykLast + (execFreq / (execFreq + alpha * td)) * cV + ((alpha + 1.0) * td / (execFreq + alpha * td)) * (cV - cVLast1)

            // let ek = setpoint - yk
            deltaMV = gain * (error - errorLast + (execFreq / integralTimeAtFrequency) * error)
            //print("yk \(yk)")
            // print("ek \(ek)")
            //print()
            ykLast = yk
            // ekLast = ek

        }
        
        errorLast = error
        cVLast2 = cVLast1
        cVLast1 = cV
        setpoint = 0.0
            
        
        return deltaMV
    }
    
    /// Initialize PID Controller (set values to zero)
    func initialize() {
        setpoint = 0.0
        // setpointLast = 0.0
        errorLast = 0.0
        cVLast1 = 0.0
        cVLast2 = 0.0
        bkLast = 0.0
        ykLast = 0.0
        ekLast = 0.0
    }
    
    public init() {
        
    }

    

}
