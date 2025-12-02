const APP = document.getElementById('app');
const BAR = document.getElementById('bar');
const PERCENT = document.getElementById('percent');
const TITLE = document.getElementById('title');
const SUBTITLE = document.getElementById('subtitle');

let current = 0;
let isFakeProgressRunning = false;

function setProgress(p) {
  if (typeof p === 'number') {
    current = Math.max(0, Math.min(100, Math.floor(p)));
  }
  BAR.style.width = current + '%';
  PERCENT.textContent = current + '%';
}

const sleep = (ms) => new Promise(resolve => setTimeout(resolve, ms));

async function startFakeProgress() {
  if (isFakeProgressRunning) return;
  isFakeProgressRunning = true;
  console.log('[loadingprotocolov] Starting realistic fake progress animation.');

  let progress = current;

  // Etapa 1: 0 -> 30%
  while (progress < 30) {
    if (!isFakeProgressRunning) return; // Detener si se cancela
    progress += Math.random() * 2 + 1;
    if (progress > 30) progress = 30;
    setProgress(progress);
    await sleep(100);
  }

  await sleep(1000); // Pausa de 1 segundo

  // Etapa 2: 30 -> 70%
  while (progress < 70) {
    if (!isFakeProgressRunning) return;
    progress += Math.random() * 1.5 + 0.5;
    if (progress > 70) progress = 70;
    setProgress(progress);
    await sleep(150);
  }

  await sleep(1500); // Pausa de 1.5 segundos

  // Etapa 3: 70 -> 90%
  while (progress < 90) {
    if (!isFakeProgressRunning) return;
    progress += Math.random() * 1 + 0.2;
    if (progress > 90) progress = 90;
    setProgress(progress);
    await sleep(250);
  }

  await sleep(2000); // Pausa de 2 segundos

  // Etapa 4: 90 -> 100%
  while (progress < 100) {
    if (!isFakeProgressRunning) return;
    progress += Math.random() * 0.8 + 0.3;
    if (progress > 100) progress = 100;
    setProgress(progress);
    await sleep(200);
  }

  console.log('[loadingprotocolov] Fake progress animation completed at 100%');
}

async function closeLoadingScreen() {
  console.log('[loadingprotocolov] Starting fade-out animation');
  isFakeProgressRunning = false;
  setProgress(100);

  // Esperar un momento para que se vea el 100%
  await sleep(800);

  // Agregar clase de fade-out
  APP.classList.add('fade-out');

  // Esperar a que termine la animación
  await sleep(1000);

  // Ocultar completamente
  APP.classList.add('hidden');
  console.log('[loadingprotocolov] Loading screen hidden');
}

window.addEventListener('message', (ev) => {
  const d = ev.data;
  if (!d) return;

  // Si recibimos progreso real, lo usamos y cancelamos el falso
  if (d.type === 'loadprogress') {
    isFakeProgressRunning = false; // Cancelar animación falsa
    const progress = d.loadFraction * 100;
    setProgress(progress);
    return;
  }

  // Eventos desde nuestro Lua
  switch (d.action) {
    case 'show':
      APP.classList.remove('hidden');
      TITLE.textContent = d.title ?? TITLE.textContent;
      SUBTITLE.textContent = d.subtitle ?? SUBTITLE.textContent;
      setProgress(typeof d.progress === 'number' ? d.progress : 0);
      break;
    case 'hide':
      APP.classList.add('hidden');
      document.body.classList.add('loaded');
      break;
    case 'complete':
      closeLoadingScreen();
      break;
  }
});

// Iniciar la animación falsa por defecto
window.addEventListener('DOMContentLoaded', startFakeProgress);

// Atajo de teclado para desarrollo
window.addEventListener('keydown', (e) => {
  if (e.key === 'Escape') {
    setProgress(100);
  }
});
