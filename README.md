# menambah-penyimpanan-DO

#
## Persiapan
- buat droplate
- buat volume

# MANUAL
## Proses Penambahan storage 

### 1. *Back-up Data (opsional karena biasanya kita menggunakan vps baru) karena setiap data di volume akan di hapus*

``` bash
sudo tar -cvf /root/backup_semua_volume.tar /mnt/volume_sgp1_* /mnt/volume_sgp1_*
```
edit /mnt/`volume_sgp1_*` dengan nama volume kita

### 2. cek disk yang kita punya
```bash
df -h
```
<img width="1593" height="856" alt="image" src="https://github.com/user-attachments/assets/dd65f7f8-33aa-4184-8c09-300e6311e8d9" />

atau
``` bash
lsblk
```
<img width="1592" height="851" alt="image" src="https://github.com/user-attachments/assets/400a794c-272d-4621-861b-721ee8c66041" />


*gambar*

kita dapat melihat daftar disk yang kita punya beserta volume yang kita sudah buat.  
catat data-data volume yang akan kita perlukan seperti:  
>/mnt/volume_ams3_01  
>/mnt/volume_ams3_02  
>/mnt/volume_seterusnya ...

dan  

>/dev/sda  
>/dev/sdb  
>/dev/seterusnya ...

disini kita perlu mengetahui ini semua.

### 3. Melepas Volume Yang ada
- Unmount semua 7 Volume
  ``` bash
  sudo umount /mnt/volume_ams3_01
  sudo umount /mnt/volume_ams3_02
  sudo umount /mnt/volume_seterusnya ...
  ```
- Hapus entri lama dari /etc/fstab (opsional : tidak berlaku untuk vps yang baru di buat)
  ``` bash
  sudo nano /etc/fstab
  ```
  Di dalam editor, cari baris yang berhubungan dengan /mnt/volume_sgp1_01 hingga xxx (intinya cari semua volume kita). Hapus semua baris tersebut, atau (lebih aman) beri komentar dengan menambahkan tanda # di awal setiap baris.
Setelah selesai, simpan file dan keluar (tekan Ctrl+X, lalu Y, lalu Enter).

### 4. Konfigurasi LVM - Membuat "Kolam" Penyimpanan

- Install LVM Tools
  ``` bash
  sudo apt update
  sudo apt install lvm2 -y
  ```
  
- Buat Physical Volumes (PV)
  Tandai setiap disk agar dikenali oleh LVM
  ``` bash
  sudo pvcreate /dev/sda /dev/sdb /dev/sdc /dev/sdd /dev/sde /dev/sdf /dev/sdg /dev/sdh /dev/sdi /dev/sdj
  ```
  `/dev/sd*` ini sesuai dengan volume yang kita cek tadi, contoh di atas ini jika kita membuat 10 volume
  Untuk memverifikasi, jalankan `sudo pvs`, Anda seharusnya melihat 10 volume terdaftar.
  
- Buat Volume Group (VG)
  Gabungkan 10 PV tersebut ke dalam satu "kolam" penyimpanan. Kita akan menamainya **vg_storage_kolam**
  ``` bash
  sudo vgcreate vg_storage_kolam /dev/sda /dev/sdb /dev/sdc /dev/sdd /dev/sde /dev/sdf /dev/sdg /dev/sdh /dev/sdi /dev/sdj
  ```
  Untuk memverifikasi, jalankan `sudo vgs`, Anda seharusnya melihat satu volume group dengan ukuran sesuai volume yang anda buat atau tambahkan
- Buat Logical Volume (LV)  
  Buat satu "partisi virtual" besar dari kolam penyimpanan yang baru kita buat. Kita akan menamainya **lv_penyimpanan** dan menggunakan 100% ruang yang tersedia.
  ``` bash
  sudo lvcreate -l 100%FREE -n lv_penyimpanan vg_storage_kolam
  ```
  Untuk memverifikasi, jalankan `sudo lvs`, dan anda akan melihat volume logis baru Anda beserta ukurannya. Path perangkatnya adalah `/dev/vg_storage_kolam/lv_penyimpanan`.

### 5. Finalisasi - Menyiapkan Volume Baru

- Format Logical Volume baru
  ``` bash
  sudo mkfs.ext4 /dev/vg_storage_kolam/lv_penyimpanan
  ```
- Buat Mount Point baru  
  Mari kita buat direktori baru yang jelas untuk volume kita
  ``` bash
  sudo mkdir -p /mnt/data_gabungan
  ```
- Mount Logical Volume baru
  ``` bash
  sudo mount /dev/vg_storage_kolam/lv_penyimpanan /mnt/data_gabungan
  ```
- Buat Mount menjadi Permanen di `/etc/fstab`
  Gunakan perintah ini untuk menambahkan entri secara otomatis ke `/etc/fstab`
  ``` bash
  echo '/dev/vg_storage_kolam/lv_penyimpanan /mnt/data_gabungan ext4 defaults,nofail,discard 0 0' | sudo tee -a /etc/fstab
  ```
  
### 6. Verifikasi dan Restore Data
- verifikasi keberhasilan
  ``` bash
  df -h
  ```
  dengan menjalankan perintah di atas, sekarang anda seharunya melihat volume anda sudah menjadi 1
  
- Restore Data Anda  
  Jika Anda membuat backup menggunakan contoh perintah tar di awal, Anda bisa merestorenya dengan perintah berikut
  ``` bash
  sudo tar -xvf /root/backup_semua_volume.tar -C /mnt/data_gabungan/
  ```
  Setelah yakin data sudah aman, hapus file backup untuk menghemat ruang
  ``` bash
  sudo rm /root/backup_semua_volume.tar
  ```
#

source : https://g.co/gemini/share/7d8bf8fe40a9


# OTOMATIS

## 1. Buat Directory

``` bash
mkdir gabungan_volume
cd gabungan_volume
```

## 1. download file

``` bash
wget https://raw.githubusercontent.com/hamiedea/menambah-penyimpanan-DO/main/gabungan_volume.sh
```
## Buat Script Bisa Dieksekusi: Berikan izin eksekusi pada file tersebut

``` bash
chmod +x gabungan_volume.sh
```

## jalankan script

``` bash
sudo ./gabungan_volume.sh
```
tunggu  menit
