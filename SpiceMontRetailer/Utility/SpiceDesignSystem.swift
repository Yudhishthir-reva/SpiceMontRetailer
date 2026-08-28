//
//  SpiceDesignSystem.swift
//  SpiceMontRetailer
//
//  Created on 24/08/26.
//

import SwiftUI

// MARK: - Spice Buttons

struct SpicePrimaryButton: View {
    let title: String
    var icon: String? = nil
    var height: CGFloat = 52
    var isEnabled: Bool = true
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.appFont(size: height > 40 ? 15 : 12, weight: .bold))
                }
                Text(title)
                    .font(.appFont(size: height > 40 ? 14.5 : 12, weight: .heavy))
                    .tracking(0.2)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: height)
            .background(isEnabled ? Color.spicePrimary : Color.spiceMuted.opacity(0.4))
            .cornerRadius(height > 40 ? 13 : 10)
        }
        .disabled(!isEnabled)
    }
}

struct SpiceOutlinedButton: View {
    let title: String
    var icon: String? = nil
    var color: Color = .spicePrimary
    var height: CGFloat = 52
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.appFont(size: height > 40 ? 14 : 11, weight: .bold))
                }
                Text(title)
                    .font(.appFont(size: height > 40 ? 14 : 12, weight: .heavy))
            }
            .foregroundColor(color)
            .frame(maxWidth: .infinity)
            .frame(height: height)
            .background(Color.white)
            .overlay(
                RoundedRectangle(cornerRadius: height > 40 ? 13 : 10)
                    .stroke(color, lineWidth: 1.5)
            )
            .cornerRadius(height > 40 ? 13 : 10)
        }
    }
}

struct SpiceGhostButton: View {
    let title: String
    var icon: String? = nil
    var height: CGFloat = 38
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.appFont(size: 11, weight: .semibold))
                }
                Text(title)
                    .font(.appFont(size: 12, weight: .bold))
            }
            .foregroundColor(Color.spiceInk)
            .frame(maxWidth: .infinity)
            .frame(height: height)
            .background(Color.white)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.spiceCardBorder, lineWidth: 1)
            )
            .cornerRadius(10)
        }
    }
}

// MARK: - Spice Card Container

struct SpiceCard<Content: View>: View {
    var backgroundColor: Color = .white
    var borderColor: Color = Color.spiceCardBorder
    var padding: CGFloat = 14
    var cornerRadius: CGFloat = 16
    let content: Content

    init(
        backgroundColor: Color = .white,
        borderColor: Color = Color.spiceCardBorder,
        padding: CGFloat = 14,
        cornerRadius: CGFloat = 16,
        @ViewBuilder content: () -> Content
    ) {
        self.backgroundColor = backgroundColor
        self.borderColor = borderColor
        self.padding = padding
        self.cornerRadius = cornerRadius
        self.content = content()
    }

    var body: some View {
        content
            .padding(padding)
            .background(backgroundColor)
            .cornerRadius(cornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(borderColor, lineWidth: 1)
            )
    }
}

// MARK: - Status Badge

struct SpiceStatusBadge: View {
    let status: String

    private var badgeColor: (bg: Color, text: Color) {
        let upper = status.uppercased().replacingOccurrences(of: "_", with: " ")
        switch upper {
        case "APPROVED", "DELIVERED", "CONFIRMED", "VERIFIED", "UPLOADED", "ACTIVE":
            return (Color.spicePrimaryLight, Color.spicePrimary)
        case "OUT FOR DELIVERY", "ORDER VALUE SLAB", "DISPATCHED", "PROCESSING":
            return (Color.spiceTransitLight, Color.spiceTransit)
        case "PENDING REVIEW", "PENDING_REVIEW", "LOW STOCK", "RETAILER SPECIFIC":
            return (Color.spiceAmberLight, Color.spiceAmber)
        case "REJECTED", "BLOCKED", "CANCELLED", "OUT OF STOCK":
            return (Color.spiceDueLight, Color.spiceDue)
        default:
            return (Color.spiceLightGray, Color.spiceMuted)
        }
    }

