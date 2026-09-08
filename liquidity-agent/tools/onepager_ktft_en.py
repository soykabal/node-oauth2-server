# -*- coding: utf-8 -*-
"""KTFT institutional one-pager (EN) — vector-only PDF with standard fonts (tiny, attachable by API).
Brand: teal #075259, lime #6FD904, dark #141E26, secondary #2a705d, #798485."""
import base64, sys, zlib, datetime

W, H = 612, 792  # Letter
TEAL, LIME, DARK, GREY, SOFT = (0.027, 0.322, 0.349), (0.435, 0.851, 0.016), (0.078, 0.118, 0.149), (0.475, 0.518, 0.522), (0.89, 0.918, 0.914)

def esc(s):
    return s.replace('\\', '\\\\').replace('(', '\\(').replace(')', '\\)')

# Helvetica widths (AFM, 1/1000 em) for wrapping — subset; default 556
_W = {' ':278,'!':278,'"':355,'#':556,'$':556,'%':889,'&':667,"'":191,'(':333,')':333,'*':389,'+':584,',':278,'-':333,'.':278,'/':278,
      '0':556,'1':556,'2':556,'3':556,'4':556,'5':556,'6':556,'7':556,'8':556,'9':556,':':278,';':278,'<':584,'=':584,'>':584,'?':556,'@':1015,
      'A':667,'B':667,'C':722,'D':722,'E':667,'F':611,'G':778,'H':722,'I':278,'J':500,'K':667,'L':556,'M':833,'N':722,'O':778,'P':667,'Q':778,
      'R':722,'S':667,'T':611,'U':722,'V':667,'W':944,'X':667,'Y':667,'Z':611,'[':278,']':278,'a':556,'b':556,'c':500,'d':556,'e':556,'f':278,
      'g':556,'h':556,'i':222,'j':222,'k':500,'l':222,'m':833,'n':556,'o':556,'p':556,'q':556,'r':333,'s':500,'t':278,'u':556,'v':500,'w':722,
      'x':500,'y':500,'z':500,'·':278,'–':556,'—':1000,'/':278}
_WB = dict(_W); _WB.update({'a':556,'b':611,'c':556,'d':611,'e':556,'f':333,'g':611,'h':611,'i':278,'j':278,'k':556,'l':278,'m':889,'n':611,'o':611,'p':611,'q':611,'r':389,'s':556,'t':333,'u':611,'v':556,'w':778,'x':556,'y':556,'z':500,'A':722,'B':722,'C':722,'D':722,'E':667,'F':611,'G':778,'H':722,'I':278,'J':556,'K':722,'L':611,'M':833,'N':722,'O':778,'P':667,'Q':778,'R':722,'S':667,'T':611,'U':722,'V':667,'W':944,'X':667,'Y':667,'Z':611,' ':278,'.':278,',':278,':':333,'-':333,'(':333,')':333,'/':278})

def width(s, size, bold=False):
    t = _WB if bold else _W
    return sum(t.get(ch, 556) for ch in s) * size / 1000.0

def wrap(text, size, maxw, bold=False):
    words, lines, cur = text.split(' '), [], ''
    for w in words:
        t = (cur + ' ' + w).strip()
        if width(t, size, bold) <= maxw or not cur: cur = t
        else: lines.append(cur); cur = w
    if cur: lines.append(cur)
    return lines

ops = []
def rgb(c, fill=True): ops.append('%.3f %.3f %.3f %s' % (c[0], c[1], c[2], 'rg' if fill else 'RG'))
def rect(x, y, w, h, c): rgb(c); ops.append('%.1f %.1f %.1f %.1f re f' % (x, y, w, h))
def text(x, y, s, size=9.5, bold=False, c=DARK):
    rgb(c); ops.append('BT /%s %.1f Tf %.1f %.1f Td (%s) Tj ET' % ('F2' if bold else 'F1', size, x, y, esc(s)))
