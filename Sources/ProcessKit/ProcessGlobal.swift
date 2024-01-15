//
//  Global.swift
//  PIDTuner
//
//  Created by Rick Street on 7/30/20.
//  Copyright © 2020 Rick Street. All rights reserved.
//

import Foundation

// Usage:
// let tuner = SingletonTuner.sharedInstance
public final class SingletonTuner {
    static let sharedInstance = Tuner()
    private init() {} //This prevents others from using the default '()' initializer for this class.
}

// Usage:
// let simulator = SingletonLoopSimulator.sharedInstance
public final class SingletonLoopSimulator {
    static let sharedInstance = LoopSimulator()
    private init() {} //This prevents others from using the default '()' initializer for this class.
}

public enum ProcessType: String {
    case FO = "FO"
    case SO = "SO"
    case I = "I"
    
    public var description: String {
        get {
            switch self {
            case .FO:
                return "First Order with Dead Time"
            case .SO:
                return "Second Order with Dead Time"
            case .I:
                return " Integrating with Dead Time"
            }
        }
    }
}

public enum PIDMode: String {
 case PI = "PI"
 case PID = "PID"
}

public enum PIDForm: String {
 case Parallel = "Parallel"
 case Series = "Series"
}

