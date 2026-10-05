'use strict';
const ENDPOINT = 'http://localhost:11434/v1/systemone';
const el = id => document.getElementById(id);
let config;
let lastResponse;
function status(message, error = false) { el('status').textContent = message; el('status').classList.toggle('error', error); }
function render(data) {
  el('results').replaceChildren();
  const threshold = Number(el('threshold').value);
  for (const [key, question] of Object.entries(config.questions)) {
    const answer = data.answers?.[key];
    if (answer?.type !== 'noul' || typeof answer.noul !== 'number' || !Number.isFinite(answer.noul) || answer.noul < 0 || answer.noul > 1) throw new Error(`Respuesta inválida para ${key}. Se esperaba type=noul y un valor entre 0 y 1.`);
    const card = document.createElement('article'); card.className = 'card';
    const title = document.createElement('h3'); title.textContent = config.labels[key] || key;
    const value = document.createElement('div'); value.className = `value ${answer.noul < threshold ? 'no' : ''}`;
    value.textContent = `${answer.noul >= threshold ? 'Sí' : 'No'} · ${(answer.noul * 100).toFixed(1)} %`;
    const bar = document.createElement('progress'); bar.max = 1; bar.value = answer.noul; bar.setAttribute('aria-label', title.textContent);
    const detail = document.createElement('p'); detail.textContent = question.instructions;
    card.append(title, value, bar, detail); el('results').append(card);
  }
}
async function run() {
  const ticket = el('ticket').value.trim(); const model = el('model').value.trim();
  const threshold = Number(el('threshold').value);
  if (!ticket || !model || el('threshold').value === '' || !Number.isFinite(threshold) || threshold < 0 || threshold > 1) return status('Introduce un ticket, un modelo y un umbral entre 0 y 1.', true);
  const payload = { model, state: ticket, questions: config.questions, keep_alive: '30m' };
  if (new TextEncoder().encode(JSON.stringify(payload)).length > 65536) return status('El ticket y las preguntas superan el límite de 64 KiB. Reduce el texto.', true);
  el('run').disabled = true; el('download').disabled = true; lastResponse = undefined;
  for (const id of ['ticket', 'model', 'threshold', 'reset']) el(id).disabled = true;
  el('results').replaceChildren(); el('raw').textContent = 'Esperando respuesta…';
  const controller = new AbortController(); const timer = setTimeout(() => controller.abort(), 300000); const start = performance.now();
  status('Analizando… Si el modelo estaba descargado de memoria, esta petición incluye su carga inicial.');
  try {
    const response = await fetch(ENDPOINT, { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify(payload), signal: controller.signal });
    const text = await response.text(); let data;
    try { data = JSON.parse(text); } catch { throw new Error(`HTTP ${response.status}: el servidor no devolvió JSON.`); }
    if (!response.ok) throw new Error(`HTTP ${response.status}: ${data.error || text}`);
    render(data); lastResponse = data; el('raw').textContent = JSON.stringify(data, null, 2); el('download').disabled = false;
    status(`Completado en ${((performance.now() - start) / 1000).toFixed(2)} s. Vuelve a analizar para comparar con el modelo caliente.`);
  } catch (error) {
    el('results').replaceChildren(); el('raw').textContent = 'No hay una respuesta válida.';
    status(error.name === 'AbortError' ? 'Tiempo agotado (5 minutos). Revisa la consola de Ollama antes de reintentar.' : error instanceof TypeError ? 'No se pudo conectar. Arranca Start-Ollama.ps1, comprueba el puerto 11434 y el permiso de acceso local del navegador. Si cambiaste el origen, reinicia el launcher.' : error.message, true);
  } finally {
    clearTimeout(timer); el('run').disabled = false;
    for (const id of ['ticket', 'model', 'threshold', 'reset']) el(id).disabled = false;
  }
}
el('run').disabled = true;
el('run').addEventListener('click', run);
el('reset').addEventListener('click', () => { if (config) el('ticket').value = config.ticket; });
el('threshold').addEventListener('change', () => { if (lastResponse && el('threshold').value !== '' && Number(el('threshold').value) >= 0 && Number(el('threshold').value) <= 1) render(lastResponse); });
el('download').addEventListener('click', () => {
  if (!lastResponse) return;
  const url = URL.createObjectURL(new Blob([JSON.stringify(lastResponse, null, 2)], { type: 'application/json' }));
  const link = document.createElement('a'); link.href = url; link.download = 'nimble-decisions.json'; link.click(); setTimeout(() => URL.revokeObjectURL(url), 1000);
});
fetch('decisions.json').then(response => { if (!response.ok) throw new Error('No se pudo leer decisions.json.'); return response.json(); }).then(data => {
  config = data; el('ticket').value = config.ticket; el('run').disabled = false;
}).catch(error => status(`${error.message} Abre la demo mediante Start-Demo.ps1, no haciendo doble clic en el HTML.`, true));
