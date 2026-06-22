import SwiftUI
import UIKit

struct AppHeader: View {
    let title: String
    let subtitle: String
    var profileImageData: Data? = nil
    var onProfileTap: (() -> Void)? = nil

    var body: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .firstTextBaseline, spacing: 10) {
                    Text(title)
                        .font(AppTypography.mainTitle)
                        .foregroundStyle(AppTheme.primaryDark)
                        .lineLimit(1)
                        .minimumScaleFactor(0.70)
                        .layoutPriority(1)

                    Image(systemName: "leaf.fill")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(AppTheme.primary)
                        .padding(.bottom, 6)
                }

                Text(subtitle)
                    .font(AppTypography.mainSubtitle)
                    .foregroundStyle(AppTheme.secondaryText)
                    .lineLimit(2)
                    .minimumScaleFactor(0.85)
            }

            Spacer(minLength: 16)

            if let onProfileTap {
                Button(action: onProfileTap) {
                    ProfileAvatar(imageData: profileImageData, size: 56)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Profile and settings")
            } else {
                ProfileAvatar(imageData: profileImageData, size: 56)
                    .accessibilityHidden(true)
            }
        }
        .padding(.top, 18)
    }
}

struct ProfileAvatar: View {
    let imageData: Data?
    var size: CGFloat = 56

    var body: some View {
        ZStack {
            if let imageData, let image = UIImage(data: imageData) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                Circle()
                    .fill(AppTheme.successSoft)
                Image(systemName: "leaf.circle.fill")
                    .font(.system(size: size * 0.57, weight: .semibold))
                    .foregroundStyle(AppTheme.primary, AppTheme.mint)
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
        .overlay(Circle().stroke(AppTheme.divider, lineWidth: 1))
    }
}

struct SecondaryHeader: View {
    let title: String
    let subtitle: String
    let onBack: () -> Void

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            Button(action: onBack) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(AppTheme.primary)
                    .frame(width: 42, height: 42)
                    .background(Circle().fill(AppTheme.mint.opacity(0.78)))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Back")

            VStack(alignment: .leading, spacing: 3) {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(title)
                        .font(AppTypography.secondaryTitle)
                        .foregroundStyle(AppTheme.primaryDark)
                        .lineLimit(1)
                        .minimumScaleFactor(0.78)
                    Image(systemName: "leaf.fill")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(AppTheme.primary)
                }

                Text(subtitle)
                    .font(AppTypography.secondarySubtitle)
                    .foregroundStyle(AppTheme.secondaryText)
                    .lineLimit(1)
                    .minimumScaleFactor(0.82)
            }
            .layoutPriority(1)

            Spacer(minLength: 0)
        }
        .padding(.top, 12)
    }
}

struct AppCard<Content: View>: View {
    var tint: Bool = false
    var padding: CGFloat = 16
    @ViewBuilder let content: Content

    var body: some View {
        content
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(tint ? AppTheme.cardTint : AppTheme.card)
                    .shadow(color: .black.opacity(0.045), radius: 12, y: 5)
                    .overlay(
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .stroke(tint ? AppTheme.primary.opacity(0.10) : AppTheme.divider, lineWidth: 1)
                    )
            )
    }
}

struct IconBubble: View {
    let symbol: String
    var tone: IconTone = .neutral
    var color: Color? = nil
    var background: Color? = nil
    var size: CGFloat = 50

    var body: some View {
        ZStack {
            Circle().fill(background ?? tone.background)
            Image(systemName: symbol)
                .font(.system(size: size * 0.44, weight: .bold))
                .foregroundStyle(color ?? tone.foreground)
        }
        .frame(width: size, height: size)
    }
}

struct PrimaryButton: View {
    let title: String
    var systemImage: String?
    var isEnabled = true
    let action: () -> Void

    var body: some View {
        Button {
            guard isEnabled else { return }
            action()
        } label: {
            HStack(spacing: 12) {
                if let systemImage {
                    Image(systemName: systemImage)
                        .font(.system(size: 18, weight: .bold))
                }
                Text(title)
                    .font(AppTypography.primaryAction)
                    .lineLimit(1)
                    .minimumScaleFactor(0.82)
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(minHeight: 58)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(isEnabled ? AppTheme.primary : AppTheme.primary.opacity(0.34))
                    .shadow(color: isEnabled ? AppTheme.primary.opacity(0.22) : .clear, radius: 14, y: 7)
            )
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
    }
}

struct FloatingWeightButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: "scalemass")
                    .font(.system(size: 17, weight: .bold))
                Text("Log weight")
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .lineLimit(1)
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 14)
            .frame(height: 48)
            .background(
                Capsule()
                    .fill(AppTheme.primary)
                    .shadow(color: AppTheme.primary.opacity(0.24), radius: 14, y: 7)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Log weight")
    }
}

