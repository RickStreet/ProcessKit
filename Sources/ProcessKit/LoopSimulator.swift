//
//  File.swift
//  
//
//  Created by Rick Street on 7/29/20.
//

import Foundation
import AxisSpacing

public class LoopSimulator {
    var process = Process()
    var pid = PID()
    var tuner = Tuner()
    
    public var spData = [(x: Double, y: Double)]() // 0 to 1
    public var mvData = [(x: Double, y: Double)]()
    public var cvData = [(x: Double, y: Double)]()

    public var spDataPercent = [(x: Double, y: Double)]() // 0 to 1
    public var mvDataPercent = [(x: Double, y: Double)]()
    public var cvDataPercent = [(x: Double, y: Double)]()

    public var spDataEU = [(x: Double, y: Double)]()
    public var mvDataEU = [(x: Double, y: Double)]()
    public var cvDataEU = [(x: Double, y: Double)]()

    public var cvLoRange: Double? {
        didSet {
            process.cvLoRange = cvLoRange
            calcTuningParams()
        }
    }
    public var cvHiRange: Double? {
        didSet {
            process.cvHiRange = cvHiRange
            calcTuningParams()
        }
    }
    public var mvLoRange: Double? {
        didSet {
            process.mvLoRange = mvLoRange
            calcTuningParams()
        }
    }
    public var mvHiRange: Double? {
        didSet {
            process.mvHiRange = mvHiRange
            calcTuningParams()
        }
    }
    
    // Test Test
    // Positional Values
    public var sp = 0.5 // Initial setpoint at 50% - process and controller in velocity form
    public var cv = 0.5
    public var mv = 0.5
    
    
    public var processType = ProcessType.FO {
        didSet {
            process.processType = processType
            tuner.processType = processType
            calcTuningParams()
        }
    }
    
    // Calc Gain/Max Slope
    public var deltaCV: Double? {
        didSet {
            process.deltaCV = deltaCV
            //calcProcessGainEU()
        }
    }
    public var deltaMV: Double? {
        didSet {
            process.deltaMV = deltaMV
            // calcProcessGainEU()
        }
    }
    public var deltaTime: Double? {
        didSet {
            process.deltaTime = deltaTime
            // calcProcessGainEU()
        }
    }

    
    /// Process Gaini in EU
    public var processGainEU: Double? {
        set {
            print()
            print("set processGainEU \(String(describing: newValue))")
            process.gainEU = newValue
            calcTuningParams()
        }
        get {
            return process.gainEU
        }
        /*
        didSet {
            print()
            print("setting processGainEU... \(String(describing: processGainEU))")
            if let gain = processGainEU {
                print("gain \(gain)")
                process.gainEU = processGainEU
                calcTuningParams()
            }
        }
        */
    }
    
        
    /// Scaled Gain
    public var processGainScaled: Double? {
        print("scaledGain from Sim...")
        return process.gainScaled
    }
    
    public var processTau1: Double? {
        didSet {
            print()
            print("tau1 set \(String(describing: processTau1))")
            if let value = processTau1 {
                process.tau1 = value
                tuner.processTau1 = value
                calcTuningParams()
            }
        }
    }
    
    public var processTau2: Double? {
        didSet {
            print()
            print("tau2 set \(String(describing: processTau2))")
            if let value = processTau2 {
                process.tau2 = value
                tuner.processTau2 = value
                calcTuningParams()
            }
        }
    }
    
    public var processDeadtime: Double? {
        didSet {
            if let value = processDeadtime {
                process.deadtime = value
                tuner.processDeadTime = value
                calcTuningParams()
            }
        }
    }
    
    /// Allows user to change controller gain (PID Lab)
    public var controllerGain: Double? {
        didSet {
            if let value = controllerGain {
                pid.gain = value
            }
        }
    }
    
    /// Allows user to change integral time (PID Lab)
    public var integralTime: Double? {
        didSet {
            if let value = integralTime {
                pid.integralTime = value
            }
        }
    }
    
