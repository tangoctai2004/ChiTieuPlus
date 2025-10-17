//
//  IconProvider.swift
//  QuanLyChiTieu
//
//  Created by Tạ Ngọc Tài on 17/10/25.
//

import SwiftUI

struct IconProvider {
    struct IconInfo: Identifiable, Hashable {
        let id = UUID()
        let iconName: String
        let color: Color
    }

    static let allIcons: [IconInfo] = [
      IconInfo(iconName: "house.fill", color: .orange),
      IconInfo(iconName: "cart.fill", color: .green),
      IconInfo(iconName: "fork.knife", color: .yellow),
      IconInfo(iconName: "bus.fill", color: .blue),
      IconInfo(iconName: "bolt.fill", color: .yellow),
      IconInfo(iconName: "drop.fill", color: .cyan),
      IconInfo(iconName: "phone.fill", color: .indigo),
      IconInfo(iconName: "wifi", color: .blue),
      IconInfo(iconName: "fuelpump.fill", color: .black),
      IconInfo(iconName: "heart.text.square.fill", color: .red),
      IconInfo(iconName: "tshirt.fill", color: .pink),
      IconInfo(iconName: "pills.fill", color: .mint),
      IconInfo(iconName: "graduationcap.fill", color: .teal),
      IconInfo(iconName: "scissors", color: .gray),
      IconInfo(iconName: "pawprint.fill", color: .brown),
      IconInfo(iconName: "gym.bag.fill", color: .purple),
      IconInfo(iconName: "books.vertical.fill", color: .brown),
      IconInfo(iconName: "wrench.and.screwdriver.fill", color: .gray),
      IconInfo(iconName: "hand.raised.fingers.spread.fill", color: .orange),
      IconInfo(iconName: "person.2.fill", color: .blue),
      IconInfo(iconName: "gift.fill", color: .red),
      IconInfo(iconName: "gamecontroller.fill", color: .purple),
      IconInfo(iconName: "film.fill", color: .indigo),
      IconInfo(iconName: "music.mic", color: .pink),
      IconInfo(iconName: "cup.and.saucer.fill", color: .brown),
      IconInfo(iconName: "airplane", color: .blue),
      IconInfo(iconName: "party.popper.fill", color: .yellow),
      IconInfo(iconName: "wineglass.fill", color: .purple),
      IconInfo(iconName: "ticket.fill", color: .orange),
      IconInfo(iconName: "tree.fill", color: .green),
      IconInfo(iconName: "doc.text.fill", color: .gray),
      IconInfo(iconName: "creditcard.fill", color: .mint),
      IconInfo(iconName: "building.columns.fill", color: .brown),
      IconInfo(iconName: "arrow.up.forward.app.fill", color: .red),
      IconInfo(iconName: "questionmark.circle.fill", color: .gray),
      IconInfo(iconName: "arrow.down.to.line.compact", color: .red),
      IconInfo(iconName: "heart.circle.fill", color: .pink),
      IconInfo(iconName: "briefcase.fill", color: .brown),
      IconInfo(iconName: "shippingbox.fill", color: .orange),
      IconInfo(iconName: "banknote.fill", color: .green),
      IconInfo(iconName: "dollarsign.circle.fill", color: .green),
      IconInfo(iconName: "chart.line.uptrend.xyaxis", color: .cyan),
      IconInfo(iconName: "arrow.up.right.circle.fill", color: .blue),
      IconInfo(iconName: "bag.fill", color: .orange),
      IconInfo(iconName: "person.3.fill", color: .teal),
      IconInfo(iconName: "lightbulb.fill", color: .yellow),
      IconInfo(iconName: "giftcard.fill", color: .red),
      IconInfo(iconName: "arrow.left.arrow.right.circle.fill", color: .purple),
      IconInfo(iconName: "plus.circle.fill", color: .green),
      IconInfo(iconName: "camera.fill", color: .black),
      IconInfo(iconName: "headphones", color: .purple),
      IconInfo(iconName: "desktopcomputer", color: .blue),
      IconInfo(iconName: "bed.double.fill", color: .brown),
      IconInfo(iconName: "leaf.fill", color: .green),
      IconInfo(iconName: "flame.fill", color: .red),
      IconInfo(iconName: "car.fill", color: .purple),
      // ... thêm các icon khác nếu bạn muốn
    ]

    static func color(for iconName: String?) -> Color {
        guard let iconName = iconName else { return .primary }
        return allIcons.first { $0.iconName == iconName }?.color ?? .primary
    }
}
