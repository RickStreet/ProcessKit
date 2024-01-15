//
//  Process.swift
//
//
//  Created by Rick Street on 4/27/15.
//
//

import Foundation

public class Tuner {
    
    // Declare Dictionaries
    var processTypes = [String: ProcessType]()
    var controlModes = [String: PIDMode]()
    var controllerTypes = [String: PIDForm]()
    
    // Set Initial Enum Values
    public var processType: ProcessType = ProcessType.FO
    public var pidMode: PIDMode = PIDMode.PID
    public var pidForm: PIDForm = PIDForm.Parallel
        
    public var processGainScaled: Double?
    public var processTau1: Double?
    public var processTau2: Double?
    public var processDeadTime: Double?
    
    public var controllerGain: Double?
    
    public var controllerMaxGain: Double?
    
    public var integralTime: Double?
    public var derivativeTime: Double?
    public var controllerFilter: Double?
    public var controllerSetpointFilter: Double?
    
    public var lamdaToTau: Double = 1.0 {
        didSet {
            calcTuningParams()
        }
    }
    
    
    public var equivalentTau: Double? {
        if processType == .FO {
            return processTau1
        }
        if processType == .SO {
            if let tau1 = processTau1, let tau2 = processTau2 {
                return tau1 + tau2 / 2.0
            }
        }
        return nil
    }
    
    public var equivalentDeadTime: Double? {
        if processType != .SO {
            return processDeadTime
        }
        if processType == .SO {
            if let tau2 = processTau2, let deadTime = processDeadTime {
                return deadTime + tau2 / 2.0
            }
        }
        return nil
    }
    
    // Lamda
    public var closedLoopTimeConstant: Double? {
        get {
            if processType == .I {
                if let dt = processDeadTime {
                    print("Have DeadTime: \(lamdaToTau + dt) and can calc Tau Closed")
                    return lamdaToTau
                }
                
            } else {
                // Non-Integrator
                if let tau = equivalentTau {
                    // print("Have Tau: \(lamdaToTau * tau) and can calc Tau Closed")
                    return lamdaToTau * tau
                }
            }
            // print("Do not have a Tau Closed:")
            return nil
        }
    }
    
    public var lamdaToDeadtime: Double? {
        get {
            if let lamda = closedLoopTimeConstant, let dt = processDeadTime {
                if dt > 0.0 {
                    return lamda / dt
                } else {
                    return nil
                }
            }
            return nil
        }
    }
    
    
    public var gainKpKc: Double? {
        get {
            if let kp = processGainScaled {
                if let kc = controllerGain {
                    return kp * kc
                }
            }
            return nil
        }
        
    }
    
