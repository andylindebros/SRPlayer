//
//  StringExtensions.swift
//  TestAVPlayer
//
//  Created by Andreas Linde on 2024-09-05.
//

import Foundation
import NiceToHave
import SwiftUI

extension String {
    var asColor: Color {
        Color(hexString: self)
    }
}
