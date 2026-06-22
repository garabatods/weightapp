import SwiftUI

enum AppTheme {
    static let background = Color(red: 0.988, green: 0.985, blue: 0.976)
    static let card = Color.white
    static let cardTint = Color(red: 0.972, green: 0.986, blue: 0.972)
    static let primary = Color(red: 0.000, green: 0.560, blue: 0.350)
    static let primaryDark = Color(red: 0.080, green: 0.145, blue: 0.165)
    static let mint = Color(red: 0.895, green: 0.960, blue: 0.885)
    static let text = Color(red: 0.080, green: 0.145, blue: 0.165)
    static let secondaryText = Color(red: 0.390, green: 0.455, blue: 0.520)
    static let divider = Color(red: 0.875, green: 0.895, blue: 0.880)
    static let track = Color(red: 0.920, green: 0.925, blue: 0.915)
    static let neutralIcon = Color(red: 0.320, green: 0.395, blue: 0.445)
    static let neutralIconBackground = Color(red: 0.936, green: 0.942, blue: 0.932)
    static let successSoft = Color(red: 0.902, green: 0.970, blue: 0.910)
    static let yellow = Color(red: 1.000, green: 0.830, blue: 0.270)
    static let yellowSoft = Color(red: 1.000, green: 0.952, blue: 0.780)
    static let grayDay = Color(red: 0.885, green: 0.890, blue: 0.895)
    static let blue = Color(red: 0.190, green: 0.415, blue: 0.850)
    static let blueSoft = Color(red: 0.895, green: 0.930, blue: 1.000)
    static let indigo = Color(red: 0.285, green: 0.365, blue: 0.860)
    static let indigoSoft = Color(red: 0.900, green: 0.920, blue: 1.000)
    static let teal = Color(red: 0.000, green: 0.500, blue: 0.585)
    static let tealSoft = Color(red: 0.860, green: 0.960, blue: 0.960)
    static let lavender = Color(red: 0.560, green: 0.390, blue: 0.850)
    static let lavenderSoft = Color(red: 0.930, green: 0.900, blue: 1.000)
    static let orange = Color(red: 0.930, green: 0.365, blue: 0.105)
    static let orangeSoft = Color(red: 1.000, green: 0.925, blue: 0.760)
    static let destructive = Color(red: 0.760, green: 0.120, blue: 0.120)
    static let destructiveSoft = Color(red: 1.000, green: 0.945, blue: 0.945)
}

enum IconTone {
    case primary
    case neutral
    case success
    case warning
    case info
    case movement
    case measurement
    case flex
    case destructive

    var foreground: Color {
        switch self {
        case .primary, .success:
            AppTheme.primary
        case .neutral:
            AppTheme.neutralIcon
        case .warning:
            AppTheme.orange
        case .info:
            AppTheme.blue
        case .movement:
            AppTheme.indigo
        case .measurement:
            AppTheme.teal
        case .flex:
            AppTheme.lavender
        case .destructive:
            AppTheme.destructive
        }
    }

    var background: Color {
        switch self {
        case .primary:
            AppTheme.mint
        case .neutral:
            AppTheme.neutralIconBackground
        case .success:
            AppTheme.successSoft
        case .warning:
            AppTheme.orangeSoft
        case .info:
            AppTheme.blueSoft
        case .movement:
            AppTheme.indigoSoft
        case .measurement:
            AppTheme.tealSoft
        case .flex:
            AppTheme.lavenderSoft
        case .destructive:
            AppTheme.destructiveSoft
        }
    }
}

enum AppTypography {
    static let mainTitle = Font.system(size: 40, weight: .heavy, design: .rounded)
    static let mainSubtitle = Font.system(size: 19, weight: .medium, design: .rounded)
    static let secondaryTitle = Font.system(size: 30, weight: .bold, design: .rounded)
    static let secondarySubtitle = Font.system(size: 16, weight: .medium, design: .rounded)
    static let featureCardTitle = Font.system(size: 22, weight: .bold, design: .rounded)
    static let sectionTitle = Font.system(size: 21, weight: .bold, design: .rounded)
    static let cardHeaderTitle = Font.system(size: 19, weight: .bold, design: .rounded)
    static let compactCardTitle = Font.system(size: 18, weight: .bold, design: .rounded)
    static let cardTitle = Font.system(size: 18, weight: .bold, design: .rounded)
    static let rowTitle = Font.system(size: 16, weight: .semibold, design: .rounded)
    static let rowValue = Font.system(size: 17, weight: .bold, design: .rounded)
    static let body = Font.system(size: 15, weight: .medium, design: .rounded)
    static let caption = Font.system(size: 13, weight: .medium, design: .rounded)
    static let label = Font.system(size: 12, weight: .bold, design: .rounded)
    static let primaryAction = Font.system(size: 18, weight: .bold, design: .rounded)
}

enum AppTab: CaseIterable {
    case today
    case mealPlan
    case progress
    case goals
    case history

    var title: String {
        switch self {
        case .today: "Today"
        case .mealPlan: "Meal Plan"
        case .progress: "Progress"
        case .goals: "Goals"
        case .history: "History"
        }
    }

    var icon: String {
        switch self {
        case .today: "house.fill"
        case .mealPlan: "fork.knife"
        case .progress: "chart.bar.fill"
        case .goals: "target"
        case .history: "clock"
        }
    }
}
