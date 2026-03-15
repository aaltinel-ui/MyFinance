import SwiftUI

struct CardView<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding()
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
    }
}

struct SummaryCardView: View {
    let title: String
    let value: String
    let subtitle: String?
    let icon: String
    let color: Color

    init(title: String, value: String, subtitle: String? = nil, icon: String, color: Color) {
        self.title = title
        self.value = value
        self.subtitle = subtitle
        self.icon = icon
        self.color = color
    }

    var body: some View {
        CardView {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(value)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(.primary)
                    if let subtitle {
                        Text(subtitle)
                            .font(.caption)
                            .foregroundStyle(subtitle.contains("+") ? .green : subtitle.contains("-") ? .red : .secondary)
                    }
                }
                Spacer()
                Image(systemName: icon)
                    .font(.title)
                    .foregroundStyle(color)
            }
        }
    }
}

struct KZBadge: View {
    let value: Double
    let percentage: Double

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: value >= 0 ? "arrow.up.right" : "arrow.down.right")
                .font(.caption2)
            Text(Formatters.formatCurrency(abs(value)))
                .font(.caption)
                .fontWeight(.semibold)
            Text("(\(Formatters.formatPercent(percentage)))")
                .font(.caption2)
        }
        .foregroundStyle(value >= 0 ? .green : .red)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(value >= 0 ? Color.green.opacity(0.1) : Color.red.opacity(0.1))
        .clipShape(Capsule())
    }
}

struct ProgressBarView: View {
    let label: String
    let value: Double
    let total: Double
    let color: Color

    var ratio: Double { total > 0 ? value / total : 0 }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(label)
                    .font(.subheadline)
                Spacer()
                Text(Formatters.formatCurrency(value))
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text("(%\(Int(ratio * 100)))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(color.opacity(0.15))
                    RoundedRectangle(cornerRadius: 4)
                        .fill(color)
                        .frame(width: geo.size.width * ratio)
                }
            }
            .frame(height: 8)
        }
    }
}