    /// Allows user to change derivative time (PID Lab)
    public var derivativeTime: Double? {
        didSet {
            if let value = derivativeTime {
                pid.derivativeTime = value
            }
        }
    }
    
    public var execFreq: Double = 1.0 {
        didSet {
            process.execFreq = execFreq
            pid.execFreq = execFreq
        }
    }
    

    public var pidForm: PIDForm = .Parallel {
        didSet {
            pid.pidForm = pidForm
            tuner.pidForm = pidForm
            calcTuningParams()
        }
    }
    
    public var pidMode: PIDMode = .PID {
        didSet {
            print("sim pidMode \(pidMode.rawValue)")
            pid.pidMode = pidMode
            tuner.pidMode = pidMode
            calcTuningParams()
        }
    }
    
    
    public var ready: Bool {
        get {
            print("simulation ready...")
            print("tuner controllerGain \(String(describing: tuner.controllerGain))")
            print("tuner integralTime \(String(describing: tuner.integralTime))")
            print("pid controllerGain \(pid.gain)")
            print("pid integralTime \(pid.integralTime)")
            return process.ready && tuner.controllerGain != nil && tuner.integralTime != nil
        }
    }
    
    public var tauPlotMultiplier = 9.0
    public var deadtimeMultiplier = 2.0
    
    public var plotTime = 30.0
    
    func calcTuningParams() {
        print("calc tuning from simulator...")
        tuner.processGainScaled = process.gainScaled
        tuner.calcTuningParams()
        print("setting pid gain \(String(describing: tuner.controllerGain))")
        if let gain = tuner.controllerGain {
            pid.gain = gain
        }
        print("setting pid Ti \(String(describing: tuner.integralTime))")
        if let time = tuner.integralTime {
            pid.integralTime = time
        }
        print("setting pid Td \(String(describing: tuner.derivativeTime))")
        if let time = tuner.derivativeTime {
            print("setting Td to \(time)")
            pid.derivativeTime = time
        } else {
            print("setting Td to 0.0")
            pid.derivativeTime = 0.0
        }
    }
    
    public func calculatePlotTime() {
        switch processType {
        case .FO:
            if let tau1 = process.tau1, let deadtime = process.deadtime {
                plotTime =  tauPlotMultiplier * tau1 + deadtime
            } else {
                plotTime = 40.0
            }
        case .SO:
            if let tau1 = process.tau1, let tau2 = process.tau2, let deadtime = process.deadtime {
                plotTime =  tauPlotMultiplier * tau1 + tau2 + deadtime
            } else {
                plotTime = 45.0
            }
        case .I:
            if let deadtime = process.deadtime {
                plotTime =  60.0 * deadtime
                if plotTime < 60.0 {
                    plotTime = 60.0
                }
            }
        }
    }
        
    public var numberPlotPoints = 100
    
