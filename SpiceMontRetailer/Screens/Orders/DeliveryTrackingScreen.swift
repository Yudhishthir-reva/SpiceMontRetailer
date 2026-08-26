//
//  DeliveryTrackingScreen.swift
//  SpiceMontRetailer
//
//  Created on 24/08/26.
//

import SwiftUI
import Combine

struct DeliveryTrackingScreen: View {
    var orderId: Int? = nil
    var orderNumber: String = ""
    @Environment(\.dismiss) private var dismiss

    @State private var trackData: RetailerOrderTrackResponse? = nil
    @State private var isLoading: Bool = false
    @State private var isShowToast: Bool = false
    @State private var toastMessage: String = ""

    private let service = OrderServiceManager()
    @State private var cancellables = Set<AnyCancellable>()

    var resolvedOrderId: Int {
        if let id = orderId, id > 0 { return id }
        let clean = orderNumber.replacingOccurrences(of: "#", with: "")
        if let intVal = Int(clean) { return intVal }
        if let lastPart = clean.components(separatedBy: "/").last, let intPart = Int(lastPart) {
            return intPart
        }
        return 0
    }

    var orderNumberText: String {
        if let num = trackData?.data?.orderNo, !num.isEmpty {
            return num
        }
        return orderNumber.isEmpty ? (resolvedOrderId > 0 ? "#\(resolvedOrderId)" : "") : orderNumber
    }

