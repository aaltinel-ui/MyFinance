import SwiftUI

struct PrivacySettingsView: View {
    @AppStorage("isPrivacyEnabled") private var isPrivacyEnabled = false
    @AppStorage("hideBalances") private var hideBalances = false
    @AppStorage("isFaceIDEnabled") private var isFaceIDEnabled = false

    var body: some View {
        Form {
            Section("Gizlilik") {
                Toggle(isOn: $hideBalances) {
                    HStack {
                        Image(systemName: "eye.slash")
                            .foregroundStyle(.blue)
                        Text("Bakiyeleri Gizle")
                    }
                }

                Toggle(isOn: $isPrivacyEnabled) {
                    HStack {
                        Image(systemName: "lock.shield")
                            .foregroundStyle(.green)
                        Text("Uygulama Kilidi")
                    }
                }

                if isPrivacyEnabled {
                    Toggle(isOn: $isFaceIDEnabled) {
                        HStack {
                            Image(systemName: "faceid")
                                .foregroundStyle(.purple)
                            Text("Face ID / Touch ID ile Aç")
                        }
                    }
                }
            }

            Section {
                Text("Bakiyeleri gizle seçeneği aktifken portföy değerleri ve bakiyeler bulanık gösterilir.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Gizlilik Ayarları")
    }
}
