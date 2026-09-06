'use strict';

const assert = require('assert');
const crm = require('../src/crm');

function fila(over) {
  return Object.assign({
    id: 'x', nombre: 'Oportunidad', etapa: 'contactado', monto_ponderado_usd: 50000, dias_en_etapa: 1, dias_sin_contacto: 1,
    alerta_sin_proximo_paso: false, alerta_paso_vencido: false, alerta_degradar: false, alerta_kyc: false, fecha_cierre_esperada: null
  }, over);
}

describe('liquidity-agent/crm', function() {
  describe('priorizar', function() {
    it('pone primero los que violan SLA aunque valgan menos', function() {
      const r = crm.priorizar([
        fila({ id: 'grande', monto_ponderado_usd: 1000000 }),
        fila({ id: 'degradar', monto_ponderado_usd: 100000, etapa: 'compromiso_verbal', alerta_degradar: true })
      ]);
      assert.strictEqual(r[0].id, 'degradar');
      assert.ok(r[0].razones[0].indexOf('degradar') >= 0);
    });

    it('excluye perdidas, nurture y wired', function() {
      const r = crm.priorizar([fila({ etapa: 'perdido' }), fila({ etapa: 'nurture' }), fila({ etapa: 'wired' }), fila({ etapa: 'due_diligence' })]);
      assert.strictEqual(r.length, 1);
      assert.strictEqual(r[0].etapa, 'due_diligence');
    });

    it('marca estancados y fríos', function() {
      const r = crm.priorizar([fila({ etapa: 'identificado', dias_en_etapa: 9, dias_sin_contacto: 12 })]);
      assert.strictEqual(r[0].razones.length, 2);
      assert.ok(/estancado/.test(r[0].razones[0]));
      assert.ok(/frío/.test(r[0].razones[1]));
    });

    it('sube el score si el cierre esperado está a menos de 14 días', function() {
      const hoy = '2026-09-04';
      const r = crm.priorizar([fila({ id: 'pronto', fecha_cierre_esperada: '2026-09-10' }), fila({ id: 'lejos', fecha_cierre_esperada: '2026-12-01' })], hoy);
      assert.strictEqual(r[0].id, 'pronto');
      assert.ok(r[0].score > r[1].score);
    });

    it('a igual urgencia gana el mayor monto ponderado', function() {
      const r = crm.priorizar([fila({ id: 'chico', monto_ponderado_usd: 10000 }), fila({ id: 'grande', monto_ponderado_usd: 900000 })]);
      assert.strictEqual(r[0].id, 'grande');
    });
  });

  describe('resumenFunnel', function() {
    const funnel = [
      { etapa: 'identificado', oportunidades: 4, monto_objetivo_usd: 2000000, monto_comprometido_usd: 0, monto_firmado_usd: 0, monto_wired_usd: 0, monto_ponderado_usd: 100000 },
      { etapa: 'contactado', oportunidades: 2, monto_objetivo_usd: 1000000, monto_comprometido_usd: 0, monto_firmado_usd: 0, monto_wired_usd: 0, monto_ponderado_usd: 100000 },
      { etapa: 'primera_reunion', oportunidades: 0, monto_objetivo_usd: 0, monto_comprometido_usd: 0, monto_firmado_usd: 0, monto_wired_usd: 0, monto_ponderado_usd: 0 },
      { etapa: 'segunda_reunion', oportunidades: 0, monto_objetivo_usd: 0, monto_comprometido_usd: 0, monto_firmado_usd: 0, monto_wired_usd: 0, monto_ponderado_usd: 0 },
      { etapa: 'due_diligence', oportunidades: 1, monto_objetivo_usd: 500000, monto_comprometido_usd: 0, monto_firmado_usd: 0, monto_wired_usd: 0, monto_ponderado_usd: 250000 },
      { etapa: 'compromiso_verbal', oportunidades: 1, monto_objetivo_usd: 300000, monto_comprometido_usd: 300000, monto_firmado_usd: 0, monto_wired_usd: 0, monto_ponderado_usd: 210000 },
      { etapa: 'firmado', oportunidades: 1, monto_objetivo_usd: 200000, monto_comprometido_usd: 200000, monto_firmado_usd: 200000, monto_wired_usd: 0, monto_ponderado_usd: 180000 },
      { etapa: 'wired', oportunidades: 2, monto_objetivo_usd: 1500000, monto_comprometido_usd: 1500000, monto_firmado_usd: 1500000, monto_wired_usd: 1500000, monto_ponderado_usd: 1500000 },
      { etapa: 'nurture', oportunidades: 3, monto_objetivo_usd: 0, monto_comprometido_usd: 0, monto_firmado_usd: 0, monto_wired_usd: 0, monto_ponderado_usd: 0 },
      { etapa: 'perdido', oportunidades: 5, monto_objetivo_usd: 0, monto_comprometido_usd: 0, monto_firmado_usd: 0, monto_wired_usd: 0, monto_ponderado_usd: 0 }
    ];

    it('calcula totales y gap a la meta', function() {
      const r = crm.resumenFunnel(funnel, 5000000);
      assert.strictEqual(r.activas, 9);
      assert.strictEqual(r.wired_usd, 1500000);
      assert.strictEqual(r.firmado_usd, 1700000);
      assert.strictEqual(r.comprometido_usd, 2000000);
      assert.strictEqual(r.ponderado_usd, 840000);
      assert.strictEqual(r.perdidas, 5);
      assert.strictEqual(r.nurture, 3);
      assert.strictEqual(r.gap_usd, 3500000);
      assert.strictEqual(r.avance_pct, 30);
    });

    it('calcula conversión acumulada etapa a etapa', function() {
      const r = crm.resumenFunnel(funnel);
      const c = {};
      r.conversion.forEach(x => { c[x.de + '>' + x.a] = x.pct; });
      // alcanzaron al menos: identificado 11, contactado 7, 1ª 5, 2ª 5, DD 5, verbal 4, firmado 3, wired 2
      assert.strictEqual(c['identificado>contactado'], 64);
      assert.strictEqual(c['contactado>primera_reunion'], 71);
      assert.strictEqual(c['firmado>wired'], 67);
      assert.strictEqual(r.meta_usd, null);
      assert.strictEqual(r.gap_usd, null);
    });
  });

  describe('validarEtapa', function() {
    it('acepta etapas válidas y rechaza inválidas', function() {
      assert.strictEqual(crm.validarEtapa('wired'), 'wired');
      assert.throws(() => crm.validarEtapa('cerrado'), /Etapa inválida/);
    });
  });

  describe('renderPlantilla', function() {
    const tpl = { asunto: 'Kabal · {{vehiculo}} — {{proveedor}}', cuerpo: 'Estimado/a {{decisor}}: {{oportunidad}} por {{monto}}. Próximo paso: {{proximo_paso}} ({{fecha_proximo_paso}}).\n{{firma}}' };

    it('rellena los placeholders con oportunidad y proveedor', function() {
      const r = crm.renderPlantilla(tpl,
        { nombre: 'FO Delta · KTFT E1', vehiculo: 'ktft', monto_objetivo_usd: 750000, proximo_paso: 'Enviar whitepaper', fecha_proximo_paso: '2026-09-12' },
        { nombre: 'FO Delta', decisor: 'Ana Pérez', contacto_email: ' ana@delta.test ' }, { firma: 'GK' });
      assert.strictEqual(r.para, 'ana@delta.test');
      assert.strictEqual(r.asunto, 'Kabal · KTFT — FO Delta');
      assert.strictEqual(r.cuerpo, 'Estimado/a Ana Pérez: FO Delta · KTFT E1 por USD 750,000. Próximo paso: Enviar whitepaper (2026-09-12).\nGK');
    });

    it('usa valores por defecto cuando faltan datos y prefiere el monto firmado', function() {
      const r = crm.renderPlantilla(tpl, { nombre: 'X', vehiculo: 'warehouse', monto_objetivo_usd: 100, monto_firmado_usd: 80, moneda: 'USDC' }, { nombre: 'Banco Y' });
      assert.strictEqual(r.para, null);
      assert.ok(r.cuerpo.indexOf('equipo de Banco Y') === 0 || r.cuerpo.indexOf('Estimado/a equipo de Banco Y') === 0);
      assert.ok(r.cuerpo.indexOf('USDC 80') >= 0);
      assert.ok(r.cuerpo.indexOf('definir siguiente paso (por definir)') >= 0);
      assert.ok(r.cuerpo.indexOf('Equipo Kabal') >= 0);
      assert.strictEqual(crm.renderPlantilla({ asunto: '{{desconocido}}' }, {}, {}).asunto, '{{desconocido}}');
    });
  });

  describe('crearCliente', function() {
    it('exige credenciales', function() {
      const url = process.env.SUPABASE_URL, key = process.env.SUPABASE_KEY;
      delete process.env.SUPABASE_URL; delete process.env.SUPABASE_KEY;
      assert.throws(() => crm.crearCliente(), /SUPABASE_URL/);
      if (url) { process.env.SUPABASE_URL = url; }
      if (key) { process.env.SUPABASE_KEY = key; }
    });

    it('arma la llamada RPC de moverEtapa y bloquea etapas inválidas', async function() {
      const llamadas = [];
      const fakeFetch = async (u, opts) => {
        llamadas.push({ u, opts });
        return { ok: true, status: 200, text: async () => JSON.stringify({ id: 'o1', etapa: 'firmado' }) };
      };
      const c = crm.crearCliente({ url: 'https://x.supabase.co/', key: 'k', fetch: fakeFetch });
      const r = await c.moverEtapa('o1', 'firmado', { proximoPaso: 'Wire', fechaProximoPaso: '2026-09-10' });
      assert.strictEqual(r.etapa, 'firmado');
      assert.strictEqual(llamadas[0].u, 'https://x.supabase.co/rest/v1/rpc/liq_mover_etapa');
      const body = JSON.parse(llamadas[0].opts.body);
      assert.strictEqual(body.p_oportunidad_id, 'o1');
      assert.strictEqual(body.p_proximo_paso, 'Wire');
      assert.strictEqual(body.p_monto_comprometido_usd, null);
      assert.strictEqual(llamadas[0].opts.headers.Authorization, 'Bearer k');
      assert.throws(() => c.moverEtapa('o1', 'cerrado'), /Etapa inválida/);
    });

    it('propaga errores de Supabase con el mensaje del servidor', async function() {
      const fakeFetch = async () => ({ ok: false, status: 400, statusText: 'Bad Request',
        text: async () => JSON.stringify({ message: 'LIQ_KYC_REQUERIDO: el proveedor no tiene KYC en verde' }) });
      const c = crm.crearCliente({ url: 'https://x.supabase.co', key: 'k', fetch: fakeFetch });
      await assert.rejects(c.moverEtapa('o1', 'wired'), /LIQ_KYC_REQUERIDO/);
    });
  });
});
