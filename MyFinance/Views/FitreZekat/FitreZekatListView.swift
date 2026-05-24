import SwiftUI
import SwiftData

struct FitreZekatListView: View {
    @Query(sort: \FitreZekat.tarih, order: .reverse) private var records: [FitreZekat]
    @Environment(\.modelContext) private var context
    @State private var showingAddSheet = false
    @State private var showingDeleteAlert = false
    @State private var recordToDelete: FitreZekat?
    @State private var searchText = ""
    @State private var selectedTur: String?

    private var totalAmount: Double { records.reduce(0) { $0 + $1.tutar } }
    private var fitreToplam: Double { records.filter { $0.tur == FitreZekatTur.fitre.rawValue }.reduce(0) { $0 + $1.tutar } }
    private var zekatToplam: Double { records.filter { $0.tur == FitreZekatTur.zekat.rawValue }.reduce(0) { $0 + $1.tutar } }

    private var filteredRecords: [FitreZekat] {
        records.filter { rec in
            let matchesSearch = searchText.isEmpty ||
                rec.kisiAdi.localizedCaseInsensitiveContains(searchText) ||
                rec.aciklama.localizedCaseInsensitiveContains(searchText)
            let matchesTur = selectedTur == nil || rec.tur == selectedTur
            return matchesSearch && matchesTur
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Summary
                VStack(spacing: 12) {
                    CardView {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Toplam").font(.subheadline).foregroundStyle(.secondary)
                            Text(Formatters.formatCurrency(totalAmount)).font(.largeTitle).fontWeight(.bold)
                        }
                    }
                    HStack(spacing: 12) {
                        SummaryCardView(title: "Fitre", value: Formatters.formatCurrency(fitreToplam), icon: "hand.raised.fill", color: .green)
                        SummaryCardView(title: "Zekât", value: Formatters.formatCurrency(zekatToplam), icon: "heart.circle.fill", color: .teal)
                    }
                }

                // Filter
                Picker("Tür", selection: Binding(
                    get: { selectedTur ?? "Tümü" },
                    set: { selectedTur = $0 == "Tümü" ? nil : $0 }
                )) {
                    Text("Tümü").tag("Tümü")
                    ForEach(FitreZekatTur.allCases) { tur in
                        Text(tur.rawValue).tag(tur.rawValue)
                    }
                }
                .pickerStyle(.segmented)

                // List
                CardView {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Kayıtlar (\(filteredRecords.count))")
                            .font(.headline)

                        if filteredRecords.isEmpty {
                            Text("Kayıt bulunamadı")
                                .font(.subheadline).foregroundStyle(.secondary)
                                .frame(maxWidth: .infinity, alignment: .center)
                                .padding(.vertical, 20)
                        } else {
                            ForEach(filteredRecords) { rec in
                                NavigationLink(destination: FitreZekatDetailView(record: rec)) {
                                    recordRow(rec)
                                }
                                .buttonStyle(.plain)
                                .contextMenu {
                                    Button(role: .destructive) {
                                        recordToDelete = rec
                                        showingDeleteAlert = true
                                    } label: {
                                        Label("Sil", systemImage: "trash")
                                    }
                                }
                                if rec.id != filteredRecords.last?.id {
                                    Divider()
                                }
                            }
                        }
                    }
                }
            }
            .padding()
        }
        .searchable(text: $searchText, prompt: "Kayıt ara...")
        .toolbar {
            ToolbarItem(placement: .automatic) {
                Button { showingAddSheet = true } label: {
                    Label("Ekle", systemImage: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAddSheet) {
            FitreZekatFormView()
        }
        .alert("Kaydı Sil", isPresented: $showingDeleteAlert) {
            Button("İptal", role: .cancel) { recordToDelete = nil }
            Button("Sil", role: .destructive) {
                if let rec = recordToDelete {
                    context.delete(rec)
                    recordToDelete = nil
                }
            }
        } message: {
            Text("Bu kayıt kalıcı olarak silinecek.")
        }
    }

    private func recordRow(_ rec: FitreZekat) -> some View {
        HStack {
            if let tur = FitreZekatTur(rawValue: rec.tur) {
                Image(systemName: tur.icon)
                    .font(.title3)
                    .foregroundStyle(Color(tur.color))
                    .frame(width: 32)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(rec.kisiAdi)
                    .font(.body).fontWeight(.medium)
                HStack(spacing: 6) {
                    Text(rec.tur)
                        .font(.subheadline)
                        .padding(.horizontal, 8).padding(.vertical, 2)
                        .background(rec.tur == "Fitre" ? Color.green.opacity(0.15) : Color.teal.opacity(0.15))
                        .clipShape(Capsule())
                    if !rec.aciklama.isEmpty {
                        Text(rec.aciklama)
                            .font(.subheadline).foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                    Text(Formatters.formatDate(rec.tarih))
                        .font(.subheadline).foregroundStyle(.secondary)
                }
            }
            Spacer()
            Text(Formatters.formatCurrency(rec.tutar))
                .font(.body).fontWeight(.medium)
        }
        .padding(.vertical, 4)
    }
}

struct FitreZekatDetailView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    let record: FitreZekat
    @State private var showingEditSheet = false
    @State private var showingDeleteAlert = false

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                CardView {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Kayıt Detayı").font(.headline)
                        detailRow("Tür", record.tur)
                        detailRow("Kişi", record.kisiAdi)
                        detailRow("Tutar", Formatters.formatCurrency(record.tutar))
                        detailRow("Tarih", Formatters.formatDate(record.tarih))
                        if !record.aciklama.isEmpty {
                            detailRow("Açıklama", record.aciklama)
                        }
                        if let notlar = record.notlar, !notlar.isEmpty {
                            Divider()
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Notlar").font(.subheadline).foregroundStyle(.secondary)
                                Text(notlar).font(.body)
                            }
                        }
                    }
                }

                VStack(spacing: 12) {
                    Button { showingEditSheet = true } label: {
                        Label("Düzenle", systemImage: "pencil")
                            .frame(maxWidth: .infinity).padding()
                            .background(Color.accentColor).foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    Button(role: .destructive) { showingDeleteAlert = true } label: {
                        Label("Sil", systemImage: "trash")
                            .frame(maxWidth: .infinity).padding()
                            .background(Color.red.opacity(0.1)).foregroundStyle(.red)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Kayıt Detayı")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingEditSheet) { FitreZekatFormView(record: record) }
        .alert("Kaydı Sil", isPresented: $showingDeleteAlert) {
            Button("İptal", role: .cancel) {}
            Button("Sil", role: .destructive) { context.delete(record); dismiss() }
        } message: {
            Text("Bu kayıt kalıcı olarak silinecek.")
        }
    }

    private func detailRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label).font(.subheadline).foregroundStyle(.secondary)
            Spacer()
            Text(value).font(.body).fontWeight(.medium)
        }
    }
}
