//
//  HandUtil.swift
//  Hand Detection
//
//  Created by Wei Liu on 2021/02/18.
//

import Foundation
import Vision

class HandUtil {
    static let order: [VNHumanHandPoseObservation.JointName] =
        [.thumbTip, .thumbIP, .thumbMP, .thumbCMC,
         .indexTip, .indexDIP, .indexPIP, .indexMCP,
         .middleTip, .middleDIP, .middlePIP, .middleMCP,
         .ringTip, .ringDIP, .ringPIP, .ringMCP,
         .littleTip, .littleDIP, .littlePIP, .littleMCP]

    static func sort(pnts: [VNHumanHandPoseObservation.JointName : VNRecognizedPoint]) -> [CGPoint] {
        var sorted = [CGPoint]()

        for k in order {
            if let v = pnts[k] {
                sorted.append(v.location)
            }
        }

        return sorted.reversed()
    }

}
