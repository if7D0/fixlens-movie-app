# FixLens — Store Listing Draft (v1.0.0)

> Status: DIARSIPKAN. Distribusi GitHub-only (keputusan owner):
> tanpa Play publish, tanpa screenshot, tanpa iOS.
> Dokumen ini disimpan sebagai referensi teks (judul + deskripsi) bila
> suatu hari berubah pikiran.

## Title (≤30 char)

FixLens — Mood Movie Picks

## Short description (≤80 char)

ID: Rekomendasi film sesuai mood. 3 pertanyaan, 3 pilihan, <1 menit.
EN: Mood-based movie picks. 3 questions, 3 films, under a minute.

## Full description (ID)

Bosan scroll 30 menit lalu tidak jadi nonton? FixLens merekomendasikan film
berdasarkan mood-mu — bukan sekadar trending yang sama di semua platform.

- Find by Mood: jawab 3 pertanyaan singkat, dapat 3 rekomendasi + alasan
- Cari film dengan filter multi-genre dan rating minimum
- Detail lengkap: cast, trailer, film terkait
- Watchlist tersimpan di HP (sinkron ke akun bila login)
- Rating + ulasan publik per film

Data film oleh TMDB. Gratis, tanpa iklan.

## Full description (EN)

Endless scrolling with nothing to watch? FixLens recommends movies by your
mood — not the same trending list everywhere.

- Find by Mood: 3 quick questions, 3 picks with reasons, under a minute
- Search with multi-genre and minimum-rating filters
- Full details: cast, trailers, similar titles
- On-device watchlist (cloud sync when signed in)
- Public ratings and reviews per movie

Movie data by TMDB. Free, no ads.

## Assets needed — DITIADAKAN (GitHub-only, keputusan owner)

Sengaja tidak dibuat: screenshot device, feature graphic.

## Data safety (arsip bila suatu hari publish)

## Data safety (panduan isi form Play)

- Lokasi: tidak dikumpulkan
- Info pribadi: nama/email/foto profil Google (login opsional, untuk ulasan)
- Konten pengguna: ulasan + watchlist (tersimpan di Firebase project owner)
- ID perangkat: tidak dikumpulkan manual (Firebase SDK standar)
- Enkripsi transit: ya (HTTPS); penghapusan akun: hapus via tab Profil
  (logout) + minta hapus data via email owner (cantumkan email di listing)

## Attribution (wajib tampil)

- "This product uses the TMDB API but is not endorsed or certified by TMDB."
  (sudah di README; tempel juga di deskripsi store bila ada kolom khusus)

## iOS — DIBATALKAN (owner: tidak ada Mac)

Folder `ios/` tetap ada agar struktur Flutter utuh, tapi tidak ada rencana
build/uji/rilis iOS. Abaikan bagian ini kecuali keputusan berubah.
