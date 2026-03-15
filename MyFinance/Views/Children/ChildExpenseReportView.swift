import SwiftUI
import SwiftData
import Charts

struct ChildExpenseReportView: View {
    @Query(sort: \ChildExpense.tarih, order: .reverse) private var expenses: [ChildExpense]

    private var byChild: [(cocuk: String, tutarTL: Double, tutarEUR: Double, kayitSayisi: Int)] {
        Dictionary(grouping: expenses, by: \.cocukAdi)
            .map { (cocuk: $0.key, tutarTL: $0.value.reduce(0) { $0 + $1.tutar }, tutarEUR: $0.value.reduce(0) { $0 + $1.eurDegeri }, kayitSayisi: $0.value.count) }
            .sorted { $0.tutarTL > $1.tutarTL }
    }

    private var byCategory: [(kategori: String, tutarTL: Double, tutarEUR: Double)] {
        Dictionary(grouping: expenses, by: \.kategori)
            .map { (kategori: $0.key, tutarTL: $0.value.reduce(0) { $0 + $1.tutar }, tutarEUR: $0.value.reduce(0) { $0 + $1.eurDegeri }) }
            .sorted { $0.tutarTL > $1.tutarTL }
    }

    private var byYear: [(yil: Int, tutarTL: Double, tutarEUR: Double)] {
        Dictionary(grouping: expenses, by: \.yil)
            .map { (yil: $0.key, tutarTL: $0.value.reduce(0) { $0 + $1.tutar }, tutarEUR: $0.value.reduce(0) { $0 + $1.eurDegeri }) }
            .sorted { $0.yil > $1.yil }
    }

    private var totalTL: Double { expenses.reduce(0) { $0 + $1.tutar } }
    private var totalEUR: Double { expenses.reduce(0) { $0 + $1.eurDegeri } }

