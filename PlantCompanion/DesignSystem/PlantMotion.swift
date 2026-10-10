import SwiftUI

/// One restrained motion language, with a static presentation when Reduce Motion is on.
enum PlantMotion {
    static func animation(reduceMotion: Bool) -> Animation? {
        reduceMotion ? nil : .spring(duration: 0.32, bounce: 0.14)
    }

    static func transition(reduceMotion: Bool) -> AnyTransition {
        reduceMotion ? .opacity : .opacity.combined(with: .offset(y: 10))
    }
}
