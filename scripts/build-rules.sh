#!/usr/bin/env bash
# Membangun bagian turunan dari tabel "Aturan Inti untuk Agent" di docs/engineering-standard.md (sumber tunggal):
#   - daftar aturan inti di .claude/devcore-rules.md (antara penanda inti:mulai dan inti:selesai)
#   - .claude/devcore-reminder.txt (pengingat per pesan, dibaca hook prompt-rules-reminder.sh)
# Khusus pengembangan devcore (tidak dipasang ke proyek lain); hasilnya yang dipasang.
#
# Pakai:
#   scripts/build-rules.sh            bangun dan tulis
#   scripts/build-rules.sh --check    gagal (exit 1) bila hasil di berkas basi
#   scripts/build-rules.sh [--check] <root>
set -u
mode=build; root=""
for a in "$@"; do
  case "$a" in
    --check) mode=check ;;
    -h|--help) sed -n '2,/^set -u/p' "$0" | sed -e '$d' -e 's/^# \{0,1\}//'; exit 0 ;;
    *) root=$a ;;
  esac
done
root=${root:-$(cd "$(dirname "$0")/.." && pwd -P)}
command -v python3 >/dev/null 2>&1 || { echo "GALAT: python3 diperlukan" >&2; exit 2; }

exec python3 -I - "$mode" "$root" <<'PY'
import os
import re
import sys

mode, root = sys.argv[1], sys.argv[2]
std_path = os.path.join(root, 'docs', 'engineering-standard.md')
rules_path = os.path.join(root, '.claude', 'devcore-rules.md')
rem_path = os.path.join(root, '.claude', 'devcore-reminder.txt')
START, END = '<!-- inti:mulai -->', '<!-- inti:selesai -->'


def die(msg):
    print('GALAT: ' + msg, file=sys.stderr)
    sys.exit(2)


for p in (std_path, rules_path):
    if not os.path.isfile(p):
        die('berkas tidak ada: ' + p)
std = open(std_path, encoding='utf-8').read()
block = re.search(re.escape(START) + r'\n(.*?)\n' + re.escape(END), std, re.S)
if not block:
    die('penanda inti:mulai / inti:selesai tidak ditemukan di standar')

rows = []
for line in block.group(1).split('\n'):
    line = line.strip()
    if not line.startswith('|'):
        continue
    cells = [c.strip() for c in line.strip('|').split('|')]
    if cells[0] == 'ID' or set(cells[0]) <= set('-: '):
        continue
    if len(cells) != 6:
        die('baris tabel harus 6 kolom (ID, Judul, Ringkasan, Kritis, Salah, Benar): ' + line[:70])
    rows.append(cells)
if not rows:
    die('tabel aturan inti kosong')

defined = set(re.findall(r'^- `([A-Z]{2,3}-\d{2})`', std, re.M))
for rid, judul, ring, krit, salah, benar in rows:
    for one in [x.strip() for x in rid.split(',')]:
        if one not in defined:
            die('ID %s pada tabel tidak terdefinisi sebagai aturan di standar' % one)
    if krit not in ('ya', 'tidak'):
        die('kolom Kritis harus "ya" atau "tidak" (%s)' % rid)
    if krit == 'ya' and not (salah and benar):
        die('aturan kritis %s wajib punya contoh Salah dan Benar' % rid)
    if not (judul and ring):
        die('judul dan ringkasan wajib diisi (%s)' % rid)

core = ['## Aturan inti (tidak boleh dilanggar)']
for i, (rid, judul, ring, krit, salah, benar) in enumerate(rows, 1):
    ids = ', '.join(x.strip() for x in rid.split(','))
    core.append('%d. **%s.** %s (%s)' % (i, judul, ring, ids))
    if krit == 'ya':
        core.append('   - Salah: ' + salah)
        core.append('   - Benar: ' + benar)
core_text = '\n'.join(core)

rem = ['[Pengingat aturan proyek — .claude/devcore-rules.md; dibangun dari docs/engineering-standard.md]']
for rid, judul, ring, krit, salah, benar in rows:
    if krit == 'ya':
        rem.append('- %s (%s).' % (judul, ', '.join(x.strip() for x in rid.split(','))))
rem.append('- Skill wajib: write-brief (sebelum kode), change-function (ubah fungsi/kontrak), verify-done (sebelum bilang selesai), check-security (auth/input/secret).')
rem.append('- Jika dikoreksi karena melanggar aturan: perbaiki, lalu usulkan penegakan mesin (hook/izin/tes), bukan sekadar minta maaf.')
rem_text = '\n'.join(rem) + '\n'

rules = open(rules_path, encoding='utf-8').read()
rb = re.search(re.escape(START) + r'\n(.*?)\n' + re.escape(END), rules, re.S)
if not rb:
    die('penanda inti:mulai / inti:selesai tidak ditemukan di .claude/devcore-rules.md')
new_rules = rules[:rb.start(1)] + core_text + rules[rb.end(1):]
old_rem = open(rem_path, encoding='utf-8').read() if os.path.isfile(rem_path) else None

if mode == 'check':
    stale = []
    if new_rules != rules:
        stale.append('.claude/devcore-rules.md')
    if old_rem != rem_text:
        stale.append('.claude/devcore-reminder.txt')
    if stale:
        print('BASI: %s tidak sesuai tabel "Aturan Inti untuk Agent" di standar; jalankan scripts/build-rules.sh' % ', '.join(stale))
        sys.exit(1)
    print('Aturan inti: OK (%d aturan, %d kritis)' % (len(rows), sum(1 for r in rows if r[3] == 'ya')))
    sys.exit(0)

open(rules_path, 'w', encoding='utf-8').write(new_rules)
open(rem_path, 'w', encoding='utf-8').write(rem_text)
print('Dibangun: %d aturan inti (%d kritis) -> .claude/devcore-rules.md dan .claude/devcore-reminder.txt' % (len(rows), sum(1 for r in rows if r[3] == 'ya')))
PY
