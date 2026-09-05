'use strict';

/**
 * Kabal · Agente de Liquidez — cliente del CRM.
 *
 * Habla con Supabase (PostgREST) sin dependencias: solo `fetch` de Node >= 18.
 * Toda la lógica de negocio dura vive en la base (triggers/vistas); este módulo
 * la expone como funciones limpias para el agente, el CLI y los tests.
 *
 * Config por variables de entorno:
 *   SUPABASE_URL   https://<ref>.supabase.co
 *   SUPABASE_KEY   service_role (agente en servidor) o JWT de un usuario autenticado
 */

const ETAPAS = [
  'identificado',
  'contactado',
  'primera_reunion',
  'segunda_reunion',
  'due_diligence',
  'compromiso_verbal',
  'firmado',
  'wired',
  'nurture',
  'perdido'
];

const ETAPAS_ACTIVAS = ETAPAS.slice(0, 8);

const VEHICULOS = ['ktft', 'emision_b2b', 'linea_credito', 'warehouse', 'deuda_privada'];

const TIPOS_PROVEEDOR = [
  'family_office', 'fondo', 'gestor_activos', 'hnwi', 'banco', 'banca_inversion', 'fintech_lender',
  'tesoreria_corporativa', 'dao_defi', 'market_maker', 'custodio', 'exchange', 'plataforma_tokenizacion',
  'infraestructura', 'aseguradora', 'soberano', 'multilateral', 'corporativo', 'otro'
];

const SLA = {
  DIAS_DEGRADAR_VERBAL: 14,   // regla H: compromiso verbal > 2 semanas sin firma
  DIAS_SIN_CONTACTO_FRIO: 10, // sin interacción registrada ⇒ "está frío"
  DIAS_MAX_EN_ETAPA: {        // más de esto en una etapa temprana ⇒ estancado
    identificado: 7,
    contactado: 10,
    primera_reunion: 14,
    segunda_reunion: 14,
    due_diligence: 30,
    compromiso_verbal: 14,
    firmado: 21
  }
};

// ---------------------------------------------------------------------------
// Lógica pura (testeable sin base de datos)
// ---------------------------------------------------------------------------

/**
 * Prioriza el pipeline: urgencia (alertas SLA) × valor (monto ponderado) × cercanía al cierre.
 * Recibe filas de la vista liq_v_pipeline y devuelve la misma lista ordenada con `score` y `razones`.
 */
function priorizar(filas, hoy) {
  const ref = hoy ? new Date(hoy) : new Date();
  return filas
    .filter(f => ETAPAS_ACTIVAS.includes(f.etapa) && f.etapa !== 'wired')
    .map(f => {
      const razones = [];
      let urgencia = 0;
      if (f.alerta_degradar) { urgencia += 40; razones.push('compromiso verbal >14 días sin firma: proponer degradar'); }
      if (f.alerta_kyc) { urgencia += 35; razones.push('KYC no está en verde y la etapa ya lo exige'); }
      if (f.alerta_paso_vencido) { urgencia += 30; razones.push('próximo paso vencido'); }
      if (f.alerta_sin_proximo_paso) { urgencia += 25; razones.push('sin próximo paso con fecha'); }
      const maxDias = SLA.DIAS_MAX_EN_ETAPA[f.etapa];
      if (maxDias && Number(f.dias_en_etapa) > maxDias) {
        urgencia += 15; razones.push('estancado: ' + f.dias_en_etapa + ' días en ' + f.etapa);
      }
      if (Number(f.dias_sin_contacto) > SLA.DIAS_SIN_CONTACTO_FRIO) {
        urgencia += 10; razones.push('frío: ' + f.dias_sin_contacto + ' días sin contacto');
      }
      const ponderado = Number(f.monto_ponderado_usd) || 0;
      const valor = Math.log10(ponderado + 1) * 10; // 100K ⇒ 50, 1M ⇒ 60
      let cierre = 0;
      if (f.fecha_cierre_esperada) {
        const dias = (new Date(f.fecha_cierre_esperada) - ref) / 86400000;
        if (dias <= 14) { cierre = 15; }
        else if (dias <= 30) { cierre = 8; }
      }
      const score = Math.round(urgencia + valor + cierre);
      return Object.assign({}, f, { score, razones });
    })
    .sort((a, b) => b.score - a.score || Number(b.monto_ponderado_usd) - Number(a.monto_ponderado_usd));
}

/**
 * Resumen ejecutivo del funnel a partir de liq_v_funnel: totales, conversión etapa a etapa y gap a la meta.
 */