    var body: some View {
        Text(status.uppercased().replacingOccurrences(of: "_", with: " "))
            .font(.appFont(size: 10, weight: .bold))
            .tracking(0.3)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(badgeColor.bg)
            .foregroundColor(badgeColor.text)
            .cornerRadius(6)
    }
}

// MARK: - Top Navigation Bar

struct SpiceTopBar: View {
    let title: String
    var subtitle: String? = nil
    var showBack: Bool = true
    var onBack: (() -> Void)? = nil
    var trailingItem: AnyView? = nil

    var body: some View {
        HStack(spacing: 12) {
            if showBack {
                Button(action: { onBack?() }) {
                    Image(systemName: "chevron.left")
                        .font(.appFont(size: 16, weight: .bold))
                        .foregroundColor(Color.spiceInk)
                        .frame(width: 32, height: 32)
                }
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.appFont(size: 15, weight: .heavy))
                    .foregroundColor(Color.spiceInk)
                    .lineLimit(1)
                
                if let subtitle = subtitle, !subtitle.isEmpty {
                    Text(subtitle)
                        .font(.appFont(size: 10.5, weight: .medium))
                        .foregroundColor(Color.spiceMuted)
                        .lineLimit(1)
                }
            }

            Spacer()

            if let trailingItem = trailingItem {
                trailingItem
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color.white)
        .overlay(
            Divider().background(Color.spiceDivider),
            alignment: .bottom
        )
    }
}

// MARK: - Monospace Currency & Code Text

struct SpiceMonoText: View {
    let text: String
    var size: CGFloat = 13
    var weight: Font.Weight = .semibold
    var color: Color = Color.spiceInk

    var body: some View {
        Text(text)
            .font(.appFont(size: size, weight: weight, design: .monospaced))
            .foregroundColor(color)
    }
}

// MARK: - Key-Value Row

struct SpiceKVRow: View {
    let key: String
    let value: String
    var isMonoValue: Bool = false
    var valueColor: Color = Color.spiceInk

    var body: some View {
        HStack {
            Text(key)
                .font(.appFont(size: 12, weight: .semibold))
                .foregroundColor(Color.spiceMuted)
            Spacer()
            if isMonoValue {
                Text(value)
                    .font(.appFont(size: 12, weight: .semibold, design: .monospaced))
                    .foregroundColor(valueColor)
            } else {
                Text(value)
                    .font(.appFont(size: 12, weight: .semibold))
                    .foregroundColor(valueColor)
            }
        }
    }
}

// MARK: - Skeleton Shimmer

struct SpiceSkeletonBox: View {
    var width: CGFloat? = nil
    var height: CGFloat = 16
    var cornerRadius: CGFloat = 6

    @State private var isAnimating: Bool = false

    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .fill(Color.spiceLightGray)
            .frame(height: height)
            .frame(maxWidth: width ?? .infinity)
            .opacity(isAnimating ? 0.5 : 1.0)
            .animation(
                Animation.easeInOut(duration: 0.8).repeatForever(autoreverses: true),
                value: isAnimating
            )
            .onAppear {
                isAnimating = true
            }
    }
}

// MARK: - Empty & Error State Views

struct SpiceEmptyStateView: View {
    let title: String
    let message: String
    var buttonTitle: String? = nil
    var onAction: (() -> Void)? = nil