    public var minStableLamdaToDeadtime: Double {
        get {
            if let tdt = uncontrollabilityParam {
                if pidMode == .PI {
                    return 0.6483 * tdt + 0.0352
                } else {
                    return 0.02
                }
            }
            return 0.0
        }
    }
    
    
    public func calcTuningParams() {
        print("Tau 1: \(String(describing: processTau1))")
        print("Tau 2: \(String(describing: processTau2))")
        print("Dead Time: \(String(describing: processDeadTime))")
        controllerGain = nil
        integralTime = nil
        derivativeTime = nil
        
        switch processType {
            
        case .FO:
            print("First Order with Deadtime...")
            if let kp = processGainScaled, let tau1 = processTau1, let dt = processDeadTime, let tauClosed = closedLoopTimeConstant {
                switch pidMode {
                case .PID:
                    // print("PID")
                    let ti = tau1 + (dt * dt) / (2 * (tauClosed + dt))
                    let kc = ti / ( kp * (tauClosed + dt))
                    let td = (dt * dt) / (6 * (tauClosed + dt)) * (3 - dt / ti)
                    
                    switch pidForm {
                    case .Parallel:
                        // print("Parallel")
                        controllerGain = kc
                        integralTime = ti
                        derivativeTime = td
                        print("Tuning: \(controllerGain ?? -999.0) \(integralTime ?? -999.0) \(derivativeTime ?? -999.0)")
                    case .Series:
                        // print("Series")
                        let tuningParameters = parallelToSeries(controllerGain: kc, integralTime: ti, derivativeTime: td)
                        controllerGain = tuningParameters.controllerGain
                        integralTime = tuningParameters.integralTime
                        derivativeTime = tuningParameters.derivativeTime
                        // print("Tuning P FO: \(controllerGain) \(controllerIntegralTime) \(controllerDerivativeTime)")
                    }
                case .PI:
                    print("PI")
                    let kc = (1/kp) * tau1 / (tauClosed)
                    let ti = min( tau1, 4 * (tauClosed + dt))
                    controllerGain = kc
                    integralTime = ti
                    derivativeTime = nil
                }
            } else {
            }
            
        case .SO:
            print("Second Order...")
            if let kp = processGainScaled,
               let tau1 = processTau1,
               let tau2 = processTau2,
               let dCoef = dampingCoef,
               let dt = processDeadTime,
               let tauClosed = closedLoopTimeConstant {
                // let taus = [tau1, tau2]
                switch pidMode {
                case .PID:
                    print("PID")
                    let tau = sqrt(tau1 + tau2)
                    let ti = 2 * dCoef * tau + (dt * dt) / (2.0 * (tauClosed + dt))
                    let kc = ti / (kp * (tauClosed + dt))
                    let td = (tau * tau - dt * dt * dt / (6 * (tauClosed + dt))) / ti + dt * dt / (2 * (tauClosed + dt))
                    switch pidForm {
                    case .Parallel:
                        print("Parallel")
                        controllerGain = kc
                        integralTime = ti
                        derivativeTime = td
                        // print("Tuning: \(controllerGain) \(controllerIntegralTime) \(controllerDerivativeTime)")
                        
                    case .Series:
                        print("Series")
                        let tuningParameters = parallelToSeries(controllerGain: kc, integralTime: ti, derivativeTime: td)
                        controllerGain = tuningParameters.controllerGain
                        integralTime = tuningParameters.integralTime
                        derivativeTime = tuningParameters.derivativeTime
                    }
                case .PI:
                    print("PI")
                    let dtEffective = dt + tau2 / 2
                    let tau1Effective = tau1 + tau2 / 2
                    let kc = tau1Effective / kp * 1 / ( tauClosed + dtEffective)
                    let ti = min(tau1Effective, 4 * (tauClosed + dtEffective))
                    controllerGain = kc
                    integralTime = ti
                    derivativeTime = nil
                }
            } else {
                controllerGain = nil
                integralTime = nil
                derivativeTime = nil
            }
            
        case .I:
            print()
            print("Long Time Constant with Deadtime...")
            // processGainScaled = max slope
            if let kp = processGainScaled, let dt = processDeadTime, let tauClosed = closedLoopTimeConstant {
                let kcSeries = (1 / kp) * (1 / (tauClosed + dt)) // series
                print("Kc Series \(kcSeries)")
                let ti = 4 * (tauClosed + dt)
                print("Ti \(ti)")
                let td = dt / 2
                print("Td Series \(td)")
                switch pidMode {
                case .PID:
                    print("PID")
                    
                    switch pidForm {
                    case .Parallel:
                        // print("Parallel")
                        let tuningParameters = seriesToParallel(controllerGain: kcSeries, integralTime: ti, derivativeTime: td)
                        controllerGain = tuningParameters.controllerGain
                        print("Para Kc \(controllerGain ?? -999.9)")
                        integralTime = tuningParameters.integralTime
                        print("Para Ti \(integralTime ?? 999.9)")
                        derivativeTime = tuningParameters.derivativeTime
                        print("Para Td \(derivativeTime ?? 999.9)")
                        
                        
                    case .Series:
                        // print("Series")
                        controllerGain = kcSeries
                        integralTime = ti
                        derivativeTime = dt
                    }
                    print()
                case .PI:
                    print("PI")
                    let kc = (1/kp) * (1 / (tauClosed + dt))
                    let ti = 4 * (tauClosed + dt)
                    print("Kc \(kc)")
                    print("Ti \(ti)")
                    controllerGain = kc
                    integralTime = ti
                    derivativeTime = nil
                }
            } else {
                controllerGain = nil
                integralTime = nil
                derivativeTime = nil
            }
        }
        
    }
    func seriesToParallel (controllerGain gain: Double, integralTime integralT: Double, derivativeTime derivativeT: Double) -> (controllerGain: Double?, integralTime: Double?, derivativeTime: Double?) {
        let parallelGain = gain * (1 + derivativeT / integralT)
        let parallelIntegralT = integralT * (1 + derivativeT / integralT)
        let parallelDerivativeT = derivativeT / (1 + derivativeT / integralT)
        return (parallelGain, parallelIntegralT, parallelDerivativeT)
    }
    
    func parallelToSeries (controllerGain gain: Double, integralTime integralT: Double, derivativeTime derivativeT: Double) -> (controllerGain: Double?, integralTime: Double?, derivativeTime: Double?) {
        let seriesGain: Double?
        let seriesIntegralT: Double?
        let seriesDerivativeT: Double?
        
        if integralT >= 4 * derivativeT {
            seriesGain = (gain / 2) * (1 + sqrt(1 - 4 * derivativeT / integralT))
            seriesIntegralT = (integralT / 2) * (1 + sqrt(1 - 4 * derivativeT / integralT))
            seriesDerivativeT = (derivativeT / 2) * (1 + sqrt(1 - 4 * derivativeT / integralT))
        } else {
            seriesGain = nil
            seriesIntegralT = nil
            seriesDerivativeT = nil
        }
        return (seriesGain, seriesIntegralT, seriesDerivativeT)
    }
    
    public var dampingCoef: Double? {
        get {
            if let t1 = processTau1 {
                if let t2 = processTau2 {
                    // print("Damp Coef \((t1 + t2) / (2 * sqrt(t1 + t2)))")
                    return (t1 + t2) / (2 * sqrt(t1 + t2))
                }
            }
            return nil
        }
    }
    
    public var uncontrollabilityParam: Double? {
        get {
            if let t1 = processTau1 {
                if let dt = processDeadTime {
                    if t1 > 0.0 {
                        return dt / t1
                    }
                }
            }
            return nil
        }
    }
    
    public init() {
        // Fill Dictionaries
        processTypes = ["FO" : .FO,
                        "SO" : .SO,
                        "I" : .I]
        
        controlModes = ["PI" : .PI,
                        "PID" : .PID]
        
        controllerTypes = ["Parallel" : .Parallel,
                           "Series" : .Series]
        lamdaToTau = 1.0
    }
}
