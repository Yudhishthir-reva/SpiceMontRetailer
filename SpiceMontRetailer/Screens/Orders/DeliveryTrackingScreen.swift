//
//  DeliveryTrackingScreen.swift
//  SpiceMontRetailer
//
//  Created on 24/08/26.
//

import SwiftUI
import Combine

struct DeliveryTrackingScreen: View {
    var orderNumber: String = "#SM10245"
    @Environment(\.dismiss) private var dismiss

    @State private var trackData: RetailerOrderTrackResponse? = nil
    @State private var isLoading: Bool = false
    @State private var isShowToast: Bool = false
    @State private var toastMessage: String = ""

    private let service = OrderServiceManager()
    @State private var cancellables = Set<AnyCancellable>()

    var intOrderId: Int {
        Int(orderNumber.replacingOccurrences(of: "#", with: "")) ?? 101
    }

    var body: some View {
        VStack(spacing: 0) {
            // Top Bar
            SpiceTopBar(title: "Track Order", showBack: true, onBack: { dismiss() })

            if isLoading && trackData == nil {
                ScrollView {
                    VStack(spacing: 12) {
                        SpiceSkeletonBox(height: 100, cornerRadius: 16)
                        SpiceSkeletonBox(height: 200, cornerRadius: 16)
                        SpiceSkeletonBox(height: 80, cornerRadius: 16)
                    }
                    .padding(16)
                }
                .background(Color.spiceBackground)
            } else {
                ScrollView {
                    VStack(spacing: 12) {
                        // Header Status Card
                        SpiceCard(backgroundColor: Color(hex: "#F5F9FE"), borderColor: Color(hex: "#C9DCF5")) {
                            VStack(alignment: .leading, spacing: 6) {
                                HStack {
                                    Text(orderNumber)
                                        .font(.system(size: 13, weight: .heavy, design: .monospaced))
                                        .foregroundColor(Color.spiceInk)
                                    Spacer()
                                    SpiceStatusBadge(status: trackData?.data?.statusText?.uppercased() ?? "OUT FOR DELIVERY")
                                }

                                Text("Order Status: \(trackData?.data?.statusText ?? "Out for Delivery")")
                                    .font(.system(size: 15, weight: .heavy))
                                    .foregroundColor(Color.spiceTransit)
                            }
                        }

                        // Progress Timeline Card
                        if let timeline = trackData?.data?.timeline, !timeline.isEmpty {
                            SpiceCard {
                                VStack(alignment: .leading, spacing: 14) {
                                    Text("Delivery Progress")
                                        .font(.system(size: 12.5, weight: .heavy))
                                        .foregroundColor(Color.spiceInk)

                                    ForEach(Array(timeline.enumerated()), id: \.offset) { index, item in
                                        timelineItem(
                                            title: item.label ?? "",
                                            time: item.date ?? "",
                                            isCompleted: item.isDone == true,
                                            isCurrent: item.isActive == true,
                                            isLast: index == timeline.count - 1
                                        )
                                    }
                                }
                            }
                        }

                        // Rider Details Card
                        if let rider = trackData?.data?.rider {
                            SpiceCard {
                                HStack(spacing: 12) {
                                    Circle()
                                        .fill(LinearGradient(colors: [Color(hex: "#2C6BE0"), Color(hex: "#123A8E")], startPoint: .topLeading, endPoint: .bottomTrailing))
                                        .frame(width: 44, height: 44)
                                        .overlay(Text(rider.name?.prefix(2).uppercased() ?? "DR").font(.system(size: 11, weight: .heavy)).foregroundColor(.white))

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(rider.name ?? "Delivery Partner")
                                            .font(.system(size: 13, weight: .heavy))
                                            .foregroundColor(Color.spiceInk)
                                        Text(rider.mobile ?? "")
                                            .font(.system(size: 11, design: .monospaced))
                                            .foregroundColor(Color.spiceMuted)
                                    }

                                    Spacer()

                                    if let phone = rider.mobile, let url = URL(string: "tel://\(phone)") {
                                        Button(action: {
                                            UIApplication.shared.open(url)
                                        }) {
                                            Text("CALL")
                                                .font(.system(size: 11, weight: .heavy))
                                                .foregroundColor(Color.spicePrimary)
                                                .padding(.horizontal, 12)
                                                .padding(.vertical, 6)
                                                .background(Color.spicePrimaryLight)
                                                .cornerRadius(6)
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .padding(16)
                }
                .refreshable {
                    loadTracking()
                }
                .background(Color.spiceBackground)
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

    private func loadTracking() {
        isLoading = true
        let headers = UserDefaultManager.shared.authHeader
        let params: [String: Any] = ["order_id": intOrderId]

        service.trackOrder(params: params, headers: headers)
            .receive(on: DispatchQueue.main)
            .sink { completion in
                isLoading = false
                if case .failure(let error) = completion {
                    toastMessage = (error as? RequestError)?.errorString ?? error.localizedDescription
                    isShowToast = true
                }
            } receiveValue: { response in
                self.trackData = response
            }
            .store(in: &cancellables)
    }

    private func timelineItem(title: String, time: String, isCompleted: Bool, isCurrent: Bool, isLast: Bool = false) -> some View {
        HStack(alignment: .top, spacing: 10) {
            VStack(spacing: 0) {
                if isCompleted {
                    Circle().fill(Color.spicePrimary).frame(width: 11, height: 11)
                } else if isCurrent {
                    Circle().stroke(Color.spiceTransit, lineWidth: 3).background(Circle().fill(Color.white)).frame(width: 12, height: 12)
                } else {
                    Circle().stroke(Color.spiceMuted.opacity(0.4), lineWidth: 1.5).frame(width: 10, height: 10)
                }

                if !isLast {
                    Rectangle()
                        .fill(isCompleted ? Color.spicePrimary : Color.spiceCardBorder)
                        .frame(width: 2, height: 22)
                }
            }

            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.system(size: 11.5, weight: isCurrent ? .heavy : .bold))
                    .foregroundColor(isCurrent ? Color.spiceTransit : (isCompleted ? Color.spiceInk : Color.spiceMuted))
                Text(time)
                    .font(.system(size: 9.5, weight: .medium, design: .monospaced))
                    .foregroundColor(isCurrent ? Color.spiceTransit : Color.spiceMuted)
            }
            Spacer()
        }
    }
}
