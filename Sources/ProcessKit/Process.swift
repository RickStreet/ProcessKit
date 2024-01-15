//
//  File.swift
//  
//
//  Created by Rick Street on 7/29/20.
//
// All Scaled, All velocity, no Optionls


import Foundation

public class Process {
    /*
     public enum ProcessType: String {
     case FO = "FO"
     case SO = "SO"
     case I = "I"
     
     var description: String {
     get {
     switch self {
     case .FO:
     return "First Order with Dead Time"
     case .SO:
     return "Second Order with Dead Time"
     case .I:
     return " Integrating or Long Time Constant with Dead Time"
     }
     }
     }
     }
     */
    
    public var processType = ProcessType.FO
    var firstOrder1 = FirstOrder()
    var firstOrder2 = FirstOrder()
    var integrator = Integrator()
    var deadTime = DeadTime()
    
    public var cvLoRange: Double?
    public var cvHiRange: Double?
    public var mvLoRange: Double?
    public var mvHiRange: Double?
    var gainEU: Double?

    
    public var gainScaled: Double? { // Use Scaled Gain when tied to a PID Controller
        get {
            print()
            print("scaledGain from process...")
            print("gainEU, \(String(describing: gainEU))")
            print("mvLoRange \(String(describing: mvLoRange))")
            print("mvHiRange \(String(describing: mvHiRange))")
            print("cvLoRange \(String(describing: cvLoRange))")
            print("cvHiRange \(String(describing: cvHiRange))")
            if let cvLo = cvLoRange, let cvHi = cvHiRange, let mvLo = mvLoRange, let mvHi = mvHiRange, let gain = gainEU {
                let scaled = gain * (mvHi - mvLo) / (cvHi - cvLo)
                switch processType {
                case .FO, .SO:
                    firstOrder1.gain = scaled
                    firstOrder2.gain = 1.0
                case .I:
                    integrator.gain = scaled
                }
               return scaled
            }  else {
                print("mising param")
                return nil
            }
        }
    }
    
    public var deltaCV: Double? {
        didSet {
            print()
            print("set detlaCV")
            calcGainEU()
        }
    }
    public var deltaMV: Double?  {
        didSet {
            print()
            print("set detlaMV")
            calcGainEU()
        }
    }
    
    public var deltaTime: Double?  {
        didSet {
            print()
            print("set detlaTime Sim")
            calcGainEU()
        }
    }

    func calcGainEU() {
        print("calcGainEU()...")
        print("deltaCV \(String(describing: deltaCV))")
        print("deltaMV \(String(describing: deltaMV))")
        print("deltaTime \(String(describing: deltaTime))")
        if let dCV = deltaCV, let dMV = deltaMV {
            if processType == .I {
                if let dTime = deltaTime {
                    gainEU = dCV / (dMV * dTime)
                }
            } else {
                gainEU = dCV / dMV
            }
            print("gainEU \(String(describing: gainEU))")
        }
    }
    
    
    
    public var tau1: Double? {
        didSet {
            if let tau = tau1 {
                firstOrder1.tau = tau
            }
        }
    }
    
    public var tau2: Double? {
        didSet {
            if let tau = tau2 {
                firstOrder2.tau = tau
            }
        }
    }
    
    
    public var deadtime: Double? {
        didSet {
            // print("set process deadtime \(deadtime)")
            if let deadtime = deadtime {
                deadTime.deadtime = deadtime
            }
        }
    }
    
    var execFreq: Double = 1.0 {
        didSet {
            firstOrder1.execFreq = execFreq
            firstOrder2.execFreq = execFreq
            deadTime.execFreq = execFreq
            integrator.execFreq = execFreq
        }
    }
    
    public var ready: Bool { // All parameters set
        print("is process ready...")
        print("gain \(gainScaled ?? -999.9)")
        print("tau1 \(tau1 ?? -999.9)")
        print("deadtime \(deadtime ?? -999.9)")

        switch processType {
        case .FO:
            return gainScaled != nil && tau1 != nil && deadtime != nil
        case .SO:
            return gainScaled != nil && tau1 != nil && tau1 != nil && deadtime != nil
        case .I:
            return gainScaled != nil && deadtime != nil
        }
    }
    
    public var input: Double = 0 {
        didSet {
            if processType == .FO {
                firstOrder1.input = input
                deadTime.input = firstOrder1.output
            }
            if processType == .SO {
                firstOrder1.input = input
                firstOrder2.input = firstOrder1.output
                deadTime.input = firstOrder2.output
            }
            if processType == .I {
                integrator.input = input
                deadTime.input = integrator.output
            }
            output = deadTime.output
        }
    }
    
    public var output = 0.0
    

    
    public func initialize() {
        deadTime.initialize()
        firstOrder1.initialize()
        firstOrder2.initialize()
        integrator.initialize()
    }
    
    public init() {
        
    }
    
    
}
