# -*- coding: utf-8 -*-
"""Kabal Digital Marketplace one-pager (EN), lean vector PDF: Helvetica text + official logo (JPEG), brand palette.
Small enough (~25 KB) to attach through the Gmail API from the chat."""
import base64, zlib, datetime
W, H = 612, 792
NAVY=(0.078,0.118,0.149); TEAL=(0.027,0.322,0.349); LIME=(0.435,0.851,0.016); TEAL2=(0.165,0.439,0.365)
DARK=(0.11,0.16,0.19); GREY=(0.36,0.42,0.43); SOFT=(0.878,0.957,0.961); OFF=(0.94,0.957,0.953); WHITE=(1,1,1); MINT=(0.612,0.769,0.38)
def esc(s): return s.replace('\\','\\\\').replace('(','\\(').replace(')','\\)')
_W={' ':278,'!':278,'"':355,'#':556,'$':556,'%':889,'&':667,"'":191,'(':333,')':333,'*':389,'+':584,',':278,'-':333,'.':278,'/':278,'0':556,'1':556,'2':556,'3':556,'4':556,'5':556,'6':556,'7':556,'8':556,'9':556,':':278,';':278,'<':584,'=':584,'>':584,'?':556,'@':1015,'A':667,'B':667,'C':722,'D':722,'E':667,'F':611,'G':778,'H':722,'I':278,'J':500,'K':667,'L':556,'M':833,'N':722,'O':778,'P':667,'Q':778,'R':722,'S':667,'T':611,'U':722,'V':667,'W':944,'X':667,'Y':667,'Z':611,'[':278,']':278,'a':556,'b':556,'c':500,'d':556,'e':556,'f':278,'g':556,'h':556,'i':222,'j':222,'k':500,'l':222,'m':833,'n':556,'o':556,'p':556,'q':556,'r':333,'s':500,'t':278,'u':556,'v':500,'w':722,'x':500,'y':500,'z':500,'·':278,'–':556,'—':1000}
_WB=dict(_W); _WB.update({'a':556,'b':611,'c':556,'d':611,'e':556,'f':333,'g':611,'h':611,'i':278,'j':278,'k':556,'l':278,'m':889,'n':611,'o':611,'p':611,'q':611,'r':389,'s':556,'t':333,'u':611,'v':556,'w':778,'x':556,'y':556,'z':500,'A':722,'B':722,'C':722,'D':722,'E':667,'F':611,'G':778,'H':722,'I':278,'J':556,'K':722,'L':611,'M':833,'N':722,'O':778,'P':667,'Q':778,'R':722,'S':667,'T':611,'U':722,'V':667,'W':944,'X':667,'Y':667,'Z':611})
def width(s,size,bold=False): t=_WB if bold else _W; return sum(t.get(ch,556) for ch in s)*size/1000.0
def wrap(text,size,maxw,bold=False):
    words,lines,cur=text.split(' '),[],''
    for w in words:
        t=(cur+' '+w).strip()
        if width(t,size,bold)<=maxw or not cur: cur=t
        else: lines.append(cur); cur=w
    if cur: lines.append(cur)
    return lines
ops=[]
def rgb(c,fill=True): ops.append('%.3f %.3f %.3f %s'%(c[0],c[1],c[2],'rg' if fill else 'RG'))
def rect(x,y,w,h,c): rgb(c); ops.append('%.1f %.1f %.1f %.1f re f'%(x,y,w,h))
def text(x,y,s,size=9.5,bold=False,c=DARK): rgb(c); ops.append('BT /%s %.1f Tf %.1f %.1f Td (%s) Tj ET'%('F2' if bold else 'F1',size,x,y,esc(s)))
def rich(x,y,parts,size):  # parts: [(text,bold,color)]
    for s,b,c in parts: text(x,y,s,size,b,c); x+=width(s,size,b)
def para(x,y,s,size,maxw,bold=False,c=DARK,lead=None):
    lead=lead or size*1.32
    for ln in wrap(s,size,maxw,bold): text(x,y,ln,size,bold,c); y-=lead
    return y
