# Peta Penegakan Aturan

Menjawab: *aturan ini dijaga oleh apa?* Aturan di markdown hanya **saran** bagi model; yang benar-benar menjamin adalah mekanisme yang dijalankan sistem, bukan ingatan model. Lihat [ADR-0001](adr/0001-layered-enforcement.md).

## Tingkat penegakan
| Tingkat | Arti | Mekanisme |
|---|---|---|
| **Keras** | Mesin menolak/menahan tindakan, apa pun yang "diingat" model | Hook `PreToolUse`, `permissions.deny/ask` |
| **Terverifikasi** | Pelanggaran terdeteksi otomatis setelah ditulis | Lint, type check, test, CI, scan (butuh tooling proyek) |
| **Terpandu** | Prosedur dan pengingat memengaruhi perilaku, tidak menjamin | `CLAUDE.md`, skill, hook `UserPromptSubmit` |
| **Review manusia** | Hanya manusia yang bisa menilai | Code review, pengguna |

## Status per aturan
| Aturan | Tingkat | Mekanisme | Catatan |
|---|---|---|---|
| AG-06 tindakan destruktif | Keras | `pretool-bash-guard.sh`, `permissions.deny` | Mencakup rm -r, reset --hard, force push, clean -f, branch -D, drop/truncate. Pola teks: bisa dikelabui varian perintah |
| AG-07 / SC-07 secret | Keras | `pretool-write-guard.sh`, `pretool-bash-guard.sh`, `deny Read` | Pola kredensial umum + penugasan literal. Tidak menangkap semua format secret |
| AG-09 melemahkan pemeriksaan | Keras sebagian | `pretool-write-guard.sh` (tamper `.claude/`) | Skip test / matikan lint di kode **belum** terdeteksi mesin → perlu CI (lihat di bawah) |
| AG-12 dependency baru | Keras | `permissions.ask` (npm/yarn/pnpm/pip/composer) | Hanya package manager yang terdaftar |
| AG-13 commit/push | Terpandu + prompt izin | Bawaan: hanya atas permintaan; izin berkelanjutan hanya di `CLAUDE.local.md` (gitignored, tidak disalin) | Force push/reset tetap Keras (diblokir hook) |
| DP-01 lockfile manual | Keras | `pretool-write-guard.sh` | |
| DP-06 curl \| sh | Keras | `pretool-bash-guard.sh` | |
| AG-01..05, AG-08, AG-10, AG-11, AG-14 | Terpandu | `CLAUDE.md`, `prompt-rules-reminder.sh`, skill `change-function`, `verify-done` | Tidak bisa diotomatisasi sepenuhnya: perilaku dan penilaian |
| VL-*, SC-01..04, API-*, DB-* | Terpandu → Terverifikasi | Skill `check-security`; test kontrak **saat kode ada** | Menjadi Terverifikasi setelah proyek punya tes |
| CD-01, CD-03, TS-*, SC-14, DP-03 | **Belum aktif** | Perlu lint/test/CI/scan | Proyek ini belum punya kode. Aktifkan saat proyek nyata dibuat (lihat daftar tugas) |
| AR-03 (hindari overengineering), CD-09 | Review manusia | — | Subjektif, tidak bisa diblokir mesin |
| Bagian 18 (OS/server) | Di luar cakupan | — | Dicatat sebagai prasyarat lingkungan |

## Batas yang jujur
- Hook adalah **pagar pengaman, bukan sandbox**. Agent yang gigih bisa menemukan varian perintah yang lolos; karena itu aturan tetap ditulis, dan perubahan pada hook butuh persetujuan.
- Aturan yang bersifat penilaian (ruang lingkup, kejujuran laporan, kesederhanaan) **tidak bisa** dipaksa mesin. Pengamannya: skill, laporan format tetap, dan review pengguna.
- Hook yang gagal tidak melindungi apa pun. Tes ada di `.claude/hooks/test-hooks.sh`; jalankan setelah mengubah hook.

## Tugas penegakan yang belum dikerjakan
Dikerjakan saat proyek nyata (dengan kode) dibuat dari standar ini:
- [ ] Pre-commit / CI: formatter, linter, type check, test, secret scan, dependency scan.
- [ ] Hook `PostToolUse`: jalankan formatter/lint pada file yang baru diubah.
- [ ] Hook `Stop`: tolak "selesai" bila test terakhir gagal.
- [ ] Contract test validasi UI–backend (VL-09).
- [ ] Deteksi `skip`/`ignore`/`any` baru di diff (AG-09, CD-03).
