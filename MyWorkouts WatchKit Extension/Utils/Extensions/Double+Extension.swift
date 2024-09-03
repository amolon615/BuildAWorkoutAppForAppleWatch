//
//  Double+Extension.swift
//  MyWorkouts WatchKit App
//
//  Created by amolonus on 03/09/2024.
//  Copyright © 2024 Apple. All rights reserved.
//

import Foundation

extension Double {
    func formattedPace() -> String {
        let minutes = Int(self)
        let seconds = Int((self - Double(minutes)) * 60)
        return "\(minutes)'\(String(format: "%02d", seconds))\""
    }
}
