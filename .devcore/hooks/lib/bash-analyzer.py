#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Penganalisis perintah shell untuk pretool-bash-guard.sh (AG-06, AG-07, DP-06, OS-01, AG-15).

Membaca JSON hook PreToolUse dari stdin, menokenisasi perintah shell (kutip, escape, operator,
substitusi, heredoc), lalu memutuskan dari ARGV per perintah sederhana, bukan dari teks mentah:
  {"decision": "allow"}
  {"decision": "ask",   "rule": "...", "reason": "..."}
  {"decision": "block", "rule": "...", "reason": "..."}
  {"decision": "fallback", "reason": "..."}   (tidak dapat diparse; pemanggil memakai penjaga regex lama)

Ini pagar pengaman, BUKAN sandbox. Yang tidak dapat dinilai: isi skrip yang dijalankan dari berkas,
variabel yang tidak terselesaikan, fungsi/alias shell, dan obfuscation lain.
Hanya stdlib; sintaks kompatibel Python 3.6+.
"""
import json
import os
import re
import subprocess
import sys

MAX_DEPTH = 6
HOOKS_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))


class ParseError(Exception):
    pass


# ----------------------------------------------------------------------------
# Tokenizer
# ----------------------------------------------------------------------------
OPERATORS = ['<<<', '<<-', '<<', '&>>', '&>', '>>', '>&', '>|', '<&', '<>', '&&', '||', '|&', ';;',
             ';', '|', '&', '(', ')', '<', '>']
REDIR_OPS = ('<<<', '&>>', '&>', '>>', '>&', '>|', '<&', '<>', '<', '>')
WRITE_REDIR_OPS = ('>', '>>', '>|', '&>', '&>>', '<>')


def scan_balanced(s, i, open_c, close_c):
    """s[i] adalah karakter setelah pembuka. Kembalikan (isi, indeks setelah penutup)."""
    depth = 1
    j = i
    n = len(s)
    while j < n:
        c = s[j]
        if c == '\\':
            j += 2
            continue
        if c == "'":
            k = s.find("'", j + 1)
            j = (k + 1) if k != -1 else n
            continue
        if c == '"':
            j += 1
            while j < n and s[j] != '"':
                if s[j] == '\\':
                    j += 1
                j += 1
            j += 1
            continue
        if c == open_c:
            depth += 1
        elif c == close_c:
            depth -= 1
            if depth == 0:
                return s[i:j], j + 1
        j += 1
    raise ParseError('tanda kurung tidak seimbang')


def find_backtick(s, i):
    j = i
    n = len(s)
    while j < n:
        if s[j] == '\\':
            j += 2
            continue
        if s[j] == '`':
            return s[i:j], j + 1
        j += 1
    raise ParseError('backtick tidak ditutup')


def extract_subs(text):
    """Substitusi perintah ($(...) dan `...`) di dalam teks (mis. isi heredoc tanpa kutip)."""
    subs = []
    i = 0
    n = len(text)
    while i < n:
        if text.startswith('$(', i) and not text.startswith('$((', i):
            try:
                inner, j = scan_balanced(text, i + 2, '(', ')')
            except ParseError:
                break
            subs.append(inner)
            i = j
            continue
        if text[i] == '`':
            try:
                inner, j = find_backtick(text, i + 1)
            except ParseError:
                break
            subs.append(inner)
            i = j
            continue
        i += 1
    return subs


def tokenize(s):
    """Kembalikan (tokens, subs). Token: ('w', teks) | ('o', operator) | ('h', badan, dikutip)."""
    tokens = []
    subs = []
    pending = []          # heredoc yang menunggu badan: (delim, strip_tab, quoted, indeks_token)
    buf = []
    inword = False
    i = 0
    n = len(s)

    def flush():
        nonlocal buf, inword
        if inword:
            tokens.append(('w', ''.join(buf)))
        buf = []
        inword = False

    while i < n:
        c = s[i]
        if c in ' \t\r':
            flush()
            i += 1
            continue
        if c == '#' and not inword:
            while i < n and s[i] != '\n':      # komentar shell hingga akhir baris
                i += 1
            continue
        if c == '\n':
            flush()
            tokens.append(('o', ';'))
            i += 1
            while pending:
                delim, strip, quoted, idx = pending.pop(0)
                lines = []
                while i < n:
                    j = s.find('\n', i)
                    line = s[i:j] if j != -1 else s[i:]
                    i = (j + 1) if j != -1 else n
                    cmp_line = line.lstrip('\t') if strip else line
                    if cmp_line == delim:
                        break
                    lines.append(line)
                tokens[idx] = ('h', '\n'.join(lines), quoted)
            continue
        if c == '\\':
            if i + 1 < n and s[i + 1] == '\n':
                i += 2
                continue
            inword = True
            if i + 1 < n:
                buf.append(s[i + 1])
            i += 2
            continue
        if c == "'":
            k = s.find("'", i + 1)
            if k == -1:
                raise ParseError('kutip tunggal tidak ditutup')
            inword = True
            buf.append(s[i + 1:k])
            i = k + 1
            continue
        if c == '"':
            j = i + 1
            piece = []
            while j < n and s[j] != '"':
                ch = s[j]
                if ch == '\\' and j + 1 < n and s[j + 1] in '"\\$`\n':
                    if s[j + 1] != '\n':
                        piece.append(s[j + 1])
                    j += 2
                    continue
                if ch == '$' and s.startswith('$(', j) and not s.startswith('$((', j):
                    inner, j2 = scan_balanced(s, j + 2, '(', ')')
                    subs.append(inner)
                    piece.append(s[j:j2])
                    j = j2
                    continue
                if ch == '`':
                    inner, j2 = find_backtick(s, j + 1)
                    subs.append(inner)
                    piece.append(s[j:j2])
                    j = j2
                    continue
                piece.append(ch)
                j += 1
            if j >= n:
                raise ParseError('kutip ganda tidak ditutup')
            inword = True
            buf.append(''.join(piece))
            i = j + 1
            continue
        if c == '$':
            if s.startswith('$((', i):
                inner, j = scan_balanced(s, i + 2, '(', ')')     # aritmetika: tidak dieksekusi sebagai perintah
                inword = True
                buf.append(s[i:j])
                i = j
                continue
            if s.startswith('$(', i):
                inner, j = scan_balanced(s, i + 2, '(', ')')
                subs.append(inner)
                inword = True
                buf.append(s[i:j])
                i = j
                continue
            if s.startswith('${', i):
                inner, j = scan_balanced(s, i + 2, '{', '}')
                inword = True
                buf.append(s[i:j])
                i = j
                continue
            inword = True
            buf.append('$')
            i += 1
            continue
        if c == '`':
            inner, j = find_backtick(s, i + 1)
            subs.append(inner)
            inword = True
            buf.append(s[i:j])
            i = j
            continue
        if c in '<>' and i + 1 < n and s[i + 1] == '(':
            inner, j = scan_balanced(s, i + 2, '(', ')')
            subs.append(inner)
            inword = True
            buf.append(s[i:j])
            i = j
            continue
        matched = None
        for op in OPERATORS:
            if s.startswith(op, i):
                matched = op
                break
        if matched:
            if matched in ('<<', '<<-'):
                flush()
                j = i + len(matched)
                while j < n and s[j] in ' \t':
                    j += 1
                quoted = False
                if j < n and s[j] in '\'"':
                    q = s[j]
                    k = s.find(q, j + 1)
                    if k == -1:
                        raise ParseError('delimiter heredoc tidak ditutup')
                    delim = s[j + 1:k]
                    quoted = True
                    j = k + 1
                else:
                    k = j
                    while k < n and s[k] not in ' \t\n;|&()<>':
                        k += 1
                    delim = s[j:k]
                    if '\\' in delim:
                        quoted = True
                        delim = delim.replace('\\', '')
                    j = k
                tokens.append(('h', '', quoted))
                pending.append((delim, matched == '<<-', quoted, len(tokens) - 1))
                i = j
                continue
            if matched in REDIR_OPS and inword and ''.join(buf).isdigit():
                buf = []          # awalan fd, mis. 2> atau 2>&1
                inword = False
            else:
                flush()
            tokens.append(('o', matched))
            i += len(matched)
            continue
        inword = True
        buf.append(c)
        i += 1
    flush()
    return tokens, subs


class Seg(object):
    def __init__(self):
        self.words = []
        self.redirs = []       # (op, target)
        self.heredocs = []     # (badan, dikutip)
        self.sep_before = ''
        self.sep_after = ''

    def empty(self):
        return not (self.words or self.redirs or self.heredocs)


def build_segments(tokens):
    segs = []
    cur = Seg()
    i = 0
    n = len(tokens)
    while i < n:
        t = tokens[i]
        if t[0] == 'w':
            cur.words.append(t[1])
            i += 1
            continue
        if t[0] == 'h':
            cur.heredocs.append((t[1], t[2]))
            i += 1
            continue
        op = t[1]
        if op in REDIR_OPS:
            tgt = tokens[i + 1][1] if i + 1 < n and tokens[i + 1][0] == 'w' else ''
            if op in ('>&', '<&') and (tgt.isdigit() or tgt == '-'):
                pass
            else:
                cur.redirs.append((op, tgt))
            i += 2
            continue
        if not cur.empty():
            cur.sep_after = op
            segs.append(cur)
            nxt = Seg()
            nxt.sep_before = op
            cur = nxt
        else:
            if op not in ('(', ')'):
                cur.sep_before = op
        i += 1
    if not cur.empty():
        segs.append(cur)
    return segs


# ----------------------------------------------------------------------------
# Pengetahuan perintah
# ----------------------------------------------------------------------------
ASSIGN_RE = re.compile(r'^[A-Za-z_][A-Za-z0-9_]*=')
KEYWORDS = ('if', 'then', 'else', 'elif', 'fi', 'while', 'until', 'do', 'done', '{', '}', '!')
SKIP_LINES = ('for', 'case', 'select', 'esac', 'in', 'function')
SHELLS = ('sh', 'bash', 'zsh', 'dash', 'ksh', 'ash', 'fish', 'csh', 'tcsh')
INTERP_RE = re.compile(r'^(python[0-9.]*|pypy[0-9.]*|node|nodejs|deno|bun|ruby|perl|php|lua|Rscript|osascript)$')
EXISTENCE_CMDS = ('ls', 'stat', 'test', '[', '[[', 'file', 'realpath', 'dirname', 'basename', 'readlink', 'du', 'find')
TEXT_CMDS = ('echo', 'printf')
PATTERN_CMDS = ('grep', 'egrep', 'fgrep', 'rg', 'ag', 'ack', 'zgrep')

# Kode one-liner/heredoc interpreter: hanya penghapusan berkas dan akses secret (batas sengaja sempit)
INTERP_DESTRUCT_RE = re.compile(
    r'\bshutil\.rmtree\b|\bos\.(remove|unlink|rmdir|removedirs)\b|\.unlink\(|\.rmdir\(|\brmtree\b'
    r'|\bfs\.(rm|rmSync|rmdir|rmdirSync|unlink|unlinkSync)\b|\brimraf\b|\.(rmSync|unlinkSync|rmdirSync)\(|\bFileUtils\.rm|\bFile\.delete\b|\bunlink\s*\(')
INTERP_SECRET_RE = re.compile(
    r'(^|[^A-Za-z0-9_])\.env(\.(?!example|sample|template|dist)[A-Za-z0-9_]+)?(?![A-Za-z0-9_])'
    r'|id_(rsa|dsa|ecdsa|ed25519)(?!\.pub)|\.(pem|key|p12|pfx)\b|\.aws/credentials|\.netrc|\.git-credentials')

SECRET_PATH_RES = [re.compile(p) for p in (
    r'(^|/)\.env$',
    r'(^|/)\.env\.(?!example$|sample$|template$|dist$)[^/]+$',
    r'\.(pem|key|p12|pfx|jks|keystore|ppk|kdbx)$',
    r'(^|/)id_(rsa|dsa|ecdsa|ed25519)$',
    r'(^|/)\.(netrc|pgpass|git-credentials|npmrc|pypirc|dockercfg)$',
    r'(^|/)\.aws/credentials$',
    r'(^|/)\.ssh/[^/]+$',
    r'(^|/)credentials(\.json)?$',
    r'(^|/)secrets?\.(ya?ml|json|toml|env)$',
)]

OS_ADMIN = ('systemctl', 'service', 'launchctl', 'ufw', 'iptables', 'ip6tables', 'nft', 'firewall-cmd', 'pfctl',
            'shutdown', 'reboot', 'halt', 'poweroff', 'fdisk', 'parted', 'diskutil', 'shred', 'mount', 'umount',
            'certbot', 'nginx', 'apachectl', 'httpd', 'crontab', 'useradd', 'userdel', 'usermod', 'passwd', 'chsh',
            'visudo', 'hostnamectl', 'timedatectl', 'sysctl', 'setenforce', 'mkswap', 'swapon', 'swapoff')

# ----------------------------------------------------------------------------
# Bantuan
# ----------------------------------------------------------------------------
class Ctx(object):
    def __init__(self, cwd, root):
        self.cwd = cwd
        self.root = root


def add(out, level, rule, reason):
    out.append((level, rule, reason))


def has_recursive_flag(args):
    for a in args:
        if a == '--recursive':
            return True
        if re.match(r'^-[A-Za-z]*[rR][A-Za-z]*$', a):
            return True
    return False


def has_short_flag(args, ch):
    for a in args:
        if re.match(r'^-[A-Za-z]+$', a) and ch in a[1:]:
            return True
    return False


def path_has_component(p, comp):
    parts = [x for x in re.split(r'[\\/]+', p) if x]
    return comp in parts


def is_unresolved(p):
    return ('$' in p) or ('`' in p) or any(ch in p for ch in '*?[')


def resolve(p, ctx):
    if not p or is_unresolved(p):
        return None
    p = os.path.expanduser(p)
    if not os.path.isabs(p):
        p = os.path.join(ctx.cwd, p)
    return os.path.normpath(p)


def secret_candidates(a):
    cands = [a]
    if '=' in a:
        cands.append(a.split('=', 1)[1])
    if a.startswith('@'):
        cands.append(a[1:])
    if '=@' in a:
        cands.append(a.split('=@', 1)[1])
    return cands


def is_secret_path(a):
    for cand in secret_candidates(a):
        if not cand or cand.startswith('-'):
            continue
        for rx in SECRET_PATH_RES:
            if rx.search(cand):
                return True
    return False


def positional(args, with_value=()):
    """Argumen non-opsi; opsi dalam with_value menghabiskan argumen berikutnya."""
    res = []
    i = 0
    while i < len(args):
        a = args[i]
        if a == '--':
            res.extend(args[i + 1:])
            break
        if a in with_value:
            i += 2
            continue
        if a.startswith('-') and a != '-':
            i += 1
            continue
        res.append(a)
        i += 1
    return res


# ----------------------------------------------------------------------------
# Pembungkus
# ----------------------------------------------------------------------------
def unwrap(words, out):
    """Buang pembungkus (env, nohup, timeout, ...). Kembalikan (nama, args) atau None."""
    words = list(words)
    while words and ASSIGN_RE.match(words[0]):
        words.pop(0)
    while words:
        while words and words[0] in KEYWORDS:
            words.pop(0)
        if not words:
            return None
        name = os.path.basename(words[0].lstrip('\\'))
        if name in ('sudo', 'doas', 'su', 'pkexec'):
            add(out, 'block', 'OS-01', 'perintah dengan hak istimewa (%s) bukan tugas agent; administrasi host dikelola tim infrastruktur' % name)
            return None
        if name in ('command', 'builtin', 'exec', 'nohup', 'time', 'stdbuf', 'setsid', 'unbuffer', 'caffeinate', 'noglob'):
            words = words[1:]
            while words and words[0].startswith('-'):
                words = words[1:]
            continue
        if name in ('nice', 'ionice'):
            words = words[1:]
            while words and (words[0].startswith('-') or words[0].isdigit()):
                words = words[1:]
            continue
        if name == 'env':
            rest = words[1:]
            while rest:
                if rest[0] in ('-u', '--unset', '-C', '--chdir', '-S'):
                    rest = rest[2:]
                elif rest[0].startswith('-') or ASSIGN_RE.match(rest[0]):
                    rest = rest[1:]
                else:
                    break
            if not rest:
                add(out, 'block', 'AG-07', 'env tanpa perintah mencetak seluruh variabel lingkungan (dapat membocorkan secret)')
                return None
            words = rest
            continue
        if name == 'timeout':
            rest = words[1:]
            while rest and rest[0].startswith('-'):
                rest = rest[2:] if rest[0] in ('-s', '-k', '--signal', '--kill-after') else rest[1:]
            if rest:
                rest = rest[1:]      # durasi
            words = rest
            continue
        return name, words[1:]
    return None


# ----------------------------------------------------------------------------
# Aturan per perintah
# ----------------------------------------------------------------------------
def check_git(args, out, ctx=None):
    i = 0
    n = len(args)
    while i < n:
        a = args[i]
        if a in ('-C', '-c', '--git-dir', '--work-tree', '--namespace', '--exec-path', '--super-prefix', '--config-env'):
            i += 2
            continue
        if a.startswith('-'):
            i += 1
            continue
        break
    if i >= n:
        return
    sub, a = args[i], args[i + 1:]
    if sub == 'reset' and '--hard' in a:
        add(out, 'block', 'AG-06', 'git reset --hard membuang perubahan yang belum di-commit')
    elif sub == 'clean':
        force = has_short_flag(a, 'f') or '--force' in a
        dry = has_short_flag(a, 'n') or '--dry-run' in a
        if force and not dry:
            add(out, 'block', 'AG-06', 'git clean -f menghapus berkas yang tidak terlacak')
    elif sub == 'checkout':
        if '-f' in a or '--force' in a or has_short_flag(a, 'f'):
            add(out, 'block', 'AG-06', 'git checkout -f membuang perubahan lokal')
        elif '--' in a and a.index('--') < len(a) - 1:
            add(out, 'block', 'AG-06', 'git checkout -- <path> menimpa perubahan yang belum di-commit')
        elif '.' in a and not any(x in a for x in ('-b', '-B', '--orphan')):
            add(out, 'block', 'AG-06', 'git checkout . membuang seluruh perubahan lokal')
        elif ctx and not any(x in a for x in ('-b', '-B', '--orphan')) and any(
                resolve(x, ctx) and os.path.exists(resolve(x, ctx)) for x in positional(a)):
            add(out, 'block', 'AG-06', 'git checkout <berkas> menimpa perubahan yang belum di-commit')
    elif sub == 'restore':
        staged_only = ('--staged' in a or '-S' in a) and not ('--worktree' in a or '-W' in a)
        if not staged_only:
            add(out, 'block', 'AG-06', 'git restore menimpa perubahan yang belum di-commit')
    elif sub == 'stash':
        pos = positional(a)
        if pos and pos[0] in ('drop', 'clear'):
            add(out, 'block', 'AG-06', 'git stash %s menghapus pekerjaan yang disimpan' % pos[0])
    elif sub == 'branch':
        if has_short_flag(a, 'D') or (('-d' in a or '--delete' in a or has_short_flag(a, 'd')) and ('-f' in a or '--force' in a)):
            add(out, 'block', 'AG-06', 'git branch -D menghapus branch secara paksa')
    elif sub == 'push':
        force = any(x in ('--force', '--force-with-lease', '--force-if-includes', '--mirror', '--prune') for x in a) \
            or any(x.startswith('--force-with-lease=') for x in a) or has_short_flag(a, 'f')
        if force:
            add(out, 'block', 'AG-06', 'git push dengan force menulis ulang riwayat remote')
        if '--delete' in a or has_short_flag(a, 'd'):
            add(out, 'block', 'AG-06', 'git push --delete menghapus ref di remote')
        for x in positional(a):
            if x.startswith('+'):
                add(out, 'block', 'AG-06', 'refspec dengan awalan + adalah force push (%s)' % x)
            elif x.startswith(':'):
                add(out, 'block', 'AG-06', 'refspec dengan awalan : menghapus ref di remote (%s)' % x)
    elif sub == 'rm':
        if '--cached' not in a and (has_recursive_flag(a) or has_short_flag(a, 'f') or '--force' in a):
            add(out, 'block', 'AG-06', 'git rm -r/-f menghapus berkas dari working tree')
    elif sub in ('filter-branch', 'filter-repo', 'prune'):
        add(out, 'block', 'AG-06', 'git %s menulis ulang atau membuang riwayat' % sub)
    elif sub == 'reflog':
        pos = positional(a)
        if pos and pos[0] in ('expire', 'delete'):
            add(out, 'block', 'AG-06', 'git reflog %s membuang jejak pemulihan' % pos[0])
    elif sub == 'gc':
        if any(x.startswith('--prune') and x != '--prune=never' for x in a):
            add(out, 'block', 'AG-06', 'git gc --prune membuang objek yang tidak terjangkau')
    elif sub == 'update-ref':
        if '-d' in a or '--delete' in a:
            add(out, 'block', 'AG-06', 'git update-ref -d menghapus ref')


def check_rm_like(name, args, out):
    pos = positional(args)
    if name == 'rm' and has_recursive_flag(args):
        add(out, 'block', 'AG-06', 'rm rekursif menghapus direktori beserta isinya')
    if name in ('rm', 'mv', 'cp', 'ln', 'truncate', 'shred', 'unlink', 'rmdir', 'install'):
        for p in pos:
            if path_has_component(p, '.git'):
                add(out, 'block', 'AG-06', '%s pada .git merusak repositori' % name)
                break


def check_find(args, out, ctx, depth, seg_info):
    if '-delete' in args:
        add(out, 'block', 'AG-06', 'find -delete menghapus berkas secara massal')
    i = 0
    while i < len(args):
        if args[i] in ('-exec', '-execdir', '-ok', '-okdir'):
            j = i + 1
            sub = []
            while j < len(args) and args[j] not in (';', '+', '\\;'):
                sub.append(args[j])
                j += 1
            if sub:
                check_effective(sub, out, ctx, depth + 1, seg_info, unknown_args=True)
            i = j
        i += 1


def check_xargs(args, out, ctx, depth, seg_info):
    i = 0
    n = len(args)
    with_val = ('-I', '-n', '-P', '-L', '-s', '-E', '-d', '-a', '-J', '--max-args', '--max-procs', '--delimiter')
    while i < n:
        a = args[i]
        if a in with_val:
            i += 2
            continue
        if a.startswith('-'):
            i += 1
            continue
        break
    sub = args[i:]
    if sub:
        check_effective(sub, out, ctx, depth + 1, seg_info, unknown_args=True)


def scan_code(name, code, out):
    if INTERP_DESTRUCT_RE.search(code):
        add(out, 'block', 'AG-06', 'kode %s menghapus berkas/direktori' % name)
    if INTERP_SECRET_RE.search(code):
        add(out, 'block', 'AG-07', 'kode %s mengakses berkas secret' % name)


def reads_stdin(name, args):
    if name in SHELLS:
        if any(a == '-c' or (re.match(r'^-[A-Za-z]*c$', a)) for a in args):
            return False
        pos = positional(args)
        return (not pos) or pos[0] == '-' or '-s' in args
    if INTERP_RE.match(name):
        if any(a in ('-c', '-e', '-E', '-r', '--eval') or re.match(r'^-[A-Za-z]*[ce]$', a) for a in args):
            return False
        pos = positional(args)
        return (not pos) or pos[0] == '-'
    return False


def shell_command_string(args):
    for i, a in enumerate(args):
        if a == '-c' or re.match(r'^-[A-Za-z]+$', a) and 'c' in a[1:]:
            rest = positional(args[i + 1:])
            return rest[0] if rest else None
    return None


DOWNLOAD_SUBST_RE = re.compile(r'^\s*(\$\(|`|<\()\s*(curl|wget|fetch)\b')
DOWNLOAD_ANY_RE = re.compile(r'(\$\(|`|<\()\s*(curl|wget|fetch)\b')


def check_effective(words, out, ctx, depth, seg_info, unknown_args=False):
    """Periksa satu perintah efektif (setelah pembungkus dibuang)."""
    if depth > MAX_DEPTH:
        add(out, 'ask', 'AG-06', 'perintah bersarang terlalu dalam untuk diperiksa')
        return
    un = unwrap(words, out)
    if un is None:
        return
    name, args = un

    # --- nama perintah dinamis: hook tidak tahu apa yang akan dijalankan ---
    if '$' in name or '`' in name:
        add(out, 'ask', 'AG-06', 'nama perintah dinamis (%s) tidak dapat diperiksa hook' % name)
        return name, args

    # --- administrasi OS ---
    if name in OS_ADMIN or name.startswith('mkfs'):
        add(out, 'block', 'OS-01', '%s adalah administrasi host; dikelola tim infrastruktur, bukan agent' % name)
    if name == 'dd':
        for a in args:
            if a.startswith('of=/dev/'):
                add(out, 'block', 'OS-01', 'dd menulis langsung ke perangkat')

    # --- dump environment ---
    if name == 'printenv' and not positional(args):
        add(out, 'block', 'AG-07', 'printenv mencetak seluruh variabel lingkungan (dapat membocorkan secret)')
    if name == 'export' and '-p' in args:
        add(out, 'block', 'AG-07', 'export -p mencetak seluruh variabel lingkungan')
    if name in ('declare', 'typeset') and '-x' in args and len(positional(args)) == 0:
        add(out, 'block', 'AG-07', '%s -x mencetak variabel yang diekspor' % name)
    if name == 'set' and not args:
        add(out, 'block', 'AG-07', 'set tanpa argumen mencetak seluruh variabel shell')

    # --- shell dan eval ---
    if name in SHELLS:
        s = shell_command_string(args)
        if s is not None:
            if DOWNLOAD_SUBST_RE.search(s):
                add(out, 'block', 'DP-06', 'mengeksekusi hasil unduhan (%s -c "$(curl ...)")' % name)
            analyze_script(s, ctx, depth + 1, out)
        for a in args:
            if DOWNLOAD_ANY_RE.search(a) and a.startswith('<('):
                add(out, 'block', 'DP-06', 'mengeksekusi hasil unduhan lewat process substitution')
        for body, quoted in seg_info.get('heredocs', []):
            if reads_stdin(name, args):
                analyze_script(body, ctx, depth + 1, out)
    elif name == 'eval':
        joined = ' '.join(args)
        if DOWNLOAD_SUBST_RE.search(joined):
            add(out, 'block', 'DP-06', 'eval atas hasil unduhan')
        elif '$' in joined and '$(' not in joined and '`' not in joined:
            add(out, 'ask', 'AG-06', 'eval dengan variabel tidak dapat diperiksa hook')
        analyze_script(joined, ctx, depth + 1, out)
    elif name in ('source', '.'):
        for a in args:
            if is_secret_path(a):
                add(out, 'block', 'AG-07', 'memuat berkas secret (%s)' % a)
            if DOWNLOAD_ANY_RE.search(a):
                add(out, 'block', 'DP-06', 'memuat skrip hasil unduhan')
    elif INTERP_RE.match(name):
        for i, a in enumerate(args):
            if a in ('-c', '-e', '-E', '-r', '-p', '--eval', '--print') or re.match(r'^-[A-Za-z]*[ce]$', a):
                scan_code(name, ' '.join(args[i + 1:]), out)
                break
        if reads_stdin(name, args):
            for body, quoted in seg_info.get('heredocs', []):
                scan_code(name, body, out)
        for a in args:
            if DOWNLOAD_ANY_RE.search(a) and a.startswith('<('):
                add(out, 'block', 'DP-06', 'mengeksekusi hasil unduhan lewat process substitution')

    # --- penghapusan ---
    if name in ('rm', 'mv', 'cp', 'ln', 'truncate', 'shred', 'unlink', 'rmdir', 'install'):
        check_rm_like(name, args, out)
    if name == 'find':
        check_find(args, out, ctx, depth, seg_info)
    if name == 'xargs':
        check_xargs(args, out, ctx, depth, seg_info)
    if name == 'git':
        check_git(args, out, ctx)

    # --- akses berkas secret lewat argumen ---
    if name not in EXISTENCE_CMDS and name not in TEXT_CMDS:
        skip_idx = set()
        if name in PATTERN_CMDS:
            pos_i = [i for i, a in enumerate(args) if not a.startswith('-')]
            if pos_i and not any(x in ('-e', '-f', '--regexp') or x.startswith('--regexp=') for x in args):
                skip_idx.add(pos_i[0])
            for i, a in enumerate(args):
                if a in ('-e', '--regexp') and i + 1 < len(args):
                    skip_idx.add(i + 1)
        elif name in ('sed', 'awk', 'gawk'):
            pos_i = [i for i, a in enumerate(args) if not a.startswith('-')]
            if pos_i and not any(x in ('-e', '-f') for x in args):
                skip_idx.add(pos_i[0])
            for i, a in enumerate(args):
                if a in ('-e',) and i + 1 < len(args):
                    skip_idx.add(i + 1)
        elif name == 'git':
            for i, a in enumerate(args):
                if a in ('-m', '--message', '--grep', '-S', '-G', '--author', '--format', '--pretty') and i + 1 < len(args):
                    skip_idx.add(i + 1)
                if a == 'check-ignore':
                    skip_idx.update(range(len(args)))
        for i, a in enumerate(args):
            if i in skip_idx:
                continue
            if is_secret_path(a):
                add(out, 'block', 'AG-07', 'akses berkas secret (%s); secret tidak boleh dibaca atau dicetak' % a)
                break

    return name, args


# ----------------------------------------------------------------------------
# Penulisan berkas lewat shell -> kebijakan yang sama dengan tool Write/Edit
# ----------------------------------------------------------------------------
def write_targets(name, args):
    """Daftar (jalur, jenis) yang akan ditulis oleh perintah ini."""
    targets = []
    pos = positional(args)
    if name == 'tee':
        targets = [(p, 'write') for p in pos]
    elif name in ('cp', 'mv', 'install', 'ln', 'rsync'):
        tdir = None
        for i, a in enumerate(args):
            if a in ('-t', '--target-directory') and i + 1 < len(args):
                tdir = args[i + 1]
        if tdir:
            targets = [(tdir, 'write')]
        elif len(pos) >= 2:
            targets = [(pos[-1], 'write')]
            if name == 'mv':
                targets += [(p, 'remove') for p in pos[:-1]]
    elif name == 'sed' and any(re.match(r'^-[A-Za-z]*i', a) or a == '--in-place' or a.startswith('--in-place=') for a in args):
        files = pos[1:] if not any(a in ('-e', '-f') for a in args) else pos
        targets = [(p, 'edit') for p in files]
    elif name == 'perl' and any(re.match(r'^-[A-Za-z]*i', a) for a in args):
        eidx = [i for i, a in enumerate(args) if re.match(r'^-[A-Za-z]*e$', a)]
        files = positional(args[eidx[0] + 2:]) if eidx else pos[1:]
        targets = [(p, 'edit') for p in files]
    elif name == 'dd':
        targets = [(a[3:], 'write') for a in args if a.startswith('of=')]
    elif name in ('truncate', 'touch'):
        targets = [(p, 'write') for p in pos[-1:]] if name == 'truncate' else [(p, 'write') for p in pos]
    elif name in ('rm', 'unlink'):
        targets = [(p, 'remove') for p in pos]
    return targets


def delegate(path, content, ctx, out):
    """Teruskan ke penjaga tulis dan gerbang brief dengan JSON sintetis (satu sumber kebijakan)."""
    payload = json.dumps({'tool_name': 'Write', 'cwd': ctx.cwd, 'tool_input': {'file_path': path, 'content': content}})
    for script in ('pretool-brief-gate.sh', 'pretool-write-guard.sh'):
        p = os.path.join(HOOKS_DIR, script)
        if not os.path.exists(p):
            continue
        try:
            r = subprocess.run([p], input=payload, stdout=subprocess.PIPE, stderr=subprocess.PIPE,
                               universal_newlines=True, timeout=25, env=os.environ.copy())
        except Exception as e:     # noqa: BLE001
            add(out, 'ask', 'AG-06', 'penjaga tulis tidak dapat dijalankan (%s)' % e)
            continue
        if r.returncode == 2:
            m = re.search(r'DIBLOKIR \[([A-Z]+-[0-9]+)\]:\s*(.*)', r.stderr or '')
            add(out, 'block', m.group(1) if m else 'AG-06', (m.group(2) if m else (r.stderr or 'ditolak penjaga tulis')).strip()[:300])
        elif r.stdout.strip():
            try:
                j = json.loads(r.stdout)
                h = j.get('hookSpecificOutput', {})
                if h.get('permissionDecision') == 'ask':
                    why = h.get('permissionDecisionReason', 'perubahan butuh persetujuan')
                    rule = 'AG-15' if 'brief' in why.lower() and 'approved' in why.lower() else \
                        ('AG-09' if 'aturan mesin' in why.lower() else ('SC-07' if 'rahasia' in why.lower() or 'secret' in why.lower() else 'AG-06'))
                    add(out, 'ask', rule, why)
            except ValueError:
                pass


def check_writes(name, args, seg, seg_text, ctx, out):
    items = []
    for op, tgt in seg.redirs:
        if op in WRITE_REDIR_OPS and tgt:
            items.append((tgt, 'write'))
    if name:
        items.extend(write_targets(name, args))
    seen = set()
    for raw, kind in items:
        if raw in ('/dev/null', '/dev/stdout', '/dev/stderr', '/dev/tty') or raw.startswith('/dev/fd/'):
            continue
        path = resolve(raw, ctx)
        if not path:
            continue
        if (path, kind) in seen:
            continue
        seen.add((path, kind))
        if is_secret_path(path) and kind != 'remove':
            add(out, 'block', 'SC-07', 'menulis ke berkas secret (%s) dilarang; gunakan .env.example' % raw)
            continue
        rel_claude = ctx.root and any(path.startswith(os.path.join(ctx.root, d) + os.sep) for d in ('.claude', '.devcore'))
        if kind == 'remove' and not rel_claude:
            continue
        content = '' if kind == 'remove' else seg_text
        delegate(path, content, ctx, out)
        if re.search(r'docs/briefs/[^/]+\.md$', path) and re.search(r'approved', seg_text, re.I):
            add(out, 'ask', 'AG-15', 'brief diubah menjadi approved lewat shell; setujui hanya bila Anda menyetujui isi brief')


# ----------------------------------------------------------------------------
# Skrip dan pipeline
# ----------------------------------------------------------------------------
def analyze_script(text, ctx, depth, out):
    if depth > MAX_DEPTH:
        add(out, 'ask', 'AG-06', 'perintah bersarang terlalu dalam untuk diperiksa')
        return
    tokens, subs = tokenize(text)
    for body in [t[1] for t in tokens if t[0] == 'h' and not t[2]]:
        subs.extend(extract_subs(body))
    for sub in subs:
        analyze_script(sub, ctx, depth + 1, out)
    segs = build_segments(tokens)

    # kelompokkan pipeline
    groups = []
    for seg in segs:
        if groups and seg.sep_before in ('|', '|&'):
            groups[-1].append(seg)
        else:
            groups.append([seg])

    for group in groups:
        pipeline_text = '\n'.join(' '.join(s.words) + '\n' + '\n'.join(b for b, _ in s.heredocs) for s in group)
        effective = []
        for seg in group:
            words = list(seg.words)
            while words and (words[0] in KEYWORDS or ASSIGN_RE.match(words[0])):
                words.pop(0)
            if words and words[0] in SKIP_LINES:
                effective.append((None, [], seg))
                continue
            info = {'heredocs': seg.heredocs, 'pipeline_text': pipeline_text}
            res = None
            if words:
                res = check_effective(words, out, ctx, depth, info)
            name, args = (res if res else (None, []))
            # cd sederhana: perbarui cwd untuk perintah berikutnya
            if name == 'cd' and args:
                tgt = resolve(positional(args)[0] if positional(args) else '', ctx)
                if tgt:
                    ctx.cwd = tgt
            seg_text = '\n'.join([w for w in seg.words] + [b for b, _ in seg.heredocs] + [pipeline_text])
            check_writes(name, args, seg, seg_text, ctx, out)
            for op, tgt in seg.redirs:
                if op == '<<<':
                    if name in SHELLS and reads_stdin(name, args):
                        analyze_script(tgt, ctx, depth + 1, out)
                elif op in ('<', '<>') and tgt and is_secret_path(tgt):
                    add(out, 'block', 'AG-07', 'membaca berkas secret lewat redirect (%s)' % tgt)
            effective.append((name, args, seg))

        # aturan lintas-pipa
        for j, (nj, aj, sj) in enumerate(effective):
            if nj is None:
                continue
            if nj in ('curl', 'wget', 'fetch'):
                for k in range(j + 1, len(effective)):
                    nk, ak, sk = effective[k]
                    if nk and (nk in SHELLS or INTERP_RE.match(nk)) and reads_stdin(nk, ak):
                        add(out, 'block', 'DP-06', 'mengalirkan unduhan langsung ke %s (curl | sh)' % nk)
            decoder = (nj == 'base64' and any(x in ('-d', '-D', '--decode') for x in aj)) \
                or (nj == 'xxd' and '-r' in aj) or (nj == 'openssl' and 'enc' in aj and '-d' in aj)
            if decoder:
                for k in range(j + 1, len(effective)):
                    nk, ak, sk = effective[k]
                    if nk and (nk in SHELLS or INTERP_RE.match(nk)) and reads_stdin(nk, ak):
                        add(out, 'block', 'AG-06', 'dekode lalu eksekusi (%s | %s) menyembunyikan perintah' % (nj, nk))
            if nj in TEXT_CMDS:
                for k in range(j + 1, len(effective)):
                    nk, ak, sk = effective[k]
                    if nk in SHELLS and reads_stdin(nk, ak):
                        analyze_script(' '.join(aj), ctx, depth + 1, out)


def decide(findings):
    blocks = [f for f in findings if f[0] == 'block']
    asks = [f for f in findings if f[0] == 'ask']
    if blocks:
        return {'decision': 'block', 'rule': blocks[0][1], 'reason': blocks[0][2]}
    if asks:
        seen = []
        for f in asks:
            if f[2] not in seen:
                seen.append(f[2])
        return {'decision': 'ask', 'rule': asks[0][1], 'reason': '; '.join(seen)}
    return {'decision': 'allow'}


def main():
    try:
        data = json.load(sys.stdin)
    except ValueError:
        print(json.dumps({'decision': 'fallback', 'reason': 'JSON masukan tidak valid'}))
        return 0
    command = (data.get('tool_input') or {}).get('command') or ''
    if not command.strip():
        print(json.dumps({'decision': 'allow'}))
        return 0
    cwd = data.get('cwd') or os.getcwd()
    root = os.environ.get('CLAUDE_PROJECT_DIR') or cwd
    ctx = Ctx(os.path.normpath(cwd), os.path.normpath(root).rstrip(os.sep) if root else '')
    out = []
    try:
        analyze_script(command, ctx, 0, out)
    except ParseError as e:
        print(json.dumps({'decision': 'fallback', 'reason': 'tidak dapat diparse: %s' % e}))
        return 0
    except Exception as e:      # noqa: BLE001
        print(json.dumps({'decision': 'fallback', 'reason': 'galat penganalisis: %s' % e}))
        return 0
    print(json.dumps(decide(out), ensure_ascii=False))
    return 0


if __name__ == '__main__':
    sys.exit(main())
