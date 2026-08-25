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
    var orderNumber: String = "#2026-27/2967"
    @Environment(\.dismiss) private var dismiss

    @State private var trackData: RetailerOrderTrackResponse? = nil
    @State private var isLoading: Bool = false
    @State private var isShowToast: Bool = false
    @State private var toastMessage: String = ""

    private let service = OrderServiceManager()
    @State private var cancellables = Set<AnyCancellable>()

    var resolvedOrderId: Int {
        if let id = orderId { return id }
        let clean = orderNumber.replacingOccurrences(of: "#", with: "")
        if let intVal = Int(clean) { return intVal }
        if let lastPart = clean.components(separatedBy: "/").last, let intPart = Int(lastPart) {
            return intPart
        }
        return 2967
    }

    var displayData: RetailerOrderTrackData {
        if let data = trackData?.data {
            return data
        }
        return RetailerOrderTrackData(
            orderId: resolvedOrderId,
            orderNo: orderNumber.isEmpty ? "#\(resolvedOrderId)" : orderNumber,
            status: 0,
            statusText: "Pending",
            statusColorHex: "#FFA500",
            orderDate: "",
            deliveryDate: nil,
            rider: nil,
            riderLocation: nil,
            timeline: []
        )
    }

    var body: some View {
        ZStack {
            Color.spiceBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                // MARK: - Top Bar
                HStack(alignment: .center, spacing: 12) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(Color.spiceInk)
                            .padding(4)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Delivery Tracking")
                            .font(.system(size: 17, weight: .heavy))
                            .foregroundColor(Color.spiceInk)

                        Text(displayData.orderNo ?? orderNumber)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(Color.spiceMuted)
                    }

                    Spacer()

                    Button(action: {
                        loadTracking()
                    }) {
                        Text("Refresh")
                            .font(.system(size: 13.5, weight: .heavy))
                            .foregroundColor(Color.spicePrimary)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 10)
                .background(Color.white)
                .overlay(Divider().background(Color.spiceDivider), alignment: .bottom)

                if isLoading && trackData == nil {
                    ScrollView {
                        VStack(spacing: 12) {
                            SpiceSkeletonBox(height: 70, cornerRadius: 16)
                            SpiceSkeletonBox(height: 240, cornerRadius: 16)
                            SpiceSkeletonBox(height: 50, cornerRadius: 12)
                        }
                        .padding(16)
                    }
                } else {
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 14) {
                            // MARK: - Card 1: Order Header Info Card
                            orderHeaderCard

                            // MARK: - Card 2: Status Timeline Card
                            statusTimelineCard

                            // MARK: - Card 3: View Order Details Button
                            NavigationLink(destination: OrderDetailScreen(orderId: displayData.orderNo ?? orderNumber)) {
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
                            if let rider = displayData.rider {
                                riderCard(rider: rider)
                            }

                            Spacer(minLength: 30)
                        }
                        .padding(16)
                    }
                    .refreshable {
                        loadTracking()
                    }
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            loadTracking()
        }
        .toast(isPresenting: $isShowToast, duration: 2.0, offsetY: 10, alert: {
            AlertToast(displayMode: .banner(.pop), type: .regular, title: toastMessage)
        }, onTap: nil, completion: nil)
    }

    // MARK: - Card 1: Order Header Card
    private var orderHeaderCard: some View {
        HStack {
            Text(displayData.orderNo ?? orderNumber)
                .font(.system(size: 14.5, weight: .heavy, design: .monospaced))
                .foregroundColor(Color.spiceInk)

            Spacer()

            Text(displayData.statusText?.uppercased() ?? "PENDING")
                .font(.system(size: 10, weight: .heavy, design: .monospaced))
                .foregroundColor(Color(hex: displayData.statusColorHex ?? "#405189"))
                .padding(.horizontal, 8)
                .padding(.vertical, 3.5)
                .background(Color(hex: displayData.statusColorHex ?? "#405189").opacity(0.12))
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
    private var statusTimelineCard: some View {
        let timeline = displayData.timeline ?? []

        return VStack(alignment: .leading, spacing: 14) {
            Text("Status Timeline")
                .font(.system(size: 14, weight: .heavy))
                .foregroundColor(Color.spiceInk)

            VStack(alignment: .leading, spacing: 0) {
                ForEach(Array(timeline.enumerated()), id: \.offset) { index, item in
                    let isLast = index == timeline.count - 1
                    let isDone = item.isDone == true
                    let isActive = item.isActive == true

                    HStack(alignment: .top, spacing: 12) {
                        VStack(spacing: 0) {
                            if isDone {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(Color(hex: "#167444"))
                            } else if isActive {
                                Circle()
                                    .stroke(Color.spicePrimary, lineWidth: 3)
                                    .background(Circle().fill(Color.white))
                                    .frame(width: 16, height: 16)
                            } else {
                                Circle()
                                    .fill(Color(hex: "#E5E7EB"))
                                    .frame(width: 16, height: 16)
                            }

                            if !isLast {
                                Rectangle()
                                    .fill(isDone ? Color(hex: "#167444") : Color(hex: "#E5E7EB"))
                                    .frame(width: 1.5, height: 32)
                            }
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.label ?? "Step")
                                .font(.system(size: 13.5, weight: isDone || isActive ? .heavy : .semibold))
                                .foregroundColor(isDone || isActive ? Color.spiceInk : Color(hex: "#9CA3AF"))

                            if let date = item.date, !date.isEmpty {
                                Text(date)
                                    .font(.system(size: 11.5, weight: .medium))
                                    .foregroundColor(Color.spiceMuted)
                            }

                            if isActive {
                                Text("Current status")
                                    .font(.system(size: 11.5, weight: .bold))
                                    .foregroundColor(Color(hex: "#167444"))
                                    .padding(.top, 1)
                            }
                        }

                        Spacer()
                    }
                }
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

    // MARK: - Rider Details Card
    private func riderCard(rider: RetailerRiderInfo) -> some View {
        HStack(spacing: 12) {
            Circle()
                .fill(Color.spicePrimaryLight)
                .frame(width: 44, height: 44)
                .overlay(
                    Image(systemName: "bicycle")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(Color.spicePrimary)
                )

            VStack(alignment: .leading, spacing: 2) {
                Text(rider.name ?? "Delivery Partner")
                    .font(.system(size: 13.5, weight: .heavy))
                    .foregroundColor(Color.spiceInk)
                Text(rider.mobile ?? "")
                    .font(.system(size: 11.5, design: .monospaced))
                    .foregroundColor(Color.spiceMuted)
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
