# SCRATCH — throwaway scan, not part of the test surface.  The real check
# lives in tests/check-chain.sh step 2.  Delete with `git rm dupscan.py'.
import re, glob, collections

names = collections.defaultdict(list)
for f in sorted(glob.glob('sane-packages/**/*.scm', recursive=True)):
    with open(f, encoding='utf-8', errors='replace') as fh:
        for i, line in enumerate(fh, 1):
            m = re.match(r'\s*\(define-public\s+([^\s()\[\]#";]+)', line)
            if m:
                names[m.group(1)].append(f'{f}:{i}')

dups = {k: v for k, v in names.items() if len(v) > 1}
print('total define-public:', sum(len(v) for v in names.values()),
      'distinct:', len(names))
print('DUPLICATES:', dups if dups else 'none')