function resumenFunnel(filasFunnel, metaUsd) {
  const porEtapa = {};
  filasFunnel.forEach(f => { porEtapa[f.etapa] = f; });
  const n = e => (porEtapa[e] ? Number(porEtapa[e].oportunidades) : 0);
  const usd = (e, col) => (porEtapa[e] ? Number(porEtapa[e][col]) : 0);

  // "Alcanzó al menos" cada etapa = suma de esa etapa y las posteriores del camino feliz.
  const camino = ETAPAS_ACTIVAS;
  const acumulado = camino.map((e, i) => camino.slice(i).reduce((s, x) => s + n(x), 0));
  const conversion = camino.slice(1).map((e, i) => ({
    de: camino[i],
    a: e,
    pct: acumulado[i] ? Math.round((acumulado[i + 1] / acumulado[i]) * 100) : null
  }));

  const wired = camino.reduce((s, e) => s + usd(e, 'monto_wired_usd'), 0);
  const firmado = usd('firmado', 'monto_firmado_usd') + usd('wired', 'monto_firmado_usd');
  const comprometido = usd('compromiso_verbal', 'monto_comprometido_usd') + firmado;
  const ponderado = camino.filter(e => e !== 'wired').reduce((s, e) => s + usd(e, 'monto_ponderado_usd'), 0);
  const activas = camino.filter(e => e !== 'wired').reduce((s, e) => s + n(e), 0);

  return {
    activas,
    wired_usd: wired,
    firmado_usd: firmado,
    comprometido_usd: comprometido,
    ponderado_usd: Math.round(ponderado),
    perdidas: n('perdido'),
    nurture: n('nurture'),
    conversion,
    meta_usd: metaUsd || null,
    gap_usd: metaUsd ? Math.max(0, metaUsd - wired) : null,
    avance_pct: metaUsd ? Math.round((wired / metaUsd) * 100) : null
  };
}

function validarEtapa(etapa) {
  if (!ETAPAS.includes(etapa)) {
    throw new Error('Etapa inválida: ' + etapa + '. Válidas: ' + ETAPAS.join(', '));
  }
  return etapa;
}

// ---------------------------------------------------------------------------
// Cliente PostgREST
// ---------------------------------------------------------------------------

// ---------------------------------------------------------------------------
// Correos por etapa: la base deja en liq_correos el correo de cada cambio de
// etapa (plantilla de liq_plantillas_correo). Esta función renderiza una
// plantilla con los mismos placeholders que liq_render_correo, para borradores
// locales o previsualización sin base.
// ---------------------------------------------------------------------------

const VEHICULO_LABEL = {
  ktft: 'KTFT', emision_b2b: 'emisión B2B', linea_credito: 'línea de crédito', warehouse: 'warehouse', deuda_privada: 'deuda privada'
};

function renderPlantilla(plantilla, oportunidad, proveedor, extra) {
  plantilla = plantilla || {};
  oportunidad = oportunidad || {};
  proveedor = proveedor || {};
  extra = extra || {};
  const monto = Number(oportunidad.monto_firmado_usd) || Number(oportunidad.monto_comprometido_usd) || Number(oportunidad.monto_objetivo_usd) || 0;
  const ctx = {
    decisor: (proveedor.decisor || '').trim() || ('equipo de ' + (proveedor.nombre || '')),
    proveedor: proveedor.nombre || '',
    oportunidad: oportunidad.nombre || '',
    vehiculo: VEHICULO_LABEL[oportunidad.vehiculo] || oportunidad.vehiculo || '',
    monto: (oportunidad.moneda || 'USD') + ' ' + Math.round(monto).toLocaleString('en-US'),
    proximo_paso: (oportunidad.proximo_paso || '').trim() || 'definir siguiente paso',
    fecha_proximo_paso: oportunidad.fecha_proximo_paso || 'por definir',
    firma: extra.firma || 'Equipo Kabal'
  };
  const fill = s => String(s || '').replace(/\{\{(\w+)\}\}/g, (m, k) => (k in ctx ? ctx[k] : m));
  return {
    para: (proveedor.contacto_email || '').trim() || null,
    asunto: fill(plantilla.asunto),
    cuerpo: fill(plantilla.cuerpo)
  };
}

