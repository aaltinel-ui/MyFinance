#!/usr/bin/env python3
"""
MyFinance — PDF Hisse Hareketi Yükleyici
-----------------------------------------
Yapı Kredi Yatırım İşlem Sonuç Formu PDF'lerini okuyup
Firestore'a Transaction olarak kaydeder.

Kurulum:
  pip install firebase-admin pdfplumber

Kullanım:
  python3 pdf_to_firestore.py <pdf_dosyasi> [--service-account <json_yolu>]

Örnekler:
  python3 pdf_to_firestore.py Hisse_Mayis_18.PDF
  python3 pdf_to_firestore.py Hisse_Mayis_18.PDF --service-account /path/to/serviceAccount.json
"""

import argparse
import re
import sys
import uuid
from datetime import datetime, timezone
from pathlib import Path

try:
    import pdfplumber
except ImportError:
    sys.exit("❌ pdfplumber bulunamadı. Kur: pip install pdfplumber")

try:
    import firebase_admin
    from firebase_admin import credentials, firestore
except ImportError:
    sys.exit("❌ firebase-admin bulunamadı. Kur: pip install firebase-admin")


# ── PDF PARSE ─────────────────────────────────────────────────────────────────

def parse_date(text: str) -> datetime:
    """18/05/2026 → datetime (UTC)"""
    return datetime.strptime(text.strip(), "%d/%m/%Y").replace(tzinfo=timezone.utc)


def parse_number(text: str) -> float:
    """'53.747,20' veya '88,40' → float"""
    return float(text.strip().replace(".", "").replace(",", "."))


def parse_pdf(pdf_path: str) -> list[dict]:
    """
    Yapı Kredi İşlem Sonuç Formu PDF'inden hisse hareketlerini çıkarır.
    Her satır için bir dict döner.
    """
    records = []

    with pdfplumber.open(pdf_path) as pdf:
        full_text = "\n".join(page.extract_text() or "" for page in pdf.pages)

    # Her işlem satırı: tarih  valör  cinsi  kodu  yer  alis/satis  adet  fiyat  tutar  komisyon
    # Örnek: 18/05/2026 21/05/2026 Pay Senedi FROTO - FORD OTOMOTİV... BORSA İSTANBUL MÜŞTERİDEN ALIŞ 608,000 88,40 53.747,20 112,30
    pattern = re.compile(
        r"(\d{2}/\d{2}/\d{4})\s+"       # işlem tarihi
        r"\d{2}/\d{2}/\d{4}\s+"          # valör tarihi (atla)
        r"Pay Senedi\s+"                  # cinsi
        r"([A-Z0-9]+)\s*-\s*([^\n]+?)\s+" # hisse kodu + açıklama
        r"BORSA İSTANBUL[^\n]*?\s+"       # gerçekleşme yeri
        r"(ALIŞ|SATIŞ)\s+"               # alış/satış
        r"([\d.,]+)\s+"                   # adet
        r"([\d.,]+)\s+"                   # fiyat
        r"([\d.,]+)\s+"                   # tutar
        r"([\d.,]+)",                     # komisyon
        re.IGNORECASE | re.MULTILINE
    )

    for m in pattern.finditer(full_text):
        islem_tarihi, kod, aciklama, alis_satis, adet_str, fiyat_str, tutar_str, komisyon_str = m.groups()

        yon    = "Alındı" if alis_satis.upper() == "ALIŞ" else "Satıldı"
        adet   = parse_number(adet_str)
        fiyat  = parse_number(fiyat_str)
        tutar  = parse_number(tutar_str)
        tarih  = parse_date(islem_tarihi)

        records.append({
            "id":              str(uuid.uuid4()),
            "tarih":           tarih,
            "kasaTip":         "Birikim",
            "islem":           kod.strip(),
            "tip":             "HİSSE",
            "nerede":          "Banka",
            "guncellenecekMi": True,
            "yon":             yon,
            "birimFiyat":      fiyat,
            "adet":            adet,
            "tutarTL":         tutar,
            "notlar":          aciklama.strip(),
        })

    return records


# ── FIRESTORE UPLOAD ──────────────────────────────────────────────────────────

def upload(records: list[dict], sa_path: str):
    if not firebase_admin._apps:
        cred = credentials.Certificate(sa_path)
        firebase_admin.initialize_app(cred)

    db  = firestore.client()
    col = db.collection("transactions")

    for r in records:
        doc_id = f"{r['islem']}-{r['yon'].lower()}-{r['tarih'].strftime('%Y%m%d')}-{r['id'][:8]}"
        col.document(doc_id).set(r, merge=True)
        print(f"  ✓ {doc_id}  |  {r['islem']} {r['yon']}  {r['adet']} adet @ {r['birimFiyat']} TL")


# ── CLI ───────────────────────────────────────────────────────────────────────

def main():
    parser = argparse.ArgumentParser(description="Hisse PDF → Firestore")
    parser.add_argument("pdf", help="PDF dosyasının yolu")
    parser.add_argument("--service-account", default="serviceAccount.json",
                        help="Firebase service account JSON (varsayılan: serviceAccount.json)")
    args = parser.parse_args()

    pdf_path = Path(args.pdf)
    if not pdf_path.exists():
        sys.exit(f"❌ Dosya bulunamadı: {pdf_path}")

    sa_path = Path(args.service_account)
    if not sa_path.exists():
        sys.exit(f"❌ Service account bulunamadı: {sa_path}\n"
                 "   Firebase Console → Proje Ayarları → Hizmet Hesapları → Yeni özel anahtar oluştur")

    print(f"\n📄 PDF okunuyor: {pdf_path.name}")
    records = parse_pdf(str(pdf_path))

    if not records:
        sys.exit("❌ PDF'de işlem satırı bulunamadı. Dosya formatı farklı olabilir.")

    print(f"✅ {len(records)} işlem bulundu\n")
    print("☁️  Firestore'a yükleniyor...")
    upload(records, str(sa_path))
    print(f"\n🎉 {len(records)} işlem başarıyla Firestore'a eklendi.")


if __name__ == "__main__":
    main()