    var body: some View {
        ZStack {
            Color.spiceBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                if isLoading && trackData == nil {
                    ScrollView {
                        VStack(spacing: 12) {
                            SpiceSkeletonBox(height: 70, cornerRadius: 16)
                            SpiceSkeletonBox(height: 240, cornerRadius: 16)
                            SpiceSkeletonBox(height: 50, cornerRadius: 12)
                        }
                        .padding(16)
                    }
                } else if let data = trackData?.data {
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 14) {
                            // MARK: - Card 1: Order Header Info Card
                            orderHeaderCard(data: data)

                            // MARK: - Card 2: Status Timeline Card
                            statusTimelineCard(data: data)

                            // MARK: - Card 3: View Order Details Button
                            NavigationLink(destination: OrderDetailScreen(orderId: data.orderNo ?? orderNumber)) {
                                HStack {
                                    Spacer()
                                    Text("View Order Details")
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundColor(Color.spiceInk)
                                    Spacer()
                                }
                                .frame(height: 48)
                                .background(Color.white)
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.spiceCardBorder, lineWidth: 1)
                                )
                            }
                            .buttonStyle(.plain)

                            // Rider Card (if assigned)
                            if let rider = data.rider {
                                riderCard(rider: rider)
                            }

                            Spacer(minLength: 30)
                        }
                        .padding(16)
                    }
                    .refreshable {
                        loadTracking()
                    }
                } else {
                    VStack {
                        Spacer()
                        SpiceEmptyStateView(
                            title: "Tracking Info Unavailable",
                            message: "Live tracking details could not be found for this order.",
                            buttonTitle: "Retry"
                        ) {
                            loadTracking()
                        }
                        Spacer()
                    }
                }
            }
        }
        .navigationTitle("Track Order")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarHidden(false)
        .toolbar(.visible, for: .navigationBar)
        .toolbar(.hidden, for: .tabBar)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { loadTracking() }) {
                    Text("Refresh")
                        .font(.system(size: 13.5, weight: .heavy))
                        .foregroundColor(Color.spicePrimary)
                }
            }
        }
        .onAppear {
            loadTracking()
        }
        .toast(isPresenting: $isShowToast, duration: 2.0, offsetY: 10, alert: {
            AlertToast(displayMode: .banner(.pop), type: .regular, title: toastMessage)
        }, onTap: nil, completion: nil)
    }

    // MARK: - Card 1: Order Header Card
    private func orderHeaderCard(data: RetailerOrderTrackData) -> some View {
        HStack {
            Text(data.orderNo ?? orderNumberText)
                .font(.system(size: 14.5, weight: .heavy, design: .monospaced))
                .foregroundColor(Color.spiceInk)

            Spacer()

            Text(data.statusText?.uppercased() ?? "PENDING")
                .font(.system(size: 10, weight: .heavy, design: .monospaced))
                .foregroundColor(Color(hex: data.statusColorHex ?? "#405189"))
                .padding(.horizontal, 8)
                .padding(.vertical, 3.5)
                .background(Color(hex: data.statusColorHex ?? "#405189").opacity(0.12))
                .cornerRadius(5)
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.spiceCardBorder.opacity(0.8), lineWidth: 1)
        )
    }

    // MARK: - Card 2: Status Timeline Card
    private func statusTimelineCard(data: RetailerOrderTrackData) -> some View {
        let timeline = data.timeline ?? []

        return VStack(alignment: .leading, spacing: 14) {
            Text("Status Timeline")
                .font(.system(size: 14, weight: .heavy))
                .foregroundColor(Color.spiceInk)

            if timeline.isEmpty {
                Text("Status timeline not available.")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Color.spiceMuted)
                    .padding(.vertical, 8)
            } else {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(Array(timeline.enumerated()), id: \.offset) { index, item in
                        let isLast = index == timeline.count - 1
                        timelineRowView(item: item, isLast: isLast)
                    }
                }
                .padding(.horizontal, 4)
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.spiceCardBorder.opacity(0.8), lineWidth: 1)
        )
    }

    @ViewBuilder
    private func timelineRowView(item: RetailerTimelineItem, isLast: Bool) -> some View {
        let isDone = item.isDone == true
        let isActive = item.isActive == true

        HStack(alignment: .top, spacing: 12) {
            timelineIconView(isDone: isDone, isActive: isActive, isLast: isLast)

            VStack(alignment: .leading, spacing: 2) {
                Text(item.label ?? item.title ?? "Status Update")
                    .font(.system(size: 13.5, weight: isDone || isActive ? .heavy : .semibold))
                    .foregroundColor(isDone || isActive ? Color.spiceInk : Color(hex: "#9CA3AF"))

                if let date = item.date, !date.isEmpty {
                    Text(date)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(Color.spiceMuted)
                }

                if let desc = item.description, !desc.isEmpty {
                    Text(desc)
                        .font(.system(size: 11, weight: .regular))
                        .foregroundColor(Color.spiceMuted)
                        .lineLimit(2)
                }

                if isActive {
                    Text("Current status")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(Color(hex: "#167444"))
                        .padding(.top, 1)
                }
            }
            .padding(.bottom, isLast ? 0 : 12)

            Spacer()
        }
    }

    @ViewBuilder
    private func timelineIconView(isDone: Bool, isActive: Bool, isLast: Bool) -> some View {
        VStack(spacing: 0) {
            if isDone {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(Color(hex: "#167444"))
            } else if isActive {
                Circle()
                    .fill(Color.spicePrimary)
                    .frame(width: 14, height: 14)
                    .overlay(
                        Circle()
                            .stroke(Color.white, lineWidth: 2)
                    )
                    .padding(.vertical, 2)
            } else {
                Circle()
                    .fill(Color(hex: "#E5E7EB"))
                    .frame(width: 14, height: 14)
                    .padding(.vertical, 2)
            }

            if !isLast {
                Rectangle()
                    .fill(isDone ? Color(hex: "#167444") : Color(hex: "#E5E7EB"))
                    .frame(width: 2, height: 28)
            }
        }
    }

    // MARK: - Rider Card
    private func riderCard(rider: RetailerRiderData) -> some View {
        HStack(spacing: 12) {
            Circle()
                .fill(Color(hex: "#E8F5EC"))
                .frame(width: 48, height: 48)
                .overlay(
                    Image(systemName: "bicycle")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(Color.spicePrimary)
                )

            VStack(alignment: .leading, spacing: 2) {
                Text(rider.name ?? "Delivery Rider")
                    .font(.system(size: 13.5, weight: .heavy))
                    .foregroundColor(Color.spiceInk)

                if let vehicle = rider.vehicleNo, !vehicle.isEmpty {
                    Text("Vehicle: \(vehicle)")
                        .font(.system(size: 11.5, weight: .medium))
                        .foregroundColor(Color.spiceMuted)
                }
            }

            Spacer()

            if let phone = rider.mobile, let url = URL(string: "tel://\(phone)") {
                Button(action: {
                    UIApplication.shared.open(url)
                }) {
                    Text("CALL")
                        .font(.system(size: 11.5, weight: .heavy))
                        .foregroundColor(Color.spicePrimary)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 7)
                        .background(Color.spicePrimaryLight)
                        .cornerRadius(6)
                }
            }
        }
        .padding(14)
        .background(Color.white)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.spiceCardBorder.opacity(0.8), lineWidth: 1)
        )
    }

    // MARK: - Service Call
    private func loadTracking() {
        guard resolvedOrderId > 0 else { return }
        isLoading = true
        let headers = UserDefaultManager.shared.authHeader
        let params: [String: Any] = ["order_id": resolvedOrderId]

        service.trackOrder(params: params, headers: headers)
            .receive(on: DispatchQueue.main)
            .sink { completion in
                isLoading = false
                if case .failure(let error) = completion {
                    toastMessage = (error as? RequestError)?.errorString ?? error.localizedDescription
                }
            } receiveValue: { response in
                self.trackData = response
            }
            .store(in: &cancellables)
    }
}

#Preview {
    NavigationStack {
        DeliveryTrackingScreen(orderId: 1)
    }
}