struct StatCard: View {
    let progress: UserProgress
    var showIcons = false

    var body: some View {
        AppCard {
            HStack(spacing: 0) {
                MetricColumn(
                    icon: showIcons ? "scalemass" : nil,
                    value: String(format: "%.1f", progress.currentWeight),
                    unit: progress.unit,
                    label: "Current weight",
                    valueColor: AppTheme.primary,
                    iconTone: .info
                )
                VerticalDivider()
                MetricColumn(
                    icon: showIcons ? "arrow.down.forward" : nil,
                    value: String(format: "%.1f", progress.totalLost),
                    unit: progress.unit,
                    label: "Total lost",
                    iconTone: .success
                )
                VerticalDivider()
                MetricColumn(
                    icon: showIcons ? "target" : nil,
                    value: String(format: "%.1f", progress.goalWeight),
                    unit: progress.unit,
                    label: "Goal weight",
                    iconTone: .primary
                )
            }
        }
    }
}

struct MetricColumn: View {
    var icon: String?
    let value: String
    let unit: String
    let label: String
    var valueColor: Color = AppTheme.text
    var iconTone: IconTone = .neutral

    var body: some View {
        VStack(spacing: 8) {
            if let icon {
                IconBubble(symbol: icon, tone: iconTone)
                    .frame(width: 44, height: 44)
                    .padding(.bottom, 4)
            }
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(value)
                    .font(.system(size: 24, weight: .heavy, design: .rounded))
                    .minimumScaleFactor(0.60)
                    .allowsTightening(true)
                Text(unit)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
            }
            .foregroundStyle(valueColor)
            .lineLimit(1)
            .minimumScaleFactor(0.60)

            Text(label)
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundStyle(AppTheme.secondaryText)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.78)
        }
        .frame(maxWidth: .infinity)
    }
}

struct VerticalDivider: View {
    var height: CGFloat = 48

    var body: some View {
        Rectangle()
            .fill(AppTheme.divider)
            .frame(width: 1, height: height)
            .padding(.horizontal, 6)
    }
}

struct ProgressBar: View {
    let value: Double
    let total: Double
    var segments: Int = 0

    private var fraction: Double {
        guard total > 0 else { return 0 }
        return min(max(value / total, 0), 1)
    }

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(AppTheme.track)

                Capsule()
                    .fill(AppTheme.primary)
                    .frame(width: proxy.size.width * fraction)

                if segments > 1 {
                    HStack(spacing: 0) {
                        ForEach(1..<segments, id: \.self) { _ in
                            Spacer()
                            Rectangle()
                                .fill(Color.white.opacity(0.9))
                                .frame(width: 2)
                            Spacer()
                        }
                    }
                    .clipShape(Capsule())
                }
            }
        }
        .frame(height: 9)
    }
}

struct CheckInCard: View {
    let hasCheckIn: Bool
    var title = "Today’s check-in"
    let statusText: String
    var helperText: String?
    var actionTitle = "Start check-in"
    var iconSymbol = "target"
    var iconTone: IconTone = .primary
    let onStart: () -> Void

    var body: some View {
        AppCard(tint: true) {
            if hasCheckIn {
                completedLayout
            } else {
                if needsStackedActionLayout {
                    pendingStackedLayout
                } else {
                    pendingLayout
                }
            }
        }
    }

    private var needsStackedActionLayout: Bool {
        statusText.count > 44 || title.count > 28
    }