def para(x, y, s, size, maxw, bold=False, c=DARK, lead=None):
    lead = lead or size * 1.32
    for ln in wrap(s, size, maxw, bold):
        text(x, y, ln, size, bold, c); y -= lead
    return y
def bullets(x, y, items, size, maxw, c=DARK):
    for it in items:
        rect(x, y + 2.6, 3.2, 3.2, LIME)
        y = para(x + 9, y, it, size, maxw - 9, False, c)
        y -= 1.5
    return y
def section(x, y, title, w):
    text(x, y, title.upper(), 8.2, True, TEAL)
    rect(x, y - 4.2, w, 0.8, TEAL)
    return y - 15

# ---- header band ------------------------------------------------------------
rect(0, H - 96, W, 96, TEAL)
rect(0, H - 100, W, 4, LIME)
text(40, H - 46, 'Kabal', 26, True, (1, 1, 1))
rect(40, H - 52, 66, 2.2, LIME)
text(40, H - 70, 'Kabal Trade Finance Token (KTFT)', 15, True, (1, 1, 1))
text(40, H - 86, 'Regulated trade-finance yield from Central America  ·  Institutional one-pager', 9.2, False, (0.85, 0.93, 0.92))
text(W - 40 - width('Kabal Bridge S.A. de C.V.  ·  CNAD license PSAD-0056  ·  El Salvador', 8.2), H - 46, 'Kabal Bridge S.A. de C.V.  ·  CNAD license PSAD-0056  ·  El Salvador', 8.2, False, (0.85, 0.93, 0.92))

# ---- key figures strip ----------------------------------------------------------
y0 = H - 150
rect(40, y0, W - 80, 44, SOFT)
figs = [('USD 5M', 'first issuance · 500,000 tokens'), ('12–18% APY', 'target yield · monthly · not guaranteed'),
        ('1.25x', 'minimum reserve-fund coverage'), ('110%', 'cargo insurance on each credit')]
cw = (W - 80) / 4.0
for i, (big, small) in enumerate(figs):
    x = 40 + i * cw + 12
    text(x, y0 + 24, big, 16, True, TEAL)
    text(x, y0 + 11, small, 7.8, False, GREY)

# ---- two columns -----------------------------------------------------------------
colw = (W - 80 - 22) / 2.0
xl, xr = 40, 40 + colw + 22
yl = y0 - 22
yl = section(xl, yl, 'What it is', colw)
yl = para(xl, yl, 'A tokenized trade-finance vehicle issued by Kabal Bridge S.A. de C.V., a digital asset issuer licensed by the CNAD of El Salvador (PSAD-0056) under the LEAD framework. Proceeds fund short-tenor import finance for small and mid-size companies in Central America and Mexico, secured by endorsed bills of lading and commercial invoices.', 9.5, colw)
yl -= 6
yl = section(xl, yl, 'Structure', colw)
yl = bullets(xl, yl, [
    'Programme target USD 200M (20M tokens at USD 10) issued in 7 Just-in-Time phases; the next phase opens only when 85% of the previous capital is deployed against a verified pipeline.',
    'First issuance: USD 5 million / 500,000 tokens.',
    'Target yield 12–18% APY (12% base + 0–6% performance), distributed monthly. Targets, not guaranteed.',
    'Token standard ERC-7943 (uRWA) on Base; smart contract audited by Hacken.',
    'Custody and settlement: PrimeVault, Fireblocks and Circle (USDC).',
], 9.3, colw)
yl -= 4
yl = section(xl, yl, 'Portfolio', colw)
yl = bullets(xl, yl, [
    'Import finance collateralized by endorsed bills of lading and commercial invoices.',
    'Geography of the pipeline: Mexico 65%, Honduras 15%, Guatemala 10%, El Salvador 5%, other Central America 5%.',
], 9.3, colw)

