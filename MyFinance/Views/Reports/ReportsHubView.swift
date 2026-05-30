import SwiftUI

// MARK: - Raporlar Hub
//
// MyFinans raporlarının listelendiği menü. Her satır bir rapora götürür.
// Yeni rapor eklemek için `ReportItem` dizisine bir giriş ekleyip
// hedef görünümü `destination` içinde tanımlamak yeterli.

struct ReportsHubView: View {
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 12) {
                    NavigationLink {
                        KasaReportView()
                    } label: {
                        reportCard(
                            title: "Kasa Bazlı Rapor",
                            subtitle: "Her kasanın değeri, dağılımı ve pozisyonları",
                            icon: "tray.2.fill",
                            color: .blue
                        )
                    }
                    .buttonStyle(.plain)

                    NavigationLink {
                        SaklamaReportView()
                    } label: {
                        reportCard(
                            title: "Saklama Bazlı Rapor",
                            subtitle: "Her saklama yerinin değeri, dağılımı ve pozisyonları",
                            icon: "archivebox.fill",
                            color: .orange
                        )
                    }
                    .buttonStyle(.plain)
                }
                .padding()
            }
            .navigationTitle("Raporlar")
        }
    }

    private func reportCard(title: String, subtitle: String, icon: String, color: Color) -> some View {
        CardView {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.12))
                        .frame(width: 44, height: 44)
                    Image(systemName: icon)
                        .font(.title3)
                        .foregroundStyle(color)
                }
                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.headline)
                        .foregroundStyle(.primary)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.body)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