    private var pendingLayout: some View {
        HStack(spacing: 10) {
            pendingIcon
            pendingText
                .layoutPriority(1)
            Spacer(minLength: 6)
            startButton(width: actionTitle == "Check in" ? 112 : 136)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var pendingStackedLayout: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                pendingIcon
                pendingText
                    .layoutPriority(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            HStack {
                Spacer(minLength: 54)
                startButton(width: 178)
                    .fixedSize(horizontal: true, vertical: false)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var completedLayout: some View {
        HStack(spacing: 18) {
            IconBubble(symbol: "checkmark.circle.fill", tone: .success)
            completedText
            .layoutPriority(1)

            Spacer(minLength: 10)
            editButton
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var pendingIcon: some View {
        ZStack {
            Circle()
                .fill(iconTone.background)
            Image(systemName: iconSymbol)
                .font(.system(size: 19, weight: .bold))
                .foregroundStyle(iconTone.foreground)
        }
        .frame(width: 42, height: 42)
    }

    private var pendingText: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(AppTypography.compactCardTitle)
                .foregroundStyle(AppTheme.text)
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            Text(statusText)
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .foregroundStyle(AppTheme.secondaryText)
                .lineLimit(2)
                .minimumScaleFactor(0.74)
                .fixedSize(horizontal: false, vertical: true)

            if let helperText {
                Text(helperText)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(AppTheme.lavender)
                    .lineLimit(2)
                    .minimumScaleFactor(0.78)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var completedText: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(AppTypography.cardHeaderTitle)
                .foregroundStyle(AppTheme.text)
                .lineLimit(1)
                .minimumScaleFactor(0.82)
            Text(statusText)
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .foregroundStyle(AppTheme.primary)
                .lineLimit(2)
                .minimumScaleFactor(0.82)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func startButton(width: CGFloat) -> some View {
        Button(action: onStart) {
            HStack(spacing: 8) {
                Text(actionTitle)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .heavy))
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 10)
            .frame(width: width, height: 42)
            .background(
                RoundedRectangle(cornerRadius: 15, style: .continuous)
                    .fill(AppTheme.primary)
            )
        }
        .buttonStyle(.plain)
    }

    private var editButton: some View {
        Button(action: onStart) {
            Text("Edit")
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundStyle(AppTheme.primary)
                .lineLimit(1)
                .padding(.horizontal, 18)
                .frame(minWidth: 88, minHeight: 42)
                .background(
                    Capsule()
                        .fill(.white)
                        .overlay(Capsule().stroke(AppTheme.primary.opacity(0.28), lineWidth: 1))
                )
        }
        .buttonStyle(.plain)
        .fixedSize(horizontal: true, vertical: false)
        .accessibilityLabel("Edit today’s check-in")
    }
}

struct GoalCard: View {
    let goal: Goal
    var mode: GoalCardMode
    var density: GoalCardDensity = .regular
    var isCompleted = false
    var onEdit: (() -> Void)?
    var onDelete: (() -> Void)?

    var body: some View {
        AppCard(padding: density.cardPadding) {
            HStack(alignment: .top, spacing: density.outerSpacing) {
                IconBubble(symbol: goalIcon, tone: goalIconTone, size: density.iconSize)

                VStack(alignment: .leading, spacing: density.contentSpacing) {
                    HStack(alignment: .top, spacing: density.headerSpacing) {
                        Text(goal.title)
                            .font(.system(size: density.titleSize, weight: .bold, design: .rounded))
                            .foregroundStyle(AppTheme.text)
                            .lineLimit(2)
                            .minimumScaleFactor(0.82)
                            .layoutPriority(1)
                        Spacer(minLength: 8)
                        if onEdit != nil || onDelete != nil {
                            Menu {
                                if let onEdit {
                                    Button("Edit goal", action: onEdit)
                                }
                                if let onDelete {
                                    Button("Delete goal", role: .destructive, action: onDelete)
                                }
                            } label: {
                                Image(systemName: "ellipsis")
                                    .font(.system(size: density.menuIconSize, weight: .bold))
                                    .foregroundStyle(AppTheme.secondaryText)
                                    .frame(width: density.actionSize, height: density.actionSize)
                                    .background(Circle().fill(AppTheme.mint.opacity(0.55)))
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    switch mode {
                    case .count(let current, let target, let label):
                        countGoalContent(current: current, target: target, label: label)
                    case .weight(let current, let toGo, let target, let unit, let progressValue, let totalValue):
                        VStack(spacing: density.metricSpacing) {
                            HStack(spacing: 0) {
                                WeightMetric(
                                    value: String(format: "%.1f", current),
                                    unit: unit,
                                    label: "Current",
                                    valueSize: density.weightValueSize,
                                    unitSize: density.weightUnitSize,
                                    labelSize: density.weightLabelSize,
                                    spacing: density.weightMetricSpacing
                                )
                                VerticalDivider(height: density.dividerHeight)
                                WeightMetric(
                                    value: String(format: "%.1f", toGo),
                                    unit: unit,
                                    label: "To go",
                                    valueSize: density.weightValueSize,
                                    unitSize: density.weightUnitSize,
                                    labelSize: density.weightLabelSize,
                                    spacing: density.weightMetricSpacing
                                )
                                VerticalDivider(height: density.dividerHeight)
                                WeightMetric(
                                    value: String(format: "%.1f", target),
                                    unit: unit,
                                    label: "Goal",
                                    valueSize: density.weightValueSize,
                                    unitSize: density.weightUnitSize,
                                    labelSize: density.weightLabelSize,
                                    spacing: density.weightMetricSpacing
                                )
                            }
                            ProgressBar(value: progressValue, total: totalValue)
                        }
                    case .completed:
                        Text(goal.completedAt.map { "Completed on \(Self.completedDateFormatter.string(from: $0))" } ?? "Completed")
                            .font(.system(size: 16, weight: .medium, design: .rounded))
                            .foregroundStyle(AppTheme.secondaryText)
                    }
                }
            }
        }
    }

    private func countGoalContent(current: Int, target: Int, label: String?) -> some View {
        VStack(alignment: .leading, spacing: density.metricSpacing) {
            if density == .compact, let label {
                ViewThatFits(in: .horizontal) {
                    HStack(alignment: .firstTextBaseline, spacing: 10) {
                        countValue(current: current, target: target)
                        Text(label)
                            .font(.system(size: density.helperSize, weight: .medium, design: .rounded))
                            .foregroundStyle(AppTheme.secondaryText)
                            .lineLimit(1)
                            .minimumScaleFactor(0.78)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        countValue(current: current, target: target)
                        Text(label)
                            .font(.system(size: density.helperSize, weight: .medium, design: .rounded))
                            .foregroundStyle(AppTheme.secondaryText)
                            .lineLimit(1)
                            .minimumScaleFactor(0.78)
                    }
                }
            } else {
                countValue(current: current, target: target)
                if let label {
                    Text(label)
                        .font(.system(size: density.helperSize, weight: .medium, design: .rounded))
                        .foregroundStyle(AppTheme.secondaryText)
                        .lineLimit(1)
                        .minimumScaleFactor(0.78)
                }
            }

            ProgressBar(value: Double(current), total: Double(target), segments: target)
        }
    }

    private func countValue(current: Int, target: Int) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: density.countSpacing) {
            Text("\(current)")
                .font(.system(size: density.countCurrentSize, weight: .heavy, design: .rounded))
                .foregroundStyle(AppTheme.primary)
            Text("/ \(target)")
                .font(.system(size: density.countTargetSize, weight: .bold, design: .rounded))
                .foregroundStyle(AppTheme.secondaryText)
        }
    }

    private var isGoalCompleted: Bool {
        mode.isCompleted || isCompleted
    }

    private static let completedDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter
    }()

    private var goalIcon: String {
        if isGoalCompleted {
            return "checkmark"
        }

        switch goal.type {
        case .dietDays:
            return "flag.fill"
        case .weightTarget:
            return "scalemass"
        case .movementDays:
            return "shoeprints.fill"
        case .weighIns:
            return "calendar.badge.checkmark"
        }
    }

    private var goalIconTone: IconTone {
        if isGoalCompleted {
            return .success
        }

        switch goal.type {
        case .dietDays:
            return .primary
        case .movementDays:
            return .movement
        case .weightTarget:
            return .info
        case .weighIns:
            return .info
        }
    }
}

enum GoalCardDensity: Equatable {
    case regular
    case compact

    var cardPadding: CGFloat {
        switch self {
        case .regular: 16
        case .compact: 14
        }
    }

    var outerSpacing: CGFloat {
        switch self {
        case .regular: 18
        case .compact: 12
        }
    }

    var contentSpacing: CGFloat {
        switch self {
        case .regular: 14
        case .compact: 9
        }
    }

    var headerSpacing: CGFloat {
        switch self {
        case .regular: 12
        case .compact: 8
        }
    }

    var iconSize: CGFloat {
        switch self {
        case .regular: 50
        case .compact: 42
        }
    }

    var actionSize: CGFloat {
        switch self {
        case .regular: 46
        case .compact: 38
        }
    }

    var menuIconSize: CGFloat {
        switch self {
        case .regular: 18
        case .compact: 16
        }
    }

    var titleSize: CGFloat {
        switch self {
        case .regular: 21
        case .compact: 18
        }
    }

    var metricSpacing: CGFloat {
        switch self {
        case .regular: 12
        case .compact: 8
        }
    }

    var countSpacing: CGFloat {
        switch self {
        case .regular: 7
        case .compact: 5
        }
    }

    var countCurrentSize: CGFloat {
        switch self {
        case .regular: 37
        case .compact: 29
        }
    }

    var countTargetSize: CGFloat {
        switch self {
        case .regular: 31
        case .compact: 24
        }
    }

    var helperSize: CGFloat {
        switch self {
        case .regular: 17
        case .compact: 14
        }
    }

    var weightValueSize: CGFloat {
        switch self {
        case .regular: 25
        case .compact: 21
        }
    }

    var weightUnitSize: CGFloat {
        switch self {
        case .regular: 14
        case .compact: 12
        }
    }

    var weightLabelSize: CGFloat {
        switch self {
        case .regular: 14
        case .compact: 12
        }
    }

    var weightMetricSpacing: CGFloat {
        switch self {
        case .regular: 6
        case .compact: 4
        }
    }

    var dividerHeight: CGFloat {
        switch self {
        case .regular: 48
        case .compact: 38
        }
    }
}

enum GoalCardMode {
    case count(current: Int, target: Int, label: String?)
    case weight(current: Double, toGo: Double, goal: Double, unit: String, progressValue: Double, totalValue: Double)
    case completed

    var isCompleted: Bool {
        if case .completed = self {
            return true
        }
        return false
    }

    var icon: String {
        switch self {
        case .count:
            "checklist"
        case .weight:
            "scalemass"
        case .completed:
            "calendar.badge.checkmark"
        }
    }
}

struct WeightMetric: View {
    let value: String
    let unit: String
    let label: String
    var valueColor: Color = AppTheme.text
    var valueSize: CGFloat = 25
    var unitSize: CGFloat = 14
    var labelSize: CGFloat = 14
    var spacing: CGFloat = 6

    var body: some View {
        VStack(spacing: spacing) {
            HStack(alignment: .firstTextBaseline, spacing: 3) {
                Text(value)
                    .font(.system(size: valueSize, weight: .heavy, design: .rounded))
                Text(unit)
                    .font(.system(size: unitSize, weight: .semibold, design: .rounded))
            }
            .foregroundStyle(valueColor)
            .lineLimit(1)
            .minimumScaleFactor(0.78)
            Text(label)
                .font(.system(size: labelSize, weight: .medium, design: .rounded))
                .foregroundStyle(AppTheme.secondaryText)
        }
        .frame(maxWidth: .infinity)
    }
}

struct CalendarMonth: View {
    let title: String
    let days: [CalendarDay]
    var onPrevious: () -> Void = {}
    var onNext: () -> Void = {}

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 10), count: 7)
    private let weekdays = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]

    var body: some View {
        AppCard {
            VStack(spacing: 20) {
                HStack {
                    CalendarNavButton(symbol: "chevron.left", action: onPrevious)
                    Spacer()
                    Text(title)
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(AppTheme.text)
                    Spacer()
                    CalendarNavButton(symbol: "chevron.right", action: onNext)
                }

                LazyVGrid(columns: columns, spacing: 0) {
                    ForEach(weekdays, id: \.self) { weekday in
                        Text(weekday)
                            .font(.system(size: 16, weight: .medium, design: .rounded))
                            .foregroundStyle(AppTheme.secondaryText)
                            .frame(height: 36)
                    }
                }

                Divider()
                    .foregroundStyle(AppTheme.divider)

                LazyVGrid(columns: columns, spacing: 14) {
                    ForEach(days) { day in
                        VStack(spacing: 4) {
                            Text("\(day.day)")
                                .font(.system(size: 19, weight: .bold, design: .rounded))
                                .foregroundStyle(dayTextColor(day))
                                .frame(width: 39, height: 39)
                                .background(dayBackground(day))
                                .clipShape(Circle())

                            Circle()
                                .fill(day.hasWeighIn ? AppTheme.blue : Color.clear)
                                .frame(width: 7, height: 7)
                        }
                        .frame(height: 50)
                    }
                }
            }
        }
    }

    private func dayTextColor(_ day: CalendarDay) -> Color {
        if !day.isCurrentMonth {
            return Color(red: 0.700, green: 0.720, blue: 0.750)
        }
        return switch day.status {
        case .onPlan: AppTheme.primary
        case .mostly: Color(red: 0.610, green: 0.430, blue: 0.000)
        case .missed: Color(red: 0.180, green: 0.230, blue: 0.280)
        case .flex: AppTheme.lavender
        case .none: day.isPlannedFlexDay ? AppTheme.lavender : AppTheme.secondaryText
        }
    }

    @ViewBuilder
    private func dayBackground(_ day: CalendarDay) -> some View {
        if !day.isCurrentMonth {
            Color.clear
        } else {
            switch day.status {
            case .onPlan: AppTheme.successSoft
            case .mostly: AppTheme.yellow.opacity(0.36)
            case .missed: AppTheme.grayDay
            case .flex: AppTheme.lavenderSoft
            case .none: day.isPlannedFlexDay ? AppTheme.lavenderSoft : Color.clear
            }
        }
    }
}

struct CalendarNavButton: View {
    let symbol: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(AppTheme.primary)
                .frame(width: 50, height: 50)
                .background(Circle().fill(AppTheme.successSoft))
        }
        .buttonStyle(.plain)
    }
}