    var body: some View {
        SpiceCard(backgroundColor: .white, borderColor: Color.spiceCardBorder.opacity(0.8)) {
            VStack(spacing: 10) {
                Text(title)
                    .font(.appFont(size: 13.5, weight: .heavy))
                    .foregroundColor(Color.spiceInk)

                Text(message)
                    .font(.appFont(size: 11.5, weight: .medium))
                    .foregroundColor(Color.spiceMuted)
                    .multilineTextAlignment(.center)

                if let btn = buttonTitle, let onAction = onAction {
                    Button(action: onAction) {
                        Text(btn)
                            .font(.appFont(size: 12, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 18)
                            .padding(.vertical, 9)
                            .background(Color.spicePrimary)
                            .cornerRadius(10)
                    }
                    .padding(.top, 4)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
        }
    }
}

// MARK: - Offline Connectivity Banner

struct SpiceOfflineBanner: View {
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "wifi.slash")
                .font(.appFont(size: 12, weight: .bold))
                .foregroundColor(.white)

            Text("No Internet Connection · Working in Offline Mode")
                .font(.appFont(size: 11, weight: .bold))
                .foregroundColor(.white)

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color.spiceDue)
    }
}

// MARK: - Divider

struct SpiceDivider: View {
    var color: Color = Color.spiceDivider

    var body: some View {
        Rectangle()
            .fill(color)
            .frame(height: 1)
    }
}

// MARK: - Interactive Date Filter Chip & Sheet

struct SpiceDateFilterChip: View {
    @Binding var selectedDate: Date?
    var placeholder: String = "Any Date"
    @State private var showSheet: Bool = false

    var label: String {
        guard let date = selectedDate else { return placeholder }
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMM yyyy"
        return formatter.string(from: date)
    }

    var body: some View {
        HStack(spacing: 6) {
            Button(action: { showSheet = true }) {
                HStack(spacing: 6) {
                    Image(systemName: "calendar")
                        .font(.appFont(size: 11, weight: .semibold))
                        .foregroundColor(selectedDate != nil ? Color.spicePrimary : Color.spiceMuted)

                    Text(label)
                        .font(.appFont(size: 12, weight: .bold))
                        .foregroundColor(selectedDate != nil ? Color.spicePrimary : Color.spiceInk)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
                .background(selectedDate != nil ? Color.spicePrimaryLight : Color.white)
                .cornerRadius(16)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(selectedDate != nil ? Color.spicePrimary : Color.spiceCardBorder, lineWidth: 1)
                )
            }
            .buttonStyle(.plain)

            if selectedDate != nil {
                Button(action: {
                    selectedDate = nil
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.appFont(size: 14))
                        .foregroundColor(Color.spiceMuted)
                }
                .buttonStyle(.plain)
            }
        }
        .sheet(isPresented: $showSheet) {
            SpiceDatePickerSheet(selectedDate: $selectedDate)
        }
    }
}

struct SpiceDatePickerSheet: View {
    @Binding var selectedDate: Date?
    @Environment(\.dismiss) private var dismiss
    @State private var tempDate: Date = Date()

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                // Quick Preset Chips
                HStack(spacing: 8) {
                    Button(action: {
                        selectedDate = nil
                        dismiss()
                    }) {
                        Text("Any Date")
                            .font(.appFont(size: 12, weight: .bold))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 7)
                            .background(selectedDate == nil ? Color.spicePrimary : Color.spiceBackground)
                            .foregroundColor(selectedDate == nil ? .white : Color.spiceInk)
                            .cornerRadius(10)
                    }

