#!/usr/bin/env node
'use strict';

/**
 * CLI del Agente de Liquidez.
 *
 *   node liquidity-agent/src/cli.js funnel [--meta 5000000]
 *   node liquidity-agent/src/cli.js pipeline [--etapa due_diligence]
 *   node liquidity-agent/src/cli.js lunes [--meta 5000000]
 *   node liquidity-agent/src/cli.js proveedores
 *   node liquidity-agent/src/cli.js proveedor:crear --nombre "FO Delta" --tipo family_office --pais Panamá --vehiculos ktft,emision_b2b
 *   node liquidity-agent/src/cli.js kyc --id <uuid> --estado verde
 *   node liquidity-agent/src/cli.js oportunidad:crear --proveedor <uuid> --nombre "FO Delta · KTFT E1" --vehiculo ktft --monto 500000 --paso "Enviar whitepaper" --fecha 2026-09-10
 *   node liquidity-agent/src/cli.js mover --id <uuid> --etapa compromiso_verbal [--monto 400000] [--paso "..."] [--fecha YYYY-MM-DD] [--motivo "..."]
 *   node liquidity-agent/src/cli.js interaccion --proveedor <uuid> [--oportunidad <uuid>] --tipo reunion --resumen "..." [--resultado "..."] [--siguiente "..."]
 *   node liquidity-agent/src/cli.js wire --oportunidad <uuid> --monto 400000 [--moneda USDC] [--ref 0x...] [--verificado]
 *   node liquidity-agent/src/cli.js perdidas
 *   node liquidity-agent/src/cli.js correos                       correos por etapa que esperan Gmail (o la dirección)
 *   node liquidity-agent/src/cli.js correo:ver --id <uuid>        muestra el correo listo para copiar/pegar
 *   node liquidity-agent/src/cli.js correo:marcar --id <uuid> --estado borrador|enviado|omitido [--para x@y.com] [--draft <gmailDraftId>]
 *
 * Requiere SUPABASE_URL y SUPABASE_KEY en el entorno.
 */

const crm = require('./crm');

function parseArgs(argv) {
  const out = { _: [] };
  for (let i = 0; i < argv.length; i++) {
    const a = argv[i];
    if (a.startsWith('--')) {
      const k = a.slice(2);
      const next = argv[i + 1];
      if (next === undefined || next.startsWith('--')) { out[k] = true; }
      else { out[k] = next; i++; }
    } else {
      out._.push(a);
    }
  }
  return out;
}

const fmtUsd = n => '$' + Number(n || 0).toLocaleString('en-US', { maximumFractionDigits: 0 });
const pad = (s, n) => String(s === null || s === undefined ? '' : s).padEnd(n).slice(0, n);

function tabla(filas, cols) {
  if (!filas.length) { console.log('  (vacío)'); return; }
  console.log('  ' + cols.map(c => pad(c.h, c.w)).join('  '));
  console.log('  ' + cols.map(c => '-'.repeat(c.w)).join('  '));
  filas.forEach(f => console.log('  ' + cols.map(c => pad(c.f ? c.f(f) : f[c.k], c.w)).join('  ')));
}

