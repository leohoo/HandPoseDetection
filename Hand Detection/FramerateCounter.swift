//
//  FramerateCounter.swift
//  Hand Detection
//
//  Created by Wei Liu on 2021/02/09.
//

import Foundation

class FramerateCounter {
    var frames = [Date]()

    func addFrame() -> Int {
        frames.append(Date())

        if frames.count > 20 {
            frames.remove(at: 0)
        }

        if frames.count > 2 {
            let interval = frames.last?.timeIntervalSince(frames.first!)
            return Int(Double(frames.count - 1) / interval!)
        }
        return 0
    }
}

