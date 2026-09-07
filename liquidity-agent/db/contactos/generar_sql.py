import json, glob, os, re, sys
OUT=os.path.dirname(os.path.abspath(__file__))  # JSON de investigacion; el SQL sale en ./sql/
# institucion (as returned) -> liq_proveedores.nombre
MAP={
 'BlackRock':'BlackRock','Apollo Global Management':'Apollo Global Management','Santander':'Santander',
 'Mubadala Capital':'Mubadala Capital','Itaú Unibanco':'Itaú Unibanco','BNP Paribas':'BNP Paribas',
 'Africa Finance Corporation':'Africa Finance Corporation','Franklin Templeton':'Franklin Templeton',
 'Hamilton Lane':'Hamilton Lane','Neuberger Berman':'Neuberger Berman','KKR':'KKR','Galaxy Digital':'Galaxy Digital',
 'Midas / Fasanara Capital':'Midas / Fasanara Capital','Centrifuge':'Centrifuge','Etherfuse':'Etherfuse','Goldfinch':'Goldfinch',
 'Maple Finance':'Maple Finance','Ondo Finance':'Ondo Finance','Plume Network':'Plume Network','Brickken':'Brickken',
 'Figure Technology Solutions (FIGR)':'Figure Technology Solutions (FIGR)','Komgo':'Komgo','Liqi Digital Assets':'Liqi Digital Assets',
 'OpenAssets':'OpenAssets','Securitize':'Securitize','Tradable':'Tradable'}
EMAIL=re.compile(r'[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}')
ROLES={'dueno_programa','decisor','entrada','influencer','cobertura_latam','canal_generico'}
def q(s):
    if s is None: return 'null'
    return "'"+str(s).replace("'","''")+"'"
def clean_email(e, notas):
    if not e: return None, notas
    m=EMAIL.search(e)
    if not m: return None, (notas or '')+' | email bruto: '+e
    rest=e.replace(m.group(0),'').strip(' ()')
    if rest: notas=((notas or '')+' | email: '+rest).strip(' |')
    return m.group(0).lower(), notas
files=sys.argv[1:] or sorted(glob.glob(os.path.join(OUT,'*.json')))
sql=[]
for f in files:
    it=json.load(open(f))
    prov=MAP.get(it['institucion'])
    if not prov: print('SKIP unmapped', it['institucion'], file=sys.stderr); continue
    fe=it.get('formato_email') or {}
    canales=json.dumps(it.get('canales_publicos') or [], ensure_ascii=False)
    prio1=None
    rows=[]
    seen=set()
    for c in it.get('contactos') or []:
        nombre=(c.get('nombre') or '').strip()
        if not nombre:
            nombre='[por identificar] '+(c.get('cargo') or 'contacto')[:120]
        if nombre.lower() in seen: continue
        seen.add(nombre.lower())
        notas=c.get('notas')
        email,notas=clean_email(c.get('email'), notas)
        estado=c.get('email_estado') or 'desconocido'
        if not email: estado='desconocido'
        if estado not in ('publico','patron_no_verificado','verificado','rebotado','desconocido'): estado='desconocido'
        rol=c.get('rol') if c.get('rol') in ROLES else 'entrada'
        try: pr=int(c.get('prioridad') or 3)
        except: pr=3
        pr=max(1,min(5,pr))
        rows.append((nombre,c.get('cargo'),c.get('area'),c.get('ubicacion'),c.get('linkedin'),email,estado,rol,pr,c.get('por_que'),c.get('fuente'),notas))
    rows.sort(key=lambda r:(r[8]))
    owner=next((r for r in rows if r[7]=='dueno_programa'),None)
    first=rows[0] if rows else None
    pub=next((r for r in rows if r[6]=='publico'),None)
    decisor=(owner[0]+' — '+(owner[1] or '')) if owner else None
    contacto_email=pub[5] if pub else None
    s=[]
    s.append(f"""with p as (select id from liq_proveedores where nombre={q(prov)})
update liq_proveedores set email_patron={q(fe.get('patron'))}, email_patron_fuente={q((fe.get('fuente') or '')+' · confianza: '+(fe.get('confianza') or '?'))},
 canales_publicos={q(canales)}::jsonb, ruta_recomendada={q(it.get('ruta_recomendada'))},
 decisor=coalesce({q(decisor)},decisor), contacto_email=coalesce(contacto_email,{q(contacto_email)}),
 notas=coalesce(notas,'')||E'\\n[Contactos '||to_char(now(),'YYYY-MM-DD')||'] Programa: '||{q(it.get('programa'))}||E'\\n'||{q(it.get('notas'))}
where id=(select id from p);""")
    if rows:
        vals=',\n'.join('('+','.join((str(v) if i==8 else q(v)) for i,v in enumerate(r))+')' for r in rows)
        s.append(f"""insert into liq_contactos (proveedor_id,nombre,cargo,area,ubicacion,linkedin,email,email_estado,rol,prioridad,por_que,fuente,notas)
select (select id from liq_proveedores where nombre={q(prov)}), v.* from (values
{vals}) as v(nombre,cargo,area,ubicacion,linkedin,email,email_estado,rol,prioridad,por_que,fuente,notas)
on conflict (proveedor_id, lower(nombre)) do update set cargo=excluded.cargo, area=excluded.area, ubicacion=excluded.ubicacion,
 linkedin=coalesce(excluded.linkedin,liq_contactos.linkedin), email=coalesce(excluded.email,liq_contactos.email), email_estado=excluded.email_estado,
 rol=excluded.rol, prioridad=excluded.prioridad, por_que=excluded.por_que, fuente=excluded.fuente, notas=excluded.notas;""")
    out=os.path.join(OUT,'sql',os.path.basename(f).replace('.json','.sql'))
    os.makedirs(os.path.dirname(out),exist_ok=True)
    open(out,'w').write('\n'.join(s)+'\n')
    print(os.path.basename(out), len('\n'.join(s)), 'bytes', len(rows),'contactos')
