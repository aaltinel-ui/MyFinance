"""
MyFinance - Firestore Doğrudan Yükleme Scripti
----------------------------------------------
Kullanım:
  1. pip install firebase-admin
  2. SERVICE_ACCOUNT_PATH değişkenini kendi service account JSON dosyasının yoluyla değiştir
  3. python3 firestore_upload.py
"""

import firebase_admin
from firebase_admin import credentials, firestore
from datetime import datetime, timezone

# ── AYARLAR ──────────────────────────────────────────────────────────────────
SERVICE_ACCOUNT_PATH = "serviceAccount.json"   # <-- kendi dosya yolunu gir
# ─────────────────────────────────────────────────────────────────────────────

cred = credentials.Certificate(SERVICE_ACCOUNT_PATH)
firebase_admin.initialize_app(cred)
db = firestore.client()


def ts(year, month, day):
    """Tarih oluşturur (UTC gece yarısı)."""
    return datetime(year, month, day, tzinfo=timezone.utc)


def upsert(collection, doc_id, data):
    db.collection(collection).document(doc_id).set(data, merge=True)
    print(f"  ✓ {collection}/{doc_id}")


# ── KAYITLAR ─────────────────────────────────────────────────────────────────

print("\n=== Çocuk Harcamaları ===")
upsert("childExpenses", "ataberk-500-20260315", {
    "id":       "ataberk-500-20260315",
    "yil":      2026,
    "tarih":    ts(2026, 3, 15),
    "cocukAdi": "ATABERK",
    "kategori": "Diğer",
    "aciklama": "Harcama",
    "tutar":    500.0,
    "eurDegeri": 0.0,
    "kur":      0.0,
    "notlar":   ""
})

upsert("childExpenses", "ataberk-999-20260315", {
    "id":       "ataberk-999-20260315",
    "yil":      2026,
    "tarih":    ts(2026, 3, 15),
    "cocukAdi": "ATABERK",
    "kategori": "Eğitim",
    "aciklama": "Eğitim Harcaması",
    "tutar":    999.0,
    "eurDegeri": 0.0,
    "kur":      0.0,
    "notlar":   ""
})

upsert("childExpenses", "alpay-500-20260315", {
    "id":       "alpay-500-20260315",
    "yil":      2026,
    "tarih":    ts(2026, 3, 15),
    "cocukAdi": "ALPAY",
    "kategori": "Diğer",
    "aciklama": "Harcama",
    "tutar":    500.0,
    "eurDegeri": 0.0,
    "kur":      0.0,
    "notlar":   ""
})

print("\n=== Borçlar ===")
upsert("debts", "aaaa-888-20260315", {
    "id":           "aaaa-888-20260315",
    "kpiAdi":       "aaaa",
    "tip":          "Nakit",
    "miktar":       1.0,
    "birimTutar":   888.0,
    "toplamTutar":  888.0,
    "paraBirimi":   "TL",
    "verilenTarih": ts(2026, 3, 15),
    "durum":        "Açık",
    "notlar":       "",
    "odemeler":     []
})

print("\n=== Hisse İşlemleri ===")
upsert("transactions", "froto-alis-20260518", {
    "id":             "froto-alis-20260518",
    "tarih":          ts(2026, 5, 18),
    "kasaTip":        "Birikim",
    "islem":          "FROTO",
    "tip":            "HİSSE",
    "nerede":         "Banka",
    "guncellenecekMi": True,
    "yon":            "Alındı",
    "birimFiyat":     88.40,
    "adet":           608.0,
    "tutarTL":        53747.20,
    "notlar":         "Ford Otomotiv Sanayi A.Ş. — Yapı Kredi Yatırım"
})

print("\n✅ Tüm kayıtlar Firestore'a yüklendi.")