    /// Makes setpoint step and runs simulation
    /// - Parameter step: step size as a fraction or range (0.05 = 5%)
    public func stepSetpoint(step: Double) {
        print()
        print("Stepping Simulator...")
        print("step size \(step)")
        if !ready {
            print("loop simulator is not ready!")
            return
        }
        getPlotTime()
        let numberIterations = Int(plotTime * 60.0 / execFreq)
        var iterationsToSkip = numberIterations / numberPlotPoints
        if iterationsToSkip < 1 {
            iterationsToSkip = 0
        }
        print("plotTime \(plotTime)")
        print("numberIterations \(numberIterations)")
        print("iterationsToSkip \(iterationsToSkip)")
        
        
        spData.removeAll()
        mvData.removeAll()
        cvData.removeAll()
        sp = 0.5
        cv = 0.5
        mv = 0.5
        spData.append((0.0, sp))
        cvData.append((0.0, cv))
        mvData.append((0.0, mv))
        pid.setpoint = step
        
        stepLoop: for t in 0 ... Int(numberIterations) {
            sp += pid.setpoint // * (cvHiRange! - cvLoRange!)
            pid.input = process.output
            process.input = pid.output
            mv += pid.output  //  * (mvHiRange! - mvLoRange!)
            cv += process.output  // * (cvHiRange! - cvLoRange!)
            func makePoints() {
                //print("pid setpoint \(pid.setpoint)")
                let pvPoint = (Double(t) * execFreq / 60.0, cv)
                let spPoint = (Double(t) * execFreq / 60.0, sp)
                let mvPoint = (Double(t) * execFreq / 60.0, mv)
                cvData.append(pvPoint)
                spData.append(spPoint)
                mvData.append(mvPoint)
                print("t \(spPoint.0)  sp \(spPoint.1)  cv \(pvPoint.1)  mv \(mvPoint.1)")
            }
            if iterationsToSkip == 0 {
                makePoints()
            } else {
                if t == 0 {
                    makePoints()
                } else if t % iterationsToSkip == 0 {
                    makePoints()
                } else if t == numberIterations {
                    makePoints()
                }
            }
        }
        cvDataEU.removeAll()
        spDataEU.removeAll()
        mvDataEU.removeAll()
        cvDataPercent.removeAll()
        spDataPercent.removeAll()
        mvDataPercent.removeAll()

        plotCVPointLoop: for point in cvData {
            cvDataEU.append((point.x, point.y * (cvHiRange! - cvLoRange!)))
            cvDataPercent.append((point.x, point.y * 100.0))
        }
        for point in spData {
            spDataEU.append((point.x, point.y * (cvHiRange! - cvLoRange!)))
            spDataPercent.append((point.x, point.y * 100.0))
        }
        for point in mvData {
            mvDataEU.append((point.x, point.y * (mvHiRange! - mvLoRange!)))
            mvDataPercent.append((point.x, point.y * 100.0))
        }
    }
    
    func getPlotTime() {
        // print()
        // print("getPlotTime()")
        switch processType {
        case .FO:
            print()
            print("first order: !!!!!!!!!!!!!!!!!!!!!!!!!!")
            if let t1 = processTau1, let dt = processDeadtime {
                // print("t1 \(t1)  dt \(dt)")
                let xRange = t1 * 9.0 + dt // in minutes
                print("plot x range \(xRange)")
                // Get nice xRange from plot
                // print("get x axis 1")
                // let axis1 = cVPlot.getXAxis(low: 0.0, high: xRange) // use same range for simulation as would for plot
                let niceAxis = AxisSpacing(min: 0.0, max: xRange)
                print("FO x axis1 to \(niceAxis.newMax)")
                
                // print("get x axis 2")
                // let axis2 = cVPlot.getXAxis(low: 0.0, high: axis1.to)
                plotTime = niceAxis.newMax
                // print("Plot and Simulation x range \(axis1.to)")
                print()
            }
        case .SO:
            if let t1 = processTau1, let t2 = processTau2, let dt = processDeadtime {
                let xRange = t1 * 9.0 + t2 * 5 + dt
                // let axis1 = cVPlot.getXAxis(low: 0.0, high: xRange) // use same range for simulation as would for plot
                let niceAxis = AxisSpacing(min: 0.0, max: xRange)
                // let axis = cVPlot.getXAxis(low: 0, high: t1 * 9.0 + 2 * t2 + dt)
                // print("SO axis to \(axis1.to)")
                plotTime = niceAxis.newMax
            }
        case .I:
            if let dt = processDeadtime {
                let xRange = max(60, 80.0 * dt)
                //let axis1 = cVPlot.getXAxis(low: 0.0, high: xRange) // use same range for simulation as would for plot
                let niceAxis = AxisSpacing(min: 0.0, max: xRange)
                // print("I axis to \(axis1.to)")
                //let axis2 = cVPlot.getXAxis(low: 0.0, high: axis1.to)
                // simulation.plotTime =  axis.to - execFreq * 1.0/60.0
                // simulation.plotTime = axis.to - execFreq * 1.0/60.0
                plotTime = niceAxis.newMax
            }
        }
    }

    
    
    public func initialize() {
        pid.initialize()
        process.initialize()
        cv = 0.5
        sp = 0.5
        mv = 0.5
    }
    
    public init() {
    }
}
