import SwiftUI
import Combine
import Foundation

public final class ThemeManager: ObservableObject {

    public static let shared = ThemeManager()

    public struct Colors: Equatable {
        public var background: Color
        public var card: Color
        public var accent: Color
        public var textPrimary: Color
        public var textSecondary: Color
        public var success: Color
        public var warning: Color
        public var error: Color
        public var separator: Color
    }

    @Published public private(set) var colors: Colors = .init(
        background: Color.black,
        card: Color(white: 0.12),
        accent: .blue,
        textPrimary: .white,
        textSecondary: .gray,
        success: .green,
        warning: .yellow,
        error: .red,
        separator: Color.white.opacity(0.12)
    )

    public let icons = Icons()
    public let metrics = Metrics()

    public init() {}

    public func setAccent(_ newAccent: Color) {
        let c = colors
        colors = Colors(
            background: c.background,
            card: c.card,
            accent: newAccent,
            textPrimary: c.textPrimary,
            textSecondary: c.textSecondary,
            success: c.success,
            warning: c.warning,
            error: c.error,
            separator: c.separator
        )
    }

    public struct Icons {
            public let interval = "timer"
            public let reps = "number.circle"
            public let cardio = "figure.run"
            public let breath = "wind"
            public let exercises = "dumbbell.fill"
            public let settings = "gearshape.fill"
            public let goals = "target"
            public let edit = "square.and.pencil"
            public let add = "plus.circle.fill"
            public let delete = "trash"
            public let check = "checkmark.circle.fill"
        }


    public struct Metrics {
        public let spacingS: CGFloat = 6
        public let spacingM: CGFloat = 12
        public let spacingL: CGFloat = 20
        public let cornerS: CGFloat = 10
        public let cornerL: CGFloat = 16
        public let ringThickness: CGFloat = 10
    }
}