yr = y0 - 22
yr = section(xr, yr, 'Protections', colw)
yr = bullets(xr, yr, [
    'Cargo insurance at 110% of each financed credit.',
    'Reserve fund with a minimum 1.25x coverage of scheduled distributions.',
    'Bills of lading pledged to the vehicle; independent external certifier of the collateral.',
    'KYC/AML clearance before any disbursement; monthly reporting to token holders.',
], 9.3, colw)
yr -= 4
yr = section(xr, yr, 'Ways to participate', colw)
yr = bullets(xr, yr, [
    'KTFT subscription (private offering for qualified investors; LEAD threshold USD 500K).',
    'Credit line or warehouse facility to the originating vehicle.',
    'Private-placement note with the same collateral package.',
], 9.3, colw)
yr -= 4
yr = section(xr, yr, 'Documentation available after NDA', colw)
yr = bullets(xr, yr, [
    'Institutional presentation and Whitepaper v3.',
    'Prospectus (Public Placement v3.0) and DIR with waterfall annex.',
    'CNAD filing (English) and data room.',
], 9.3, colw)
yr -= 4
yr = section(xr, yr, 'Next step', colw)
yr = para(xr, yr, 'A 20-minute call with our team to walk through the structure and the current pipeline.', 9.5, colw)
yr -= 3
text(xr, yr, 'Guillermo Kattan · CEO, Kabal', 8.8, True, TEAL); yr -= 12
text(xr, yr, 'gkattan@soykabal.com  ·  contacto@soykabal.com', 8.4, False, DARK); yr -= 12
text(xr, yr, 'San Salvador, El Salvador  ·  ' + datetime.date.today().strftime('%B %Y'), 8.0, False, GREY)

# ---- footer disclaimer ---------------------------------------------------------------
rect(0, 0, W, 58, SOFT)
rect(0, 58, W, 1.5, TEAL)
para(40, 44, 'For institutional and qualified investors only. This document is informational and does not constitute an offer or solicitation where such offer is not authorized. Digital assets involve significant risk, including the possible loss of capital. Yields are targets and are not guaranteed. Please read the Whitepaper and the DIR before investing. Subscription is subject to qualified-investor status under the LEAD framework of El Salvador and to KYC/AML clearance.', 6.9, W - 80, False, GREY, 9.2)

# ---- assemble PDF -------------------------------------------------------------------
content = '\n'.join(ops).encode('cp1252', 'replace')
content_z = zlib.compress(content, 9)
objs = [
    b'<< /Type /Catalog /Pages 2 0 R >>',
    b'<< /Type /Pages /Kids [3 0 R] /Count 1 >>',
    b'<< /Type /Page /Parent 2 0 R /MediaBox [0 0 612 792] /Contents 4 0 R /Resources << /Font << /F1 5 0 R /F2 6 0 R >> >> >>',
    b'<< /Length %d /Filter /FlateDecode >>\nstream\n' % len(content_z) + content_z + b'\nendstream',
    b'<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica /Encoding /WinAnsiEncoding >>',
    b'<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica-Bold /Encoding /WinAnsiEncoding >>',
    b'<< /Title (KTFT Institutional One-Pager) /Author (Kabal Bridge S.A. de C.V.) /Producer (Kabal Liquidity Agent) >>',
]
out = b'%PDF-1.4\n%\xe2\xe3\xcf\xd3\n'; offs = []
for i, o in enumerate(objs, 1):
    offs.append(len(out)); out += b'%d 0 obj\n' % i + o + b'\nendobj\n'
xref = len(out)
out += b'xref\n0 %d\n0000000000 65535 f \n' % (len(objs) + 1) + b''.join(b'%010d 00000 n \n' % o for o in offs)
out += b'trailer\n<< /Size %d /Root 1 0 R /Info 7 0 R >>\nstartxref\n%d\n%%%%EOF\n' % (len(objs) + 1, xref)
name = (sys.argv[1] if len(sys.argv) > 1 else 'Kabal_KTFT_One_Pager_EN.pdf')
open(name, 'wb').write(out)
open(name + '.b64', 'w').write(base64.b64encode(out).decode())
print(name, len(out), 'bytes; base64', len(base64.b64encode(out)), 'chars; min y left/right', round(yl), round(yr))