async function main() {
  const args = parseArgs(process.argv.slice(2));
  const cmd = args._[0];
  if (!cmd || cmd === 'help') {
    console.log(require('fs').readFileSync(__filename, 'utf8').split('\n').filter(l => l.startsWith(' *')).join('\n'));
    return;
  }
  const c = crm.crearCliente();
  const meta = args.meta ? Number(args.meta) : undefined;

  switch (cmd) {
  case 'funnel': {
    const filas = await c.funnel();
    tabla(filas, [
      { h: 'etapa', k: 'etapa', w: 18 }, { h: '#', k: 'oportunidades', w: 4 },
      { h: 'objetivo', w: 14, f: f => fmtUsd(f.monto_objetivo_usd) },
      { h: 'ponderado', w: 14, f: f => fmtUsd(f.monto_ponderado_usd) },
      { h: 'firmado', w: 14, f: f => fmtUsd(f.monto_firmado_usd) },
      { h: 'wired', w: 14, f: f => fmtUsd(f.monto_wired_usd) }
    ]);
    const r = crm.resumenFunnel(filas, meta);
    console.log('\n  activas: ' + r.activas + ' · ponderado ' + fmtUsd(r.ponderado_usd) + ' · comprometido ' + fmtUsd(r.comprometido_usd) +
      ' · firmado ' + fmtUsd(r.firmado_usd) + ' · wired ' + fmtUsd(r.wired_usd) +
      (meta ? ' · meta ' + fmtUsd(meta) + ' (' + r.avance_pct + '%, gap ' + fmtUsd(r.gap_usd) + ')' : ''));
    break;
  }
  case 'pipeline': {
    const filtro = args.etapa ? { etapa: 'eq.' + args.etapa } : undefined;
    const filas = crm.priorizar(await c.pipeline(filtro));
    tabla(filas, [
      { h: 'score', k: 'score', w: 5 }, { h: 'oportunidad', k: 'nombre', w: 34 }, { h: 'etapa', k: 'etapa', w: 18 },
      { h: 'ponderado', w: 12, f: f => fmtUsd(f.monto_ponderado_usd) }, { h: 'días', k: 'dias_en_etapa', w: 5 },
      { h: 'kyc', k: 'kyc_estado', w: 9 }, { h: 'próximo paso', w: 30, f: f => (f.proximo_paso || '—') + (f.fecha_proximo_paso ? ' (' + f.fecha_proximo_paso + ')' : '') },
      { h: 'alertas', w: 60, f: f => f.razones.join(' | ') }
    ]);
    console.log('\n  ' + filas.map(f => f.id + '  ' + f.nombre).join('\n  '));
    break;
  }
  case 'lunes': {
    const r = await c.lunesDeLiquidez(meta);
    console.log('LUNES DE LIQUIDEZ — ' + new Date().toISOString().slice(0, 10));
    console.log('  Wired ' + fmtUsd(r.resumen.wired_usd) + ' · Firmado ' + fmtUsd(r.resumen.firmado_usd) +
      ' · Comprometido ' + fmtUsd(r.resumen.comprometido_usd) + ' · Ponderado ' + fmtUsd(r.resumen.ponderado_usd) +
      (meta ? ' · Meta ' + fmtUsd(meta) + ' → gap ' + fmtUsd(r.resumen.gap_usd) : ''));
    console.log('\nPor vehículo');
    tabla(r.por_vehiculo, [
      { h: 'vehículo', k: 'vehiculo', w: 14 }, { h: 'activas', k: 'activas', w: 7 },
      { h: 'pipeline', w: 12, f: f => fmtUsd(f.pipeline_usd) }, { h: 'ponderado', w: 12, f: f => fmtUsd(f.ponderado_usd) },
      { h: 'firmado', w: 12, f: f => fmtUsd(f.firmado_usd) }, { h: 'wired', w: 12, f: f => fmtUsd(f.wired_usd) }
    ]);
    console.log('\nLos 3 más calientes (acción del día)');
    r.top3.forEach((f, i) => console.log('  ' + (i + 1) + '. ' + f.nombre + ' [' + f.etapa + ', ' + fmtUsd(f.monto_ponderado_usd) + '] → ' +
      (f.proximo_paso || 'DEFINIR PRÓXIMO PASO') + (f.fecha_proximo_paso ? ' (' + f.fecha_proximo_paso + ')' : '')));
    console.log('\nAlertas SLA');
    if (!r.alertas.length) { console.log('  ninguna'); }
    r.alertas.forEach(f => console.log('  · ' + f.nombre + ': ' + f.razones.join('; ')));
    break;
  }
  case 'proveedores': {
    tabla(await c.listarProveedores(), [
      { h: 'proveedor', k: 'nombre', w: 30 }, { h: 'tipo', k: 'tipo', w: 20 }, { h: 'país', k: 'pais', w: 12 },
      { h: 'kyc', k: 'kyc_estado', w: 10 }, { h: 'calif', k: 'calificacion', w: 8 }, { h: 'activas', k: 'activas', w: 7 },
      { h: 'pipeline', w: 12, f: f => fmtUsd(f.pipeline_usd) }, { h: 'wired', w: 12, f: f => fmtUsd(f.wired_usd) }, { h: 'id', k: 'id', w: 36 }
    ]);
    break;
  }
  case 'proveedor:crear': {
    const p = await c.crearProveedor({
      nombre: args.nombre, tipo: args.tipo || 'family_office', pais: args.pais,
      vehiculos: args.vehiculos ? String(args.vehiculos).split(',') : [],
      ticket_min_usd: args.min ? Number(args.min) : null, ticket_max_usd: args.max ? Number(args.max) : null,
      decisor: args.decisor, contacto_email: args.email, telefono: args.telefono, fuente: args.fuente, notas: args.notas
    });
    console.log('Proveedor creado: ' + p.id + ' · ' + p.nombre);
    break;
  }
  case 'kyc': {
    const p = await c.marcarKyc(args.id, args.estado, args.fecha);
    console.log('KYC ' + p.nombre + ' → ' + p.kyc_estado + ' (' + p.kyc_fecha + ')');
    break;
  }
  case 'oportunidad:crear': {
    const o = await c.crearOportunidad({
      proveedor_id: args.proveedor, nombre: args.nombre, vehiculo: args.vehiculo || 'ktft',
      monto_objetivo_usd: Number(args.monto), emision_id: args.emision || null,
      proximo_paso: args.paso, fecha_proximo_paso: args.fecha, fecha_cierre_esperada: args.cierre, owner: args.owner, notas: args.notas
    });
    console.log('Oportunidad creada: ' + o.id + ' · ' + o.nombre + ' [' + o.etapa + ']');
    break;
  }
  case 'mover': {
    const o = await c.moverEtapa(args.id, args.etapa, {
      motivo: args.motivo, proximoPaso: args.paso, fechaProximoPaso: args.fecha,
      montoComprometidoUsd: args.monto ? Number(args.monto) : undefined
    });
    console.log(o.nombre + ' → ' + o.etapa + ' (prob ' + o.probabilidad_pct + '%)');
    break;
  }
  case 'interaccion': {
    const i = await c.registrarInteraccion({
      proveedor_id: args.proveedor, oportunidad_id: args.oportunidad || null, tipo: args.tipo || 'nota',
      resumen: args.resumen, resultado: args.resultado, siguiente_accion: args.siguiente, creado_por: args.por || 'agente-liquidez'
    });
    console.log('Interacción registrada: ' + i.id);
    break;
  }
  case 'wire': {
    const d = await c.registrarDesembolso({
      oportunidad_id: args.oportunidad, monto_usd: Number(args.monto), moneda: args.moneda || 'USD',
      referencia: args.ref, cuenta_destino: args.cuenta, verificado: !!args.verificado, notas: args.notas
    });
    console.log('Desembolso registrado: ' + d.id + ' · ' + fmtUsd(d.monto_usd) + ' ' + d.moneda + (d.verificado ? ' (verificado)' : ' (pendiente de verificar)'));
    break;
  }
  case 'perdidas': {
    tabla(await c.motivosPerdida(), [{ h: 'motivo', k: 'motivo', w: 50 }, { h: 'casos', k: 'casos', w: 5 }, { h: 'monto', w: 14, f: f => fmtUsd(f.monto_usd) }]);
    break;
  }
  case 'correos': {
    const filas = await c.correosPendientes();
    if (!filas.length) { console.log('Sin correos pendientes. Mové una oportunidad de etapa y la base prepara el siguiente.'); break; }
    tabla(filas, [
      { h: 'estado', k: 'estado', w: 10 }, { h: 'etapa', k: 'etapa', w: 18 }, { h: 'oportunidad', k: 'oportunidad', w: 34 },
      { h: 'para', w: 30, f: f => f.para || '(falta la dirección)' }, { h: 'días', k: 'dias_esperando', w: 5 }, { h: 'id', k: 'id', w: 36 }
    ]);
    console.log('\n  correo:ver --id <id> para leerlo · correo:marcar --id <id> --estado enviado|borrador|omitido [--para ...]');
    break;
  }
  case 'correo:ver': {
    const f = (await c.correosPendientes()).find(x => x.id === args.id);
    if (!f) { console.error('No hay un correo pendiente con ese id.'); process.exitCode = 1; break; }
    console.log('Para: ' + (f.para || '(falta la dirección: correo:marcar --id ' + f.id + ' --estado pendiente --para x@y.com)'));
    console.log('Asunto: ' + f.asunto + '\n\n' + f.cuerpo);
    break;
  }
  case 'correo:marcar': {
    const r = await c.marcarCorreo(args.id, args.estado, {
      para: args.para, gmailDraftId: args.draft, gmailMessageId: args.mensaje, gmailThreadId: args.hilo
    });
    console.log('Correo ' + r.etapa + ' → ' + r.estado + (r.para ? ' · ' + r.para : ''));
    break;
  }
  default:
    console.error('Comando desconocido: ' + cmd + '. Usá `help`.');
    process.exitCode = 1;
  }
}

main().catch(err => {
  console.error('Error: ' + err.message);
  process.exitCode = 1;
});
