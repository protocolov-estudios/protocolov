const hudContainer = document.getElementById('hud-container');

const healthBar = document.getElementById('health-bar');
const armorBar = document.getElementById('armor-bar');
const hungerBar = document.getElementById('hunger-bar');
const thirstBar = document.getElementById('thirst-bar');

const streetContainer = document.getElementById('street-container');
const streetNameElement = document.getElementById('street-name');

// Escuchar mensajes desde el cliente
window.addEventListener('message', function (event) {
    const data = event.data;

    if (data.action === 'updateHUD') {
        updateStat(healthBar, data.health);
        updateStat(armorBar, data.armor);
        updateStat(hungerBar, data.hunger);
        updateStat(thirstBar, data.thirst);
    } else if (data.action === 'show') {
        if (data.display) {
            hudContainer.classList.add('visible');
        } else {
            hudContainer.classList.remove('visible');
        }
    } else if (data.action === 'updateStreet') {
        if (data.inVehicle) {
            streetContainer.classList.add('visible');
            streetNameElement.textContent = data.street;
        } else {
            streetContainer.classList.remove('visible');
        }
    }
});

// Función para actualizar una estadística
function updateStat(barElement, value) {
    // Asegurar que el valor esté entre 0 y 100
    value = Math.max(0, Math.min(100, value));

    // Actualizar la barra
    const currentWidth = parseFloat(barElement.style.width) || 0;
    const newWidth = value;

    if (Math.abs(currentWidth - newWidth) > 0.5) {
        barElement.classList.add('pulse');
        setTimeout(() => barElement.classList.remove('pulse'), 300);
    }

    barElement.style.width = newWidth + '%';
}

// Inicializar el HUD con valores por defecto
window.addEventListener('load', function () {
    updateStat(healthBar, 100);
    updateStat(armorBar, 0);
    updateStat(hungerBar, 100);
    updateStat(thirstBar, 100);
});
