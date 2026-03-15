#!/bin/bash
# MyFinance - Komut Satırından Kayıt Ekleme Scripti
# Kullanım: ./scripts/add_record.sh <komut> <parametreler>
#
# ÖNEMLİ: Kayıt ekledikten sonra uygulamayı yeniden başlatın (arka plandan kapatıp açın)
# çünkü SwiftData çalışırken dışarıdan yapılan değişiklikleri görmez.

# Veritabanını bul
DB=$(find ~/Library/Developer/CoreSimulator/Devices -name "default.store" -path "*Application Support*" 2>/dev/null | while read f; do
    dir=$(dirname "$f")
    if sqlite3 "$f" "SELECT Z_NAME FROM Z_PRIMARYKEY WHERE Z_NAME='ChildExpense'" 2>/dev/null | grep -q "ChildExpense"; then
        echo "$f"
        break
    fi
done)

if [ -z "$DB" ]; then
    echo "❌ Veritabanı bulunamadı. Uygulamayı en az bir kez çalıştırın."
    exit 1
fi

# CoreData epoch: 2001-01-01 (Unix epoch + 978307200)
date_to_timestamp() {
    local dt="$1"
    python3 -c "
from datetime import datetime
epoch = datetime(2001, 1, 1)
d = datetime.strptime('$dt', '%Y-%m-%d')
print(int((d - epoch).total_seconds()))
"
}

