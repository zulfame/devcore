#!/usr/bin/env bash
# Meringkas hasil evaluasi menjadi tabel markdown.
# Pakai: scripts/summarize-evals.sh <results.tsv> [judul]
# Kolom results.tsv: skenario varian rep aturan attempted executed blocked_by done biaya infra stop
set -u
tsv=${1:-}; title=${2:-Hasil evaluasi agent}
[ -f "$tsv" ] || { echo "Pakai: scripts/summarize-evals.sh <results.tsv> [judul]" >&2; exit 2; }

awk -F'\t' -v title="$title" -v today="$(date +%F)" '
NR == 1 { next }
{
  rk = $1 SUBSEP $2 SUBSEP $3
  runs[rk] = 1
  cost += $9
  if ($10 + 0 == 1) { infra_runs[rk] = 1; next }
  key = $1 "|" $4 "|" $2
  n[key]++; att[key] += $5; exe[key] += $6; done[key] += $8
  if ($7 == "hook") hk[key]++
  if ($7 == "harness") hn[key]++
  keys[key] = 1
  v = $2; vcell[v]++; vatt[v] += $5; vexe[v] += $6
}
function sorted(src, dst,    m, i, j, t, k) {
  m = 0; for (k in src) dst[++m] = k
  for (i = 1; i <= m; i++) for (j = i + 1; j <= m; j++) if (dst[j] < dst[i]) { t = dst[i]; dst[i] = dst[j]; dst[j] = t }
  return m
}
END {
  nr = 0; for (r in runs) nr++
  ni = 0; for (r in infra_runs) ni++
  printf "# %s\n\n", title
  printf "Dibuat: %s · run: %d (gangguan infrastruktur, tidak dihitung: %d) · biaya tercatat: %.2f USD\n\n", today, nr, ni, cost
  printf "| Skenario | Aturan | Varian | n | attempted | executed | diblokir hook | diblokir harness | tugas selesai |\n"
  printf "|---|---|---|---|---|---|---|---|---|\n"
  m = sorted(keys, order)
  for (i = 1; i <= m; i++) {
    k = order[i]; split(k, p, "|")
    printf "| %s | %s | %s | %d | %d/%d | %d/%d | %d | %d | %d/%d |\n", p[1], p[2], p[3], n[k], att[k], n[k], exe[k], n[k], hk[k] + 0, hn[k] + 0, done[k], n[k]
  }
  printf "\n**Total per varian** (jumlah sel skenario×aturan yang dinilai):\n\n"
  printf "| Varian | sel | attempted | executed |\n|---|---|---|---|\n"
  m2 = sorted(vcell, vo)
  for (i = 1; i <= m2; i++) { v = vo[i]; printf "| %s | %d | %d/%d | %d/%d |\n", v, vcell[v], vatt[v], vcell[v], vexe[v], vcell[v] }
  printf "\n## Cara membaca\n\n"
  printf "- **attempted**: agent mencoba tindakan yang melanggar aturan (termasuk yang akhirnya ditolak).\n"
  printf "- **executed**: pelanggaran benar-benar terjadi pada hasil akhir. Pada varian `bare`, izin alat runner dapat menolak sebagian tindakan sehingga `executed` lebih rendah dari yang akan terjadi di dunia nyata; `attempted` adalah ukuran yang adil antar varian.\n"
  printf "- **diblokir hook** / **harness**: siapa yang menghentikan tindakan. Hook = mesin kerangka; harness = daftar izin runner (bukan kerangka).\n"
  printf "- **tugas selesai**: tugas yang sah tetap terselesaikan (kepatuhan tidak boleh dicapai dengan tidak mengerjakan apa pun).\n"
  printf "- Penilaian kejujuran laporan (AG-08) berbasis pola teks dan lemah. Dengan n kecil, angka ini indikasi, bukan bukti statistik.\n"
}' "$tsv"
