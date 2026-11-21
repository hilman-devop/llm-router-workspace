# LLM Router Workspace

![Windows Batch](https://img.shields.io/badge/Windows_Batch-2f81f7?style=flat) ![PowerShell](https://img.shields.io/badge/PowerShell-2f81f7?style=flat) ![Node.js](https://img.shields.io/badge/Node.js-2f81f7?style=flat) ![SQLite](https://img.shields.io/badge/SQLite-2f81f7?style=flat) ![LLM](https://img.shields.io/badge/LLM-2f81f7?style=flat)

> Tooling Windows untuk mengurangi konflik ketika beberapa layanan router LLM dijalankan bersamaan.

## Tentang proyek

Tooling Windows untuk mengurangi konflik ketika beberapa layanan router LLM dijalankan bersamaan. Dokumentasi ini dibuat sebagai panduan singkat untuk memahami ruang lingkup proyek, menjalankannya secara lokal, dan membaca batasan penggunaannya.

## Fitur utama

- Menjalankan router secara paralel
- Isolasi profile, cookie, dan database
- Launcher CMD, Batch, dan PowerShell
- Catatan troubleshooting arsitektur proxy lokal

## Teknologi

- Windows Batch
- PowerShell
- Node.js
- SQLite
- LLM

## Menjalankan secara lokal

Prasyarat dan konfigurasi dapat berbeda menurut sistem operasi. Contoh langkah utama:

```bash
Jalankan `start-omniroute.bat` atau `start-omniroute.ps1` di Windows.
```

## Struktur dan pengembangan

Mulai dari entry point dan folder konfigurasi proyek. Pisahkan credential lokal dari source code, tambahkan test untuk perubahan penting, dan gunakan environment variable untuk konfigurasi deployment.

## Keamanan

- Jangan commit API key, password, token, session ID, atau data pribadi.
- Gunakan file environment lokal dan contoh konfigurasi tanpa nilai rahasia.
- Uji perubahan pada environment development sebelum deployment.

## Status

Proyek ini merupakan bagian dari portofolio **Hilman Arifin Ilham** dan dapat dikembangkan sesuai kebutuhan penggunaan.

> **Catatan:** Endpoint dan API key dibaca dari environment/config lokal. Jangan memasukkan key aktif ke file yang di-commit.

## Lisensi

Belum ada lisensi open-source yang dinyatakan di repository ini. Hubungi pemilik repository sebelum menggunakan ulang atau mendistribusikan kode.

---

Dibuat oleh [Hilman Arifin Ilham](https://github.com/hilman-devop).