def bullets(x,y,items,size,maxw,c=DARK):
    for it in items:
        rect(x,y+2.4,3.2,3.2,LIME)
        if isinstance(it,tuple):
            b,rest=it; lines=wrap(b+' '+rest,size,maxw-9,False)
            # first line: bold prefix
            first=lines[0]
            if first.startswith(b): rich(x+9,y,[(b,True,DARK),(first[len(b):],False,c)],size)
            else: text(x+9,y,first,size,False,c)
            y-=size*1.32
            for ln in lines[1:]: text(x+9,y,ln,size,False,c); y-=size*1.32
        else: y=para(x+9,y,it,size,maxw-9,False,c)
        y-=1.4
    return y
def section(x,y,title,w): text(x,y,title.upper(),7.8,True,TEAL); rect(x,y-4,w,0.9,TEAL); return y-14
def image(name,x,y,w,h): ops.append('q %.1f 0 0 %.1f %.1f %.1f cm /%s Do Q'%(w,h,x,y,name))

# ---- header band (navy) with official logo -----------------------------------
rect(0,H-92,W,92,NAVY); rect(0,H-96,W,4,LIME)
image('Im1',40,H-74,150,44.6)   # 360x107 -> 150x44.6
title='Kabal Digital Marketplace'
text(W-40-width(title,20,True),H-44,title,20,True,WHITE)
for k,sub in enumerate(['INSTITUTIONAL LIQUIDITY PARTNER BRIEF','OPERATED BY KABAL BRIDGE S.A. DE C.V. · CNAD LICENCE PSAD-0056']):
    text(W-40-width(sub,7.2),H-58-k*10.5,sub,7.2,False,MINT)
# ---- key strip ------------------------------------------------------------------
y0=H-140; rect(40,y0,W-80,42,SOFT); cw=(W-80)/4.0
for i,(big,small) in enumerate([('Licensed venue','LEAD framework · CNAD oversight'),('6 asset classes','trade finance to real estate'),('Base · USDC','DvP settlement, ERC-7943 tokens'),('Monthly reporting','to holders and CNAD, on-chain trail')]):
    x=40+i*cw+10; text(x,y0+24,big,12,True,TEAL); text(x,y0+11,small,7.4,False,TEAL2)
    if i: rect(40+i*cw,y0+6,0.6,30,(0.78,0.85,0.84))