                    Button(action: {
                        selectedDate = Date()
                        dismiss()
                    }) {
                        Text("Today")
                            .font(.appFont(size: 12, weight: .bold))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 7)
                            .background(Color.spiceBackground)
                            .foregroundColor(Color.spiceInk)
                            .cornerRadius(10)
                    }

                    Button(action: {
                        if let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date()) {
                            selectedDate = yesterday
                        }
                        dismiss()
                    }) {
                        Text("Yesterday")
                            .font(.appFont(size: 12, weight: .bold))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 7)
                            .background(Color.spiceBackground)
                            .foregroundColor(Color.spiceInk)
                            .cornerRadius(10)
                    }
                }
                .padding(.top, 12)

                Divider()

                // Graphical DatePicker
                DatePicker(
                    "Select Date",
                    selection: $tempDate,
                    displayedComponents: [.date]
                )
                .datePickerStyle(.graphical)
                .accentColor(Color.spicePrimary)
                .padding(.horizontal, 12)

                Spacer()

                // Actions
                HStack(spacing: 12) {
                    SpiceOutlinedButton(title: "Reset", height: 44) {
                        selectedDate = nil
                        dismiss()
                    }

                    SpicePrimaryButton(title: "Apply Date", height: 44) {
                        selectedDate = tempDate
                        dismiss()
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
            }
            .navigationTitle("Filter by Date")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
            .onAppear {
                if let s = selectedDate {
                    tempDate = s
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}

// MARK: - Date Range Model
public struct DateRange: Equatable, Hashable {
    public var start: Date?
    public var end: Date?

    public var startDate: Date { start ?? Date() }
    public var endDate: Date { end ?? start ?? Date() }

    public init(start: Date? = nil, end: Date? = nil) {
        self.start = start
        self.end = end
    }

    public init(startDate: Date, endDate: Date) {
        self.start = startDate
        self.end = endDate
    }

    public static var today: DateRange {
        let today = Calendar.current.startOfDay(for: Date())
        return DateRange(start: today, end: today)
    }

    public static var yesterday: DateRange {
        let cal = Calendar.current
        let yday = cal.date(byAdding: .day, value: -1, to: cal.startOfDay(for: Date())) ?? Date()
        return DateRange(start: yday, end: yday)
    }

    public static var thisWeek: DateRange {
        let cal = Calendar.current
        let now = Date()
        let start = cal.date(from: cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now)) ?? now
        return DateRange(start: start, end: now)
    }

    public static var thisMonth: DateRange {
        let cal = Calendar.current
        let now = Date()
        let start = cal.date(from: cal.dateComponents([.year, .month], from: now)) ?? now
        return DateRange(start: start, end: now)
    }

    public static var last30Days: DateRange {
        let cal = Calendar.current
        let now = Date()
        let start = cal.date(byAdding: .day, value: -30, to: now) ?? now
        return DateRange(start: start, end: now)
    }

    public var isComplete: Bool {
        start != nil && end != nil
    }

    public var isActive: Bool {
        start != nil
    }

    public func contains(_ date: Date) -> Bool {
        guard let s = start else { return true }
        let cal = Calendar.current
        let startOfDay = cal.startOfDay(for: s)

        if let e = end {
            let endOfDay = cal.date(bySettingHour: 23, minute: 59, second: 59, of: e) ?? e
            return (startOfDay...endOfDay).contains(date)
        } else {
            let endOfDay = cal.date(bySettingHour: 23, minute: 59, second: 59, of: s) ?? s
            return (startOfDay...endOfDay).contains(date)
        }
    }

    public func contains(dateString: String) -> Bool {
        guard start != nil else { return true }
        let clean = String(dateString.prefix(10))
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        if let d = formatter.date(from: clean) {
            return contains(d)
        }
        return false
    }

    public var displayString: String {
        guard let s = start else { return "All time" }
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMM yyyy"
        if let e = end, !Calendar.current.isDate(s, inSameDayAs: e) {
            return "\(formatter.string(from: s)) → \(formatter.string(from: e))"
        } else {
            return formatter.string(from: s)
        }
    }
}

// MARK: - Date Range Filter Chip
public struct SpiceDateRangeFilterChip: View {
    @Binding var selectedRange: DateRange?
    var placeholder: String = "Select Date"
    @State private var showModal: Bool = false

    public init(selectedRange: Binding<DateRange?>, placeholder: String = "Select Date") {
        self._selectedRange = selectedRange
        self.placeholder = placeholder
    }

    var label: String {
        guard let range = selectedRange, range.isActive else { return placeholder }
        return range.displayString
    }

    public var body: some View {
        HStack(spacing: 6) {
            Button(action: { showModal = true }) {
                HStack(spacing: 6) {
                    Image(systemName: "calendar")
                        .font(.appFont(size: 12, weight: .semibold))
                        .foregroundColor(selectedRange?.isActive == true ? Color.spicePrimary : Color.spiceMuted)

                    Text(label)
                        .font(.appFont(size: 12.5, weight: .bold))
                        .foregroundColor(selectedRange?.isActive == true ? Color.spicePrimary : Color.spiceInk)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(selectedRange?.isActive == true ? Color(hex: "#E8F5EC") : Color.white)
                .cornerRadius(20)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(selectedRange?.isActive == true ? Color.spicePrimary : Color.spiceCardBorder, lineWidth: 1)
                )
            }
            .buttonStyle(.plain)

            if selectedRange?.isActive == true {
                Button(action: {
                    selectedRange = nil
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.appFont(size: 14))
                        .foregroundColor(Color.spiceMuted)
                }
                .buttonStyle(.plain)
            }
        }
        .fullScreenCover(isPresented: $showModal) {
            SpiceDateRangeModal(selectedRange: $selectedRange, isPresented: $showModal)
                .background(BackgroundCleanerView())
        }
    }
}

// MARK: - Background Cleaner for Transparent Modal
public struct BackgroundCleanerView: UIViewRepresentable {
    public init() {}
    public func makeUIView(context: Context) -> UIView {
        let view = UIView()
        DispatchQueue.main.async {
            view.superview?.superview?.backgroundColor = .clear
        }
        return view
    }

    public func updateUIView(_ uiView: UIView, context: Context) {}
}

// MARK: - Select Date Range Modal (Exact Visual Match to Screenshot)
public struct SpiceDateRangeModal: View {
    @Binding var selectedRange: DateRange?
    @Binding var isPresented: Bool

    @State private var tempStart: Date?
    @State private var tempEnd: Date?
    @State private var displayedMonth: Date = Date()

    private let calendar = Calendar.current
    private let weekdays = ["S", "M", "T", "W", "T", "F", "S"]

    public init(selectedRange: Binding<DateRange?>, isPresented: Binding<Bool>) {
        self._selectedRange = selectedRange
        self._isPresented = isPresented
    }

    var rangePreviewText: String {
        guard let s = tempStart else { return "Select dates" }
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMM yyyy"
        if let e = tempEnd, !calendar.isDate(s, inSameDayAs: e) {
            return "\(formatter.string(from: s)) → \(formatter.string(from: e))"
        } else {
            return formatter.string(from: s)
        }
    }

    var monthTitle: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: displayedMonth)
    }

    public var body: some View {
        ZStack {
            // Backdrop Scrim
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture {
                    isPresented = false
                }

            // Modal Card
            VStack(alignment: .leading, spacing: 14) {
                // Title
                Text("Select Date Range")
                    .font(.appFont(size: 17, weight: .heavy))
                    .foregroundColor(Color.spiceInk)

                // Subtitle / Selected Range
                Text(rangePreviewText)
                    .font(.appFont(size: 13, weight: .bold))
                    .foregroundColor(Color.spicePrimary)

                // 4 Preset Filter Chips
                HStack(spacing: 8) {
                    presetButton(title: "7 days") {
                        applyPreset(days: 7)
                    }

                    presetButton(title: "30 days") {
                        applyPreset(days: 30)
                    }

                    presetButton(title: "This month") {
                        applyThisMonth()
                    }

                    presetButton(title: "Last month") {
                        applyLastMonth()
                    }
                }

                // Month Navigation Header
                HStack {
                    HStack(spacing: 4) {
                        Text(monthTitle)
                            .font(.appFont(size: 14.5, weight: .heavy))
                            .foregroundColor(Color.spiceInk)

                        Image(systemName: "chevron.down")
                            .font(.appFont(size: 10, weight: .bold))
                            .foregroundColor(Color.spiceInk)
                    }

                    Spacer()

                    HStack(spacing: 6) {
                        Button(action: { changeMonth(by: -1) }) {
                            Circle()
                                .fill(Color(hex: "#F1F5F2"))
                                .frame(width: 32, height: 32)
                                .overlay(
                                    Image(systemName: "chevron.left")
                                        .font(.appFont(size: 11, weight: .bold))
                                        .foregroundColor(Color.spiceInk)
                                )
                        }

                        Button(action: { changeMonth(by: 1) }) {
                            Circle()
                                .fill(Color(hex: "#F1F5F2"))
                                .frame(width: 32, height: 32)
                                .overlay(
                                    Image(systemName: "chevron.right")
                                        .font(.appFont(size: 11, weight: .bold))
                                        .foregroundColor(Color.spiceInk)
                                )
                        }
                    }
                }
                .padding(.top, 4)

                // Weekdays Header
                HStack(spacing: 0) {
                    ForEach(weekdays, id: \.self) { day in
                        Text(day)
                            .font(.appFont(size: 12, weight: .medium))
                            .foregroundColor(Color.spiceMuted)
                            .frame(maxWidth: .infinity)
                    }
                }
                .padding(.top, 2)

                // Calendar Days Grid
                calendarGridView

                // Bottom Action Buttons
                HStack(spacing: 12) {
                    // Clear Button
                    Button(action: {
                        tempStart = nil
                        tempEnd = nil
                    }) {
                        Text("Clear")
                            .font(.appFont(size: 14, weight: .heavy))
                            .foregroundColor(Color.spiceInk)
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                            .background(Color.white)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.spiceCardBorder, lineWidth: 1)
                            )
                            .cornerRadius(12)
                    }
                    .buttonStyle(.plain)

                    // Apply Button
                    Button(action: {
                        if tempStart != nil {
                            selectedRange = DateRange(start: tempStart, end: tempEnd ?? tempStart)
                        } else {
                            selectedRange = nil
                        }
                        isPresented = false
                    }) {
                        Text("Apply")
                            .font(.appFont(size: 14, weight: .heavy))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                            .background(Color.spicePrimary)
                            .cornerRadius(12)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.top, 8)
            }
            .padding(20)
            .background(Color.white)
            .cornerRadius(20)
            .shadow(color: Color.black.opacity(0.18), radius: 24, x: 0, y: 8)
            .padding(.horizontal, 20)
        }
        .onAppear {
            if let current = selectedRange {
                tempStart = current.start
                tempEnd = current.end
                if let s = current.start {
                    displayedMonth = s
                }
            } else {
                let today = calendar.startOfDay(for: Date())
                tempStart = today
                tempEnd = today
                displayedMonth = today
            }
        }
    }

    // MARK: - Calendar Grid View
    private var calendarGridView: some View {
        let days = daysInMonth(for: displayedMonth)
        let firstWeekday = firstWeekdayOffset(for: displayedMonth)
        let totalCells = (days + firstWeekday <= 35) ? 35 : 42

        return LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 0), count: 7), spacing: 4) {
            ForEach(0..<totalCells, id: \.self) { index in
                let dayNumber = index - firstWeekday + 1
                if dayNumber >= 1 && dayNumber <= days {
                    let cellDate = dateForDay(dayNumber, in: displayedMonth)
                    dayCellView(date: cellDate, dayNumber: dayNumber)
                } else {
                    Text("")
                        .frame(height: 38)
                }
            }
        }
    }

    // MARK: - Day Cell View
    @ViewBuilder
    private func dayCellView(date: Date, dayNumber: Int) -> some View {
        let isStart = tempStart != nil && calendar.isDate(date, inSameDayAs: tempStart!)
        let isEnd = tempEnd != nil && calendar.isDate(date, inSameDayAs: tempEnd!)
        let isRangeActive = tempStart != nil && tempEnd != nil && !calendar.isDate(tempStart!, inSameDayAs: tempEnd!)
        let isInBetween = isRangeActive && date > tempStart! && date < tempEnd!

        ZStack {
            // In-between connector bands
            if isInBetween {
                Rectangle()
                    .fill(Color(hex: "#E6F4EC"))
                    .frame(height: 38)
            } else if isStart && isRangeActive {
                HStack(spacing: 0) {
                    Spacer()
                    Rectangle()
                        .fill(Color(hex: "#E6F4EC"))
                        .frame(width: 22, height: 38)
                }
            } else if isEnd && isRangeActive {
                HStack(spacing: 0) {
                    Rectangle()
                        .fill(Color(hex: "#E6F4EC"))
                        .frame(width: 22, height: 38)
                    Spacer()
                }
            }

            // Start / End circle highlight
            if isStart || isEnd {
                Circle()
                    .fill(Color.spicePrimary)
                    .frame(width: 36, height: 36)
            }

            Text("\(dayNumber)")
                .font(.appFont(size: 13.5, weight: (isStart || isEnd) ? .heavy : .medium))
                .foregroundColor(
                    (isStart || isEnd) ? .white :
                    isInBetween ? Color.spicePrimary : Color.spiceInk
                )
        }
        .frame(height: 38)
        .contentShape(Rectangle())
        .onTapGesture {
            selectDate(date)
        }
    }

    // MARK: - Date Selection Logic
    private func selectDate(_ date: Date) {
        if tempStart == nil || (tempStart != nil && tempEnd != nil) {
            tempStart = date
            tempEnd = nil
        } else if let s = tempStart {
            if date < s {
                tempStart = date
                tempEnd = s
            } else {
                tempEnd = date
            }
        }
    }

    // MARK: - Preset Handlers
    private func presetButton(title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.appFont(size: 12, weight: .bold))
                .foregroundColor(Color.spicePrimary)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color(hex: "#E8F5EC"))
                .cornerRadius(10)
        }
        .buttonStyle(.plain)
    }

    private func applyPreset(days: Int) {
        let today = calendar.startOfDay(for: Date())
        if let past = calendar.date(byAdding: .day, value: -(days - 1), to: today) {
            tempStart = past
            tempEnd = today
            displayedMonth = past
        }
    }

    private func applyThisMonth() {
        let components = calendar.dateComponents([.year, .month], from: Date())
        if let startOfMonth = calendar.date(from: components),
           let range = calendar.range(of: .day, in: .month, for: startOfMonth),
           let endOfMonth = calendar.date(byAdding: .day, value: range.count - 1, to: startOfMonth) {
            tempStart = startOfMonth
            tempEnd = endOfMonth
            displayedMonth = startOfMonth
        }
    }

    private func applyLastMonth() {
        if let lastMonthDate = calendar.date(byAdding: .month, value: -1, to: Date()) {
            let components = calendar.dateComponents([.year, .month], from: lastMonthDate)
            if let startOfMonth = calendar.date(from: components),
               let range = calendar.range(of: .day, in: .month, for: startOfMonth),
               let endOfMonth = calendar.date(byAdding: .day, value: range.count - 1, to: startOfMonth) {
                tempStart = startOfMonth
                tempEnd = endOfMonth
                displayedMonth = startOfMonth
            }
        }
    }

    private func changeMonth(by amount: Int) {
        if let next = calendar.date(byAdding: .month, value: amount, to: displayedMonth) {
            displayedMonth = next
        }
    }

    // MARK: - Calendar Helpers
    private func daysInMonth(for date: Date) -> Int {
        calendar.range(of: .day, in: .month, for: date)?.count ?? 30
    }

    private func firstWeekdayOffset(for date: Date) -> Int {
        let components = calendar.dateComponents([.year, .month], from: date)
        guard let firstDay = calendar.date(from: components) else { return 0 }
        let weekday = calendar.component(.weekday, from: firstDay)
        return weekday - 1
    }

    private func dateForDay(_ day: Int, in monthDate: Date) -> Date {
        var components = calendar.dateComponents([.year, .month], from: monthDate)
        components.day = day
        return calendar.date(from: components) ?? monthDate
    }
}
