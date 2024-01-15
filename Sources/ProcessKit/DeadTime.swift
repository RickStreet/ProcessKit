//
//  VelocityDeadTime.swift
//  TunerSimulator
//
//  Created by Rick Street on 6/23/16.
//  Copyright © 2016 Rick Street. All rights reserved.
//

import Foundation


public class DeadTime {
    
    public var execFreq: Double = 1.0 // Process Exicution Frequency in Seconds
    var ready: Bool = false
    fileprivate var firstRun: Bool = true // first cycle
    
    
    // when set deadtime in minutes, set up array with deadtime elemements
    public var deadtime: Double = 0.0 {
        didSet {
            deadtimeArrayInit()
        }
    }
    
    public var input: Double = 0.0{
        didSet {
            output = valueOut(input)
        }
    }
    
    public var output = 0.0
    
    func valueOut(_ valueIn: Double) -> (Double) {
        if firstRun {
            deadtimeArraySetValues(0.0)
            firstRun = false
        }
        let dt = deadtimeCalc(valueIn)
        // print("delayed MV \(dt)   deadtime \(deadtime)")
        return dt
    }
    
    
    // var valueInLast: Double  // after deadtime delay
    
    var deadtimeArray = [Double]()
    
    
    func deadtimeArrayInit() {
        let size = Int(deadtime * (60 / execFreq)) // to execution frequency
        print("deadtime size \(size)")
        
        deadtimeArray = [Double](repeating: 0.0, count: size)
        firstRun = true
        ready = true
    }
    
    func deadtimeArraySetValues(_ value: Double) {
        print("deadtime init to \(value)")
        for index in 0 ..< deadtimeArray.count {
            deadtimeArray[index] = value
            firstRun = false
        }
    }
    
    func deadtimeCalc(_ value: Double) -> Double {
        let count = deadtimeArray.count
        if count > 0 {
            let returnValue = deadtimeArray[count - 1]
            for i in (1 ..< count).reversed() {
                deadtimeArray[i] = deadtimeArray[i - 1]
            }
            deadtimeArray[0] = value
            // print("delayed value \(returnValue)")
            return returnValue
        } else {
            return value
        }
    }
    
    public func initialize() {
        firstRun = true
    }
    
    public init() {
        // Empty ConfigParam
    }
}