colw=(W-80-22)/2.0; xl,xr=40,40+colw+22; yl=y0-22; yr=y0-22
# ---- left column ------------------------------------------------------------------
yl=section(xl,yl,'What it is',colw)
yl=para(xl,yl,'A regulated marketplace where tokenized real-economy assets from Central America and Mexico are issued and traded. Kabal Bridge S.A. de C.V., licensed by the Comisión Nacional de Activos Digitales of El Salvador (PSAD-0056), operates the venue under published Listing Rules, Trading Rules, Investor Terms, a platform-level AML/KYC policy and a Conflicts of Interest policy. We are building its network of institutional liquidity partners.',9.2,colw)
yl-=5; yl=section(xl,yl,'Assets that flow through the venue',colw)
yl=bullets(xl,yl,[('Trade finance','secured by endorsed bills of lading and cargo insurance, 60–180 day tenors · 12–18% target APY'),('Receivables / factoring','against verified invoices · 10–15% target APY'),('Real estate','via SPV with independent valuation · 6–12% target APY'),('Renewable energy','PPA cash flows · 8–14% target APY'),('Commodities','in certified custody · financing yield'),('Private credit / SME pools','originated by Kabal Capital and Kabal Trade Finance · per DIR')],9.0,colw)
text(xl,yl,'Yields are indicative targets set per issuance in its DIR; they are not guaranteed.',7.4,False,GREY); yl-=12
yl-=3; yl=section(xl,yl,'How an issuance works',colw)
steps=[('1 · Certify','Independent certifier verifies existence, valuation, title, liens, insurance.'),('2 · Register','DIR on the marketplace template; CNAD registration (0.01% fee, typically 4–8 weeks).'),('3 · List and fund','KYC-whitelisted investors subscribe; ERC-7943 tokens on Base, audited by Hacken.'),('4 · Distribute and trade','Monthly USDC distributions; secondary trading with DvP settlement.')]
bw=(colw-8)/2.0; ytop=yl
for i,(t,b) in enumerate(steps):
    cx=xl+(i%2)*(bw+8); cy=ytop-(i//2)*64
    rect(cx,cy-52,bw,58,OFF); text(cx+7,cy-6,t,8.6,True,TEAL); para(cx+7,cy-18,b,8.0,bw-14,False,DARK,9.6)
yl=ytop-64*2+6
yl=section(xl,yl,'Protections',colw)
yl=bullets(xl,yl,['Collateral pledged to the vehicle: bills of lading, assigned invoices, property, custody receipts.','Insurance and reserve funds where the asset calls for them; waterfall priority of payments; concentration limits per borrower, sector, carrier and geography.','Platform AML/KYC aligned with LEAD, CNAD and FATF; market-integrity rules; conflicts disclosure.'],9.0,colw)
# ---- right column ------------------------------------------------------------------
yr=section(xr,yr,'Ways to participate',colw)
for b,rest in [('Anchor allocation','— commit to primary issuances that match your mandate (asset class, tenor, ticket, geography), with first look at the pipeline.'),('Programmatic facility','— credit line or warehouse to the originating vehicles, with marketplace issuances as the take-out.'),('Private-placement note','— the same collateral package in a note format for mandates that cannot hold tokens.'),('Secondary liquidity','— market-making or block trades through the order book, bulletin board and OTC desk.')]:
    lines=wrap(b+' '+rest,8.9,colw-16,False); hgt=len(lines)*11.8+9
    rect(xr,yr-hgt+8,colw,hgt,OFF); rect(xr,yr-hgt+8,2.6,hgt,LIME)
    yy=yr-3
    for j,ln in enumerate(lines):
        if j==0 and ln.startswith(b): rich(xr+10,yy,[(b,True,TEAL),(ln[len(b):],False,DARK)],8.9)
        else: text(xr+10,yy,ln,8.9,False,DARK)
        yy-=11.8
    yr=yr-hgt-4
yr-=4; yr=section(xr,yr,'Stack and partners',colw)
yr=bullets(xr,yr,[('Base','(Coinbase L2), the only chain of the ecosystem · ERC-7943 (uRWA) compliance-aware standard'),('Hacken','audits · PrimeVault + Fireblocks custody · Circle USDC settlement'),('Brickken','tokenization platform (ISO 27001) · CargoX, WaveBL, Contour electronic bills of lading · BIVO Inc. US rails')],9.0,colw)
yr-=3; yr=section(xr,yr,'The group behind the pipeline',colw)
yr=bullets(xr,yr,[('Kabal Bridge','(El Salvador) — operator and structurer, PSAD-0056'),('Kabal Trade Finance','(Panama) — trade-finance operations and supplier payments'),('Kabal Capital','(Honduras) — non-bank lender originating SME credit and receivables'),('Kabal Pay · Kabal Send · Kabal Invest','— payments, remittances and the marketplace')],9.0,colw)
yr-=3; yr=section(xr,yr,'Documentation after NDA',colw)
yr=bullets(xr,yr,['Rulebook (listing, trading, investor terms), DIR template and certifier reports','Pipeline preview, economic terms per mandate, data room'],9.0,colw)
yr-=4; boxh=64; rect(xr,yr-boxh+8,colw,boxh,TEAL)
rich(xr+10,yr-6,[('Next step: ',True,LIME),('a 20-minute call to match your mandate',False,WHITE)],9.0)
text(xr+10,yr-18,'with the pipeline and the participation format.',9.0,False,WHITE)
rich(xr+10,yr-33,[('Guillermo Kattan',True,LIME),(' · CEO, Kabal · gkattan@soykabal.com',False,WHITE)],8.6)
text(xr+10,yr-45,'contacto@soykabal.com · soykabal.com · San Salvador',8.4,False,WHITE)
# ---- footer -------------------------------------------------------------------------
rect(0,0,W,64,OFF); rect(0,64,W,1.4,TEAL)
text(40,52,'Kabal Digital Marketplace · Kabal Bridge S.A. de C.V. · CNAD licence PSAD-0056 · '+datetime.date.today().strftime('%B %Y'),7.6,True,TEAL)
image('Im2',W-40-62,44,62,18.3)
para(40,40,'For institutional and qualified investors only. This document is informational and does not constitute an offer or solicitation where such offer is not authorized. Digital assets involve significant risk, including the possible loss of capital. Yields are indicative targets and are not guaranteed. Each issuance is subject to CNAD registration and to its own Relevant Information Document (DIR); read the DIR before investing. Participation is subject to qualified-investor status under the LEAD framework of El Salvador and to KYC/AML clearance. Pricing and terms under NDA. Kabal Capital S.A. de C.V. is a non-bank lender in Honduras and is not supervised by the CNBS.',6.6,W-80,False,GREY,8.6)
# ---- assemble --------------------------------------------------------------------------
content=zlib.compress('\n'.join(ops).encode('cp1252','replace'),9)
j1=open('logo_dark_on_navy.jpg','rb').read(); j2=open('logo_light_on_grey.jpg','rb').read()
objs=[b'<< /Type /Catalog /Pages 2 0 R >>', b'<< /Type /Pages /Kids [3 0 R] /Count 1 >>',
 b'<< /Type /Page /Parent 2 0 R /MediaBox [0 0 612 792] /Contents 4 0 R /Resources << /Font << /F1 5 0 R /F2 6 0 R >> /XObject << /Im1 8 0 R /Im2 9 0 R >> >> >>',
 b'<< /Length %d /Filter /FlateDecode >>\nstream\n'%len(content)+content+b'\nendstream',
 b'<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica /Encoding /WinAnsiEncoding >>',
 b'<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica-Bold /Encoding /WinAnsiEncoding >>',
 b'<< /Title (Kabal Digital Marketplace - Institutional Liquidity Partner Brief) /Author (Kabal Bridge S.A. de C.V.) /Producer (Kabal Liquidity Agent) >>',
 b'<< /Type /XObject /Subtype /Image /Width 360 /Height 107 /ColorSpace /DeviceRGB /BitsPerComponent 8 /Filter /DCTDecode /Length %d >>\nstream\n'%len(j1)+j1+b'\nendstream',
 b'<< /Type /XObject /Subtype /Image /Width 200 /Height 59 /ColorSpace /DeviceRGB /BitsPerComponent 8 /Filter /DCTDecode /Length %d >>\nstream\n'%len(j2)+j2+b'\nendstream']
out=b'%PDF-1.4\n%\xe2\xe3\xcf\xd3\n'; offs=[]
for i,o in enumerate(objs,1): offs.append(len(out)); out+=b'%d 0 obj\n'%i+o+b'\nendobj\n'
xref=len(out); out+=b'xref\n0 %d\n0000000000 65535 f \n'%(len(objs)+1)+b''.join(b'%010d 00000 n \n'%o for o in offs)
out+=b'trailer\n<< /Size %d /Root 1 0 R /Info 7 0 R >>\nstartxref\n%d\n%%%%EOF\n'%(len(objs)+1,xref)
name='Kabal_Digital_Marketplace_One_Pager_EN.pdf'
open('lean_'+name,'wb').write(out); open('lean_'+name+'.b64','w').write(base64.b64encode(out).decode())
print(name,len(out),'bytes; b64',len(base64.b64encode(out)),'chars; min y left/right',round(yl),round(yr-boxh+8))
