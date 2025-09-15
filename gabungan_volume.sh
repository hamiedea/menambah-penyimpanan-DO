#!/bin/bash

# ==============================================================================
# Script untuk Mengotomatisasi Penggabungan Volume DigitalOcean menggunakan LVM
# ==============================================================================

# --- Konfigurasi (Bisa diubah sesuai kebutuhan) ---
VG_NAME="vg_storage_kolam"
LV_NAME="lv_penyimpanan"
MOUNT_POINT="/mnt/data_gabungan"
FILE_SYSTEM="ext4"
# --------------------------------------------------


# --- Warna untuk output ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color
# --------------------------

# Fungsi untuk menampilkan pesan error dan keluar
function error_exit {
    echo -e "${RED}ERROR: $1${NC}" >&2
    exit 1
}

# 1. Peringatan Keras dan Konfirmasi
echo -e "${RED}==================================== PERINGATAN ====================================${NC}"
echo -e "${RED}Script ini akan MENGHAPUS SEMUA DATA pada volume DigitalOcean yang belum diformat.${NC}"
echo -e "Volume yang terdeteksi akan digabungkan menjadi satu penyimpanan LVM besar."
echo -e "Pastikan Anda sudah melakukan backup jika ada data penting."
echo -e "${RED}Script ini TIDAK akan menyentuh disk OS atau volume yang sudah menjadi bagian dari LVM lain.${NC}"
echo -e "${YELLOW}Ketik 'YES' untuk melanjutkan, atau ketik apapun untuk membatalkan.${NC}"
read -p "Apakah Anda yakin ingin melanjutkan? " CONFIRMATION
if [ "$CONFIRMATION" != "YES" ]; then
    echo "Operasi dibatalkan oleh pengguna."
    exit 0
fi

# 2. Periksa apakah script dijalankan sebagai root
if [ "$(id -u)" -ne 0 ]; then
    error_exit "Script ini harus dijalankan sebagai root atau dengan sudo."
fi

# 3. Periksa apakah lvm2 sudah terinstall
if ! command -v pvcreate &> /dev/null; then
    echo "Perintah LVM (lvm2) tidak ditemukan. Menginstall..."
    apt update && apt install -y lvm2 || error_exit "Gagal menginstall lvm2."
fi

# 4. Deteksi volume DigitalOcean yang baru (belum menjadi bagian dari PV)
echo -e "\n${GREEN}Mencari volume DigitalOcean yang baru...${NC}"
TARGET_DISKS=()
for disk in /dev/disk/by-id/scsi-0DO_Volume_*; do
    # Memastikan file disk benar-benar ada
    if [ -e "$disk" ]; then
        # Cek apakah disk ini sudah menjadi Physical Volume (PV)
        if ! pvs "$disk" &>/dev/null; then
            echo "   -> Ditemukan volume baru: $disk"
            TARGET_DISKS+=("$disk")
        else
            echo "   -> Melewati volume yang sudah ada di LVM: $disk"
        fi
    fi
done

if [ ${#TARGET_DISKS[@]} -eq 0 ]; then
    echo -e "\n${YELLOW}Tidak ada volume DigitalOcean baru yang ditemukan untuk diproses.${NC}"
    exit 0
fi

echo -e "\n${GREEN}Volume berikut akan digabungkan:${NC}"
for disk in "${TARGET_DISKS[@]}"; do
    echo " - $disk"
done
echo ""

# 5. Eksekusi Perintah LVM
echo "Membuat Physical Volumes (PV)..."
pvcreate "${TARGET_DISKS[@]}" || error_exit "Gagal membuat Physical Volumes."

echo "Membuat Volume Group (VG) dengan nama '$VG_NAME'..."
vgcreate "$VG_NAME" "${TARGET_DISKS[@]}" || error_exit "Gagal membuat Volume Group."

echo "Membuat Logical Volume (LV) dengan nama '$LV_NAME' menggunakan 100% ruang..."
lvcreate -l 100%FREE -n "$LV_NAME" "$VG_NAME" || error_exit "Gagal membuat Logical Volume."

# 6. Finalisasi: Format, Mount, dan Update /etc/fstab
LV_PATH="/dev/$VG_NAME/$LV_NAME"
echo "Memformat LV '$LV_PATH' dengan sistem file $FILE_SYSTEM..."
mkfs.$FILE_SYSTEM "$LV_PATH" || error_exit "Gagal memformat Logical Volume."

echo "Membuat mount point '$MOUNT_POINT'..."
mkdir -p "$MOUNT_POINT"

echo "Mounting LV ke '$MOUNT_POINT'..."
mount "$LV_PATH" "$MOUNT_POINT" || error_exit "Gagal me-mount Logical Volume."

echo "Menambahkan entri ke /etc/fstab agar mount permanen..."
FSTAB_ENTRY="$LV_PATH $MOUNT_POINT $FILE_SYSTEM defaults,nofail,discard 0 0"
# Cek agar tidak ada duplikat entri
if ! grep -qF "$FSTAB_ENTRY" /etc/fstab; then
    echo "$FSTAB_ENTRY" >> /etc/fstab
else
    echo "Entri sudah ada di /etc/fstab."
fi

# 7. Verifikasi dan Selesai
echo -e "\n${GREEN}================================= PROSES SELESAI =================================${NC}"
echo -e "Volume telah berhasil digabungkan dan di-mount."
echo -e "\n${YELLOW}Hasil Verifikasi:${NC}"
echo "--- Output 'lvs' ---"
lvs
echo ""
echo "--- Output 'df -h' ---"
df -h "$MOUNT_POINT"
echo -e "\n${GREEN}Penyimpanan gabungan Anda sekarang siap digunakan di: $MOUNT_POINT ${NC}"