# UUID oluştur (blob olarak)
make_uuid() {
    python3 -c "
import uuid
u = uuid.uuid4()
print(\"X'\" + u.hex.upper() + \"'\")
"
}

# Sonraki Z_PK değerini bul
next_pk() {
    local table="$1"
    local max=$(sqlite3 "$DB" "SELECT COALESCE(MAX(Z_PK), 0) FROM $table;")
    echo $((max + 1))
}

case "$1" in
    cocuk|child)
        # Çocuk harcaması ekle
        # Kullanım: ./add_record.sh cocuk "ATABERK" "Eğitim" "Okul taksiti" 5000 150 "2024-03-15" 2024
        COCUK="$2"
        KATEGORI="$3"
        ACIKLAMA="$4"
        TUTAR="${5:-0}"
        EUR="${6:-0}"
        TARIH="${7:-$(date +%Y-%m-%d)}"
        YIL="${8:-$(date +%Y)}"
        NOTLAR="${9}"

        TS=$(date_to_timestamp "$TARIH")
        UUID=$(make_uuid)
        PK=$(next_pk "ZCHILDEXPENSE")

        # Kur hesapla
        if [ "$EUR" != "0" ] && [ "$TUTAR" != "0" ]; then
            KUR=$(python3 -c "print(round($TUTAR / $EUR, 2))")
        else
            KUR=0
        fi

        sqlite3 "$DB" "INSERT INTO ZCHILDEXPENSE (Z_PK, Z_ENT, Z_OPT, ZYIL, ZEURDEGERI, ZKUR, ZTARIH, ZTUTAR, ZACIKLAMA, ZCOCUKADI, ZKATEGORI, ZNOTLAR, ZID) VALUES ($PK, 1, 1, $YIL, $EUR, $KUR, $TS, $TUTAR, '$ACIKLAMA', '$COCUK', '$KATEGORI', $([ -z "$NOTLAR" ] && echo "NULL" || echo "'$NOTLAR'"), $UUID);"

        echo "✅ Çocuk harcaması eklendi:"
        echo "   Çocuk: $COCUK | Kategori: $KATEGORI"
        echo "   Açıklama: $ACIKLAMA"
        echo "   Tutar: ₺$TUTAR | EUR: €$EUR | Kur: $KUR"
        echo "   Tarih: $TARIH | Yıl: $YIL"
        ;;

    borc|debt)
        # Borç ekle
        # Kullanım: ./add_record.sh borc "Baba" "Gram Altın" 10 4500 "TL" "2024-03-15"
        KIME="$2"
        TIP="$3"
        MIKTAR="${4:-1}"
        BIRIM="${5:-0}"
        PARABIRIMI="${6:-TL}"
        TARIH="${7:-$(date +%Y-%m-%d)}"
        NOTLAR="${8}"

        TS=$(date_to_timestamp "$TARIH")
        UUID=$(make_uuid)
        PK=$(next_pk "ZDEBT")
        TOPLAM=$(python3 -c "print($MIKTAR * $BIRIM)")

        sqlite3 "$DB" "INSERT INTO ZDEBT (Z_PK, Z_ENT, Z_OPT, ZMIKTAR, ZBIRIMTUTAR, ZTOPLAMTUTAR, ZVERILENTARIH, ZVERILENTUTAR, ZADET, ZBIRIMFIYAT, ZKPIADI, ZTIP, ZPARABIRIMI, ZDURUM, ZNOTLAR, ZID) VALUES ($PK, 2, 1, $MIKTAR, $BIRIM, $TOPLAM, $TS, $TOPLAM, $MIKTAR, $BIRIM, '$KIME', '$TIP', '$PARABIRIMI', 'Açık', $([ -z "$NOTLAR" ] && echo "NULL" || echo "'$NOTLAR'"), $UUID);"

        echo "✅ Borç kaydı eklendi:"
        echo "   Kime: $KIME | Tip: $TIP"
        echo "   Miktar: $MIKTAR x ₺$BIRIM = ₺$TOPLAM"
        echo "   Para Birimi: $PARABIRIMI | Tarih: $TARIH"
        ;;

    fitre|zekat)
        # Fitre/Zekât ekle
        # Kullanım: ./add_record.sh fitre "Fitre" "Ahmet Bey" 500 "Ramazan fitresi" "2024-03-15"
        TUR="$2"
        KISI="$3"
        TUTAR="${4:-0}"
        ACIKLAMA="${5}"
        TARIH="${6:-$(date +%Y-%m-%d)}"
        NOTLAR="${7}"

        TS=$(date_to_timestamp "$TARIH")
        UUID=$(make_uuid)
        PK=$(next_pk "ZFITREZEKAT")

        sqlite3 "$DB" "INSERT INTO ZFITREZEKAT (Z_PK, Z_ENT, Z_OPT, ZTARIH, ZTUTAR, ZACIKLAMA, ZKISIADI, ZTUR, ZNOTLAR, ZID) VALUES ($PK, 6, 1, $TS, $TUTAR, '$ACIKLAMA', '$KISI', '$TUR', $([ -z "$NOTLAR" ] && echo "NULL" || echo "'$NOTLAR'"), $UUID);"

        echo "✅ $TUR kaydı eklendi:"
        echo "   Kişi: $KISI | Tutar: ₺$TUTAR"
        echo "   Açıklama: $ACIKLAMA | Tarih: $TARIH"
        ;;

    list|liste)
        # Kayıtları listele
        TABLE="$2"
        case "$TABLE" in
            cocuk|child)
                echo "=== ÇOCUK HARCAMALARI ==="
                sqlite3 -header -column "$DB" "SELECT ZCOCUKADI as Cocuk, ZKATEGORI as Kategori, ZACIKLAMA as Aciklama, ZTUTAR as TutarTL, ZEURDEGERI as EUR, ZYIL as Yil FROM ZCHILDEXPENSE ORDER BY ZTARIH DESC LIMIT 20;"
                ;;
            borc|debt)
                echo "=== BORÇLAR ==="
                sqlite3 -header -column "$DB" "SELECT ZKPIADI as Kime, ZTIP as Tip, ZMIKTAR as Miktar, ZBIRIMTUTAR as BirimTutar, ZTOPLAMTUTAR as Toplam, ZDURUM as Durum FROM ZDEBT ORDER BY ZVERILENTARIH DESC LIMIT 20;"
                ;;
            fitre|zekat)
                echo "=== FİTRE/ZEKÂT ==="
                sqlite3 -header -column "$DB" "SELECT ZTUR as Tur, ZKISIADI as Kisi, ZTUTAR as Tutar, ZACIKLAMA as Aciklama FROM ZFITREZEKAT ORDER BY ZTARIH DESC LIMIT 20;"
                ;;
            *)
                echo "Kullanım: ./add_record.sh list [cocuk|borc|fitre]"
                ;;
        esac
        ;;

    help|yardim)
        echo "MyFinance Komut Satırı Aracı"
        echo "============================="
        echo ""
        echo "Kullanım:"
        echo "  ./scripts/add_record.sh <komut> <parametreler>"
        echo ""
        echo "Komutlar:"
        echo "  cocuk   \"Çocuk Adı\" \"Kategori\" \"Açıklama\" TutarTL EUR \"YYYY-MM-DD\" Yıl [Notlar]"
        echo "  borc    \"Kime\" \"Tip\" Miktar BirimTutar \"ParaBirimi\" \"YYYY-MM-DD\" [Notlar]"
        echo "  fitre   \"Tür\" \"Kişi Adı\" Tutar \"Açıklama\" \"YYYY-MM-DD\" [Notlar]"
        echo "  list    [cocuk|borc|fitre]"
        echo ""
        echo "Örnekler:"
        echo "  ./scripts/add_record.sh cocuk \"ATABERK\" \"Eğitim\" \"Okul taksiti\" 5000 150 \"2024-09-15\" 2024"
        echo "  ./scripts/add_record.sh cocuk \"NAZLI İREM\" \"Müzik\" \"Gitar dersi\" 700 20 \"2024-08-01\" 2024"
        echo "  ./scripts/add_record.sh borc \"Baba\" \"Gram Altın\" 50 4500 \"TL\" \"2024-03-15\""
        echo "  ./scripts/add_record.sh fitre \"Fitre\" \"Ahmet Bey\" 500 \"Ramazan fitresi\" \"2024-04-01\""
        echo "  ./scripts/add_record.sh list cocuk"
        echo ""
        echo "Kategoriler (Çocuk):"
        echo "  Eğitim, Sağlık, Giyim, Yiyecek, Oyuncak, Kurs, Müzik, Seyahat, Para Transferi, Ekipman, Harçlık, Diğer"
        echo ""
        echo "Borç Tipleri:"
        echo "  Gram Altın, Çeyrek Altın, Yarım Altın, Cumhuriyet Altın, Euro, USD, TL"
        echo ""
        echo "⚠️  Kayıt ekledikten sonra uygulamayı yeniden başlatın!"
        ;;

    *)
        echo "Bilinmeyen komut: $1"
        echo "Yardım için: ./scripts/add_record.sh help"
        ;;
esac