    private let childColors: [Color] = [.purple, .blue, .pink, .orange, .teal, .indigo]

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Summary
                CardView {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Genel Özet").font(.headline)
                        HStack(spacing: 20) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Toplam TL").font(.caption).foregroundStyle(.secondary)
                                Text(Formatters.formatCurrency(totalTL)).font(.title2).fontWeight(.bold)
                            }
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Toplam EUR").font(.caption).foregroundStyle(.secondary)
                                Text("€\(Int(totalEUR))").font(.title2).fontWeight(.bold).foregroundStyle(.blue)
                            }
                        }
                        HStack {
                            Text("\(expenses.count) kayıt").font(.subheadline).foregroundStyle(.secondary)
                            Text("•")
                            Text("\(byChild.count) çocuk").font(.subheadline).foregroundStyle(.secondary)
                        }
                    }
                }

                // Yıl bazlı tablo
                if !byYear.isEmpty {
                    CardView {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Yıl Bazlı Özet").font(.title3).fontWeight(.bold)
                            ForEach(byYear, id: \.yil) { item in
                                HStack {
                                    Text(String(item.yil)).font(.body).fontWeight(.medium)
                                    Spacer()
                                    VStack(alignment: .trailing, spacing: 2) {
                                        Text(Formatters.formatCurrency(item.tutarTL)).font(.body).fontWeight(.medium)
                                        Text("€\(Int(item.tutarEUR))").font(.caption).foregroundStyle(.blue)
                                    }
                                }
                                if item.yil != byYear.last?.yil {
                                    Divider()
                                }
                            }
                        }
                    }
                }

                // By Child pie chart
                if !byChild.isEmpty {
                    CardView {
                        VStack(alignment: .leading, spacing: 14) {
                            Text("Çocuk Bazlı Dağılım").font(.title3).fontWeight(.bold)
                            Chart(byChild, id: \.cocuk) { item in
                                SectorMark(
                                    angle: .value("Tutar", item.tutarTL),
                                    innerRadius: .ratio(0.55),
                                    angularInset: 2
                                )
                                .foregroundStyle(childColors[byChild.firstIndex(where: { $0.cocuk == item.cocuk })! % childColors.count])
                                .annotation(position: .overlay) {
                                    let pct = totalTL > 0 ? item.tutarTL / totalTL * 100 : 0
                                    if pct > 8 {
                                        VStack(spacing: 2) {
                                            Text(item.cocuk).font(.caption).fontWeight(.bold)
                                            Text("%\(Int(pct))").font(.caption2)
                                        }
                                        .foregroundStyle(.white)
                                    }
                                }
                            }
                            .frame(height: 240)

                            // Tıklanabilir çocuk listesi
                            ForEach(Array(byChild.enumerated()), id: \.element.cocuk) { idx, item in
                                let pct = totalTL > 0 ? item.tutarTL / totalTL * 100 : 0
                                NavigationLink(destination: ChildDetailReportView(cocukAdi: item.cocuk)) {
                                    HStack {
                                        Circle().fill(childColors[idx % childColors.count]).frame(width: 10, height: 10)
                                        Text(item.cocuk).font(.body)
                                        Spacer()
                                        Text("%\(Int(pct))").font(.subheadline).foregroundStyle(.secondary)
                                        VStack(alignment: .trailing, spacing: 2) {
                                            Text(Formatters.formatCurrency(item.tutarTL)).font(.body).fontWeight(.medium)
                                            Text("€\(Int(item.tutarEUR))").font(.caption).foregroundStyle(.blue)
                                        }
                                        Image(systemName: "chevron.right")
                                            .font(.caption).foregroundStyle(.secondary)
                                    }
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }

                // By Category pie chart
                if !byCategory.isEmpty {
                    CardView {
                        VStack(alignment: .leading, spacing: 14) {
                            Text("Kategori Bazlı Dağılım").font(.title3).fontWeight(.bold)
                            Chart(byCategory, id: \.kategori) { item in
                                SectorMark(
                                    angle: .value("Tutar", item.tutarTL),
                                    innerRadius: .ratio(0.55),
                                    angularInset: 2
                                )
                                .foregroundStyle(categoryColor(item.kategori))
                                .annotation(position: .overlay) {
                                    let pct = totalTL > 0 ? item.tutarTL / totalTL * 100 : 0
                                    if pct > 8 {
                                        VStack(spacing: 2) {
                                            Text(item.kategori).font(.caption).fontWeight(.bold)
                                            Text("%\(Int(pct))").font(.caption2)
                                        }
                                        .foregroundStyle(.white)
                                    }
                                }
                            }
                            .frame(height: 240)

                            ForEach(byCategory, id: \.kategori) { item in
                                let pct = totalTL > 0 ? item.tutarTL / totalTL * 100 : 0
                                HStack {
                                    if let kat = CocukHarcamaKategori(rawValue: item.kategori) {
                                        Image(systemName: kat.icon).font(.subheadline).foregroundStyle(categoryColor(item.kategori))
                                    }
                                    Text(item.kategori).font(.body)
                                    Spacer()
                                    Text("%\(Int(pct))").font(.subheadline).foregroundStyle(.secondary)
                                    VStack(alignment: .trailing, spacing: 2) {
                                        Text(Formatters.formatCurrency(item.tutarTL)).font(.body).fontWeight(.medium)
                                        Text("€\(Int(item.tutarEUR))").font(.caption).foregroundStyle(.blue)
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Çocuk Harcama Raporları")
    }

    private func categoryColor(_ kategori: String) -> Color {
        if let kat = CocukHarcamaKategori(rawValue: kategori) {
            return Color(kat.color)
        }
        return .secondary
    }
}

// MARK: - Çocuk Detay Raporu

struct ChildDetailReportView: View {
    let cocukAdi: String
    @Query(sort: \ChildExpense.tarih, order: .reverse) private var allExpenses: [ChildExpense]

    private var expenses: [ChildExpense] {
        allExpenses.filter { $0.cocukAdi == cocukAdi }
    }

    private var totalTL: Double { expenses.reduce(0) { $0 + $1.tutar } }
    private var totalEUR: Double { expenses.reduce(0) { $0 + $1.eurDegeri } }

    private var byCategory: [(kategori: String, tutarTL: Double, tutarEUR: Double, kayitSayisi: Int)] {
        Dictionary(grouping: expenses, by: \.kategori)
            .map { (kategori: $0.key, tutarTL: $0.value.reduce(0) { $0 + $1.tutar }, tutarEUR: $0.value.reduce(0) { $0 + $1.eurDegeri }, kayitSayisi: $0.value.count) }
            .sorted { $0.tutarTL > $1.tutarTL }
    }

    private var byYear: [(yil: Int, tutarTL: Double, tutarEUR: Double, kayitSayisi: Int)] {
        Dictionary(grouping: expenses, by: \.yil)
            .map { (yil: $0.key, tutarTL: $0.value.reduce(0) { $0 + $1.tutar }, tutarEUR: $0.value.reduce(0) { $0 + $1.eurDegeri }, kayitSayisi: $0.value.count) }
            .sorted { $0.yil > $1.yil }
    }

    private let categoryColors: [Color] = [.blue, .red, .purple, .orange, .pink, .teal, .indigo, .cyan, .mint, .brown, .green, .gray]

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Özet kartı
                CardView {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "person.fill")
                                .font(.title2).foregroundStyle(.purple)
                            Text(cocukAdi).font(.title2).fontWeight(.bold)
                        }
                        Divider()
                        HStack(spacing: 20) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Toplam TL").font(.caption).foregroundStyle(.secondary)
                                Text(Formatters.formatCurrency(totalTL)).font(.title3).fontWeight(.bold)
                            }
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Toplam EUR").font(.caption).foregroundStyle(.secondary)
                                Text("€\(Int(totalEUR))").font(.title3).fontWeight(.bold).foregroundStyle(.blue)
                            }
                            Spacer()
                            VStack(alignment: .trailing, spacing: 4) {
                                Text("\(expenses.count)").font(.title3).fontWeight(.bold)
                                Text("kayıt").font(.caption).foregroundStyle(.secondary)
                            }
                        }
                        if totalEUR > 0 {
                            HStack {
                                Text("Ortalama Kur").font(.caption).foregroundStyle(.secondary)
                                Spacer()
                                Text(String(format: "%.2f ₺/€", totalTL / totalEUR)).font(.subheadline).fontWeight(.medium)
                            }
                        }
                    }
                }

                // Kategori bazlı pie chart
                if !byCategory.isEmpty {
                    CardView {
                        VStack(alignment: .leading, spacing: 14) {
                            Text("Kategori Bazlı Dağılım").font(.title3).fontWeight(.bold)
                            Chart(byCategory, id: \.kategori) { item in
                                SectorMark(
                                    angle: .value("Tutar", item.tutarTL),
                                    innerRadius: .ratio(0.55),
                                    angularInset: 2
                                )
                                .foregroundStyle(categoryColorAt(item.kategori))
                                .annotation(position: .overlay) {
                                    let pct = totalTL > 0 ? item.tutarTL / totalTL * 100 : 0
                                    if pct > 8 {
                                        VStack(spacing: 2) {
                                            Text(item.kategori).font(.caption).fontWeight(.bold)
                                            Text("%\(Int(pct))").font(.caption2)
                                            Text(Formatters.formatCurrency(item.tutarTL)).font(.caption2)
                                        }
                                        .foregroundStyle(.white)
                                    }
                                }
                            }
                            .frame(height: 260)

                            ForEach(Array(byCategory.enumerated()), id: \.element.kategori) { idx, item in
                                let pct = totalTL > 0 ? item.tutarTL / totalTL * 100 : 0
                                HStack {
                                    if let kat = CocukHarcamaKategori(rawValue: item.kategori) {
                                        Image(systemName: kat.icon).font(.subheadline).foregroundStyle(categoryColorAt(item.kategori))
                                    } else {
                                        Circle().fill(categoryColors[idx % categoryColors.count]).frame(width: 10, height: 10)
                                    }
                                    Text(item.kategori).font(.body)
                                    Text("(\(item.kayitSayisi))").font(.caption).foregroundStyle(.secondary)
                                    Spacer()
                                    Text("%\(Int(pct))").font(.subheadline).foregroundStyle(.secondary)
                                    VStack(alignment: .trailing, spacing: 2) {
                                        Text(Formatters.formatCurrency(item.tutarTL)).font(.body).fontWeight(.medium)
                                        Text("€\(Int(item.tutarEUR))").font(.caption).foregroundStyle(.blue)
                                    }
                                }
                            }
                        }
                    }
                }

                // Yıl bazlı bar chart
                if !byYear.isEmpty {
                    CardView {
                        VStack(alignment: .leading, spacing: 14) {
                            Text("Yıl Bazlı Harcamalar").font(.title3).fontWeight(.bold)
                            Chart(byYear, id: \.yil) { item in
                                BarMark(
                                    x: .value("Yıl", String(item.yil)),
                                    y: .value("Tutar", item.tutarTL)
                                )
                                .foregroundStyle(.purple.gradient)
                                .annotation(position: .top) {
                                    Text(Formatters.formatCurrency(item.tutarTL))
                                        .font(.caption2).foregroundStyle(.secondary)
                                }
                            }
                            .frame(height: 200)

                            ForEach(byYear, id: \.yil) { item in
                                let pct = totalTL > 0 ? item.tutarTL / totalTL * 100 : 0
                                HStack {
                                    Text(String(item.yil)).font(.body).fontWeight(.medium)
                                    Text("(\(item.kayitSayisi) kayıt)").font(.caption).foregroundStyle(.secondary)
                                    Spacer()
                                    Text("%\(Int(pct))").font(.subheadline).foregroundStyle(.secondary)
                                    VStack(alignment: .trailing, spacing: 2) {
                                        Text(Formatters.formatCurrency(item.tutarTL)).font(.body).fontWeight(.medium)
                                        Text("€\(Int(item.tutarEUR))").font(.caption).foregroundStyle(.blue)
                                    }
                                }
                                if item.yil != byYear.last?.yil {
                                    Divider()
                                }
                            }
                        }
                    }
                }

                // Son harcamalar listesi
                CardView {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Son Harcamalar").font(.title3).fontWeight(.bold)
                        ForEach(expenses.prefix(10)) { exp in
                            HStack {
                                if let kat = CocukHarcamaKategori(rawValue: exp.kategori) {
                                    Image(systemName: kat.icon)
                                        .font(.subheadline)
                                        .foregroundStyle(Color(kat.color))
                                        .frame(width: 24)
                                }
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(exp.aciklama).font(.subheadline).lineLimit(1)
                                    Text(Formatters.formatDate(exp.tarih)).font(.caption).foregroundStyle(.secondary)
                                }
                                Spacer()
                                VStack(alignment: .trailing, spacing: 2) {
                                    Text(Formatters.formatCurrency(exp.tutar)).font(.subheadline).fontWeight(.medium)
                                    if exp.eurDegeri > 0 {
                                        Text("€\(Int(exp.eurDegeri))").font(.caption).foregroundStyle(.blue)
                                    }
                                }
                            }
                            if exp.id != expenses.prefix(10).last?.id {
                                Divider()
                            }
                        }
                    }
                }
            }
            .padding()
        }
        .navigationTitle(cocukAdi)
        .navigationBarTitleDisplayMode(.inline)
    }

    private func categoryColorAt(_ kategori: String) -> Color {
        if let kat = CocukHarcamaKategori(rawValue: kategori) {
            return Color(kat.color)
        }
        if let idx = byCategory.firstIndex(where: { $0.kategori == kategori }) {
            return categoryColors[idx % categoryColors.count]
        }
        return .secondary
    }
}