function crearCliente(opts) {
  opts = opts || {};
  const url = (opts.url || process.env.SUPABASE_URL || '').replace(/\/$/, '');
  const key = opts.key || process.env.SUPABASE_KEY || process.env.SUPABASE_SERVICE_ROLE_KEY;
  const fetchImpl = opts.fetch || globalThis.fetch;
  if (!url || !key) {
    throw new Error('Faltan SUPABASE_URL y SUPABASE_KEY');
  }
  if (typeof fetchImpl !== 'function') {
    throw new Error('fetch no disponible: usá Node >= 18');
  }

  async function rest(method, path, body, extraHeaders) {
    const headers = Object.assign({
      apikey: key,
      Authorization: 'Bearer ' + key,
      'Content-Type': 'application/json',
      Prefer: 'return=representation'
    }, extraHeaders || {});
    const res = await fetchImpl(url + '/rest/v1/' + path, {
      method,
      headers,
      body: body === undefined ? undefined : JSON.stringify(body)
    });
    const text = await res.text();
    let data = null;
    if (text) {
      try { data = JSON.parse(text); } catch (e) { data = text; }
    }
    if (!res.ok) {
      const msg = (data && (data.message || data.hint || data.details)) || text || res.statusText;
      const err = new Error('Supabase ' + res.status + ': ' + msg);
      err.status = res.status;
      err.body = data;
      throw err;
    }
    return data;
  }

  const q = obj => Object.keys(obj).map(k => k + '=' + encodeURIComponent(obj[k])).join('&');

  return {
    // --- Proveedores -------------------------------------------------------
    crearProveedor: p => rest('POST', 'liq_proveedores', p).then(r => r[0]),
    actualizarProveedor: (id, cambios) => rest('PATCH', 'liq_proveedores?' + q({ id: 'eq.' + id }), cambios).then(r => r[0]),
    listarProveedores: filtro => rest('GET', 'liq_v_proveedor_resumen?' + q(Object.assign({ order: 'pipeline_usd.desc' }, filtro || {}))),
    buscarProveedor: nombre => rest('GET', 'liq_proveedores?' + q({ nombre: 'ilike.*' + nombre + '*', limit: 10 })),
    marcarKyc: (id, estado, fecha) => rest('PATCH', 'liq_proveedores?' + q({ id: 'eq.' + id }), {
      kyc_estado: estado, kyc_fecha: fecha || new Date().toISOString().slice(0, 10)
    }).then(r => r[0]),

    // --- Oportunidades (funnel) ------------------------------------------
    crearOportunidad: o => rest('POST', 'liq_oportunidades', o).then(r => r[0]),
    actualizarOportunidad: (id, cambios) => rest('PATCH', 'liq_oportunidades?' + q({ id: 'eq.' + id }), cambios).then(r => r[0]),
    moverEtapa: (id, etapa, extra) => {
      validarEtapa(etapa);
      extra = extra || {};
      return rest('POST', 'rpc/liq_mover_etapa', {
        p_oportunidad_id: id,
        p_etapa: etapa,
        p_motivo: extra.motivo || null,
        p_proximo_paso: extra.proximoPaso || null,
        p_fecha_proximo_paso: extra.fechaProximoPaso || null,
        p_monto_comprometido_usd: extra.montoComprometidoUsd === undefined ? null : extra.montoComprometidoUsd
      });
    },
    pipeline: filtro => rest('GET', 'liq_v_pipeline?' + q(Object.assign({ order: 'monto_ponderado_usd.desc' }, filtro || {}))),
    funnel: () => rest('GET', 'liq_v_funnel?order=orden.asc'),
    resumenVehiculo: () => rest('GET', 'liq_v_resumen_vehiculo'),
    motivosPerdida: () => rest('GET', 'liq_v_motivos_perdida'),
    historial: oportunidadId => rest('GET', 'liq_etapa_historial?' + q({ oportunidad_id: 'eq.' + oportunidadId, order: 'cambiado_en.asc' })),

    // --- Interacciones y wires ------------------------------------------
    registrarInteraccion: i => rest('POST', 'liq_interacciones', i).then(r => r[0]),
    interacciones: proveedorId => rest('GET', 'liq_interacciones?' + q({ proveedor_id: 'eq.' + proveedorId, order: 'fecha.desc', limit: 50 })),
    registrarDesembolso: d => rest('POST', 'liq_desembolsos', d).then(r => r[0]),
    verificarDesembolso: id => rest('PATCH', 'liq_desembolsos?' + q({ id: 'eq.' + id }), { verificado: true }).then(r => r[0]),

    // --- Correos por etapa (cola liq_correos, la llena el trigger) -------
    correosPendientes: () => rest('GET', 'liq_v_correos_pendientes?order=creado_en.desc'),
    plantillasCorreo: () => rest('GET', 'liq_plantillas_correo?order=etapa.asc'),
    marcarCorreo: (id, estado, datos) => {
      datos = datos || {};
      return rest('POST', 'rpc/liq_correo_marcar', {
        p_id: id,
        p_estado: estado,
        p_para: datos.para || null,
        p_gmail_draft_id: datos.gmailDraftId || null,
        p_gmail_message_id: datos.gmailMessageId || null,
        p_gmail_thread_id: datos.gmailThreadId || null,
        p_asunto: datos.asunto || null,
        p_cuerpo: datos.cuerpo || null,
        p_error: datos.error || null
      });
    },

    // --- Reportes compuestos --------------------------------------------
    async lunesDeLiquidez(metaUsd) {
      const [funnel, pipe, vehiculos] = await Promise.all([this.funnel(), this.pipeline(), this.resumenVehiculo()]);
      const priorizado = priorizar(pipe);
      return {
        resumen: resumenFunnel(funnel, metaUsd),
        por_vehiculo: vehiculos,
        top3: priorizado.slice(0, 3),
        alertas: priorizado.filter(f => f.razones.length > 0),
        funnel
      };
    }
  };
}

module.exports = {
  ETAPAS,
  ETAPAS_ACTIVAS,
  VEHICULOS,
  TIPOS_PROVEEDOR,
  SLA,
  priorizar,
  resumenFunnel,
  validarEtapa,
  renderPlantilla,
  crearCliente
};
