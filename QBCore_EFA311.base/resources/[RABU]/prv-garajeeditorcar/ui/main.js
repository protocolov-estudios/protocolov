const app = document.getElementById('app')
const vehId = document.getElementById('vehId')
const owner = document.getElementById('owner')
const model = document.getElementById('model')
const plateOld = document.getElementById('plate_old')
const plate = document.getElementById('plate')
const garage = document.getElementById('garage')
const closeBtn = document.getElementById('closeBtn')
const identifier = document.getElementById('identifier')
const saveBtn = document.getElementById('saveBtn')
const cancelBtn = document.getElementById('cancelBtn')
const panelList = document.getElementById('panel-list')
const panelEditor = document.getElementById('panel-editor')
const garagesList = document.getElementById('garagesList')
const closeList = document.getElementById('closeList')
const closeList2 = document.getElementById('closeList2')

let currentVehicle = null

function open(data) {
	if (!data) return
	// reset identifier field by default
	identifier.value = ''
	// show editor panel and hide others
	document.querySelectorAll('.panel').forEach(p => p.style.display = 'none')
	panelEditor.style.display = 'block'
	currentVehicle = data
	vehId.innerText = data.id || ''
	owner.innerText = data.citizenid || ''
	model.innerText = data.vehicle || ''
	plateOld.innerText = data.plate || ''

	plate.value = ''
	garage.value = data.garage || ''

	// if prefill mode, set identifier/garage accordingly
	if (data.mode === 'prefill') {
		// show editor panel and set identifier if present
		identifier.value = data.identifier || ''
		garage.value = data.garage || ''
	}

	app.classList.remove('hidden')
}

function close() {
	app.classList.add('hidden')
	currentVehicle = null
	fetch(`https://${GetParentResourceName()}/close`, { method: 'POST' })
}

closeBtn.addEventListener('click', close)
cancelBtn.addEventListener('click', close)

saveBtn.addEventListener('click', () => {
	// if opened in prefill mode currentVehicle may be an object with mode or be null
	const id = currentVehicle && currentVehicle.id ? currentVehicle.id : (identifier.value || '')
	const currentPlate = currentVehicle && currentVehicle.plate ? currentVehicle.plate : ''
	const payload = {
		id: id,
		plate: currentPlate,
		newPlate: plate.value,
		garage: garage.value
	}
	fetch(`https://${GetParentResourceName()}/save`, { method: 'POST', body: JSON.stringify(payload) })
	close()
})

closeList.addEventListener('click', close)
closeList2.addEventListener('click', close)

function openList(names) {
	// ensure UI is visible (openList previously didn't remove the hidden class)
	app.classList.remove('hidden')
	// hide editor panel and show list panel
	document.querySelectorAll('.panel').forEach(p => p.style.display = 'none')
	panelList.style.display = 'block'
	garagesList.innerHTML = ''
	names.forEach(item => {
		const row = document.createElement('div')
		row.className = 'row'
		// item can be string or object { name, label }
		let name = item
		let label = item
		if (typeof item === 'object' && item !== null) {
			name = item.name || ''
			label = item.label || item.name || ''
		}

			row.innerHTML = `<div style="flex:1"><strong>${label}</strong><div style="opacity:0.8;font-size:12px;margin-top:4px">(${name})</div></div><div style="display:flex;gap:6px;align-items:center"><button class="btn small" data-name="${name}" data-action="copy">Copiar</button><button class="btn small" data-name="${name}" data-action="use">Usar</button></div>`
		garagesList.appendChild(row)
	})

	// attach action handlers (copy/use)
	garagesList.querySelectorAll('button[data-name]').forEach(b => {
		b.addEventListener('click', (e) => {
			const name = e.currentTarget.dataset.name
			const action = e.currentTarget.dataset.action
			if (action === 'copy') {
				try { navigator.clipboard.writeText(name) } catch (err) {
					const ta = document.createElement('textarea')
					ta.value = name
					document.body.appendChild(ta)
					ta.select()
					document.execCommand('copy')
					document.body.removeChild(ta)
				}
				// notify client and close list
				fetch(`https://${GetParentResourceName()}/copied`, { method: 'POST', body: JSON.stringify({ name }) })
				fetch(`https://${GetParentResourceName()}/close`, { method: 'POST' })
			} else if (action === 'use') {
				// call client to open editor with prefilled garage
				panelList.style.display = 'none'
				fetch(`https://${GetParentResourceName()}/useInEditor`, { method: 'POST', body: JSON.stringify({ name }) })
			}
		})
	})
}

window.addEventListener('message', (event) => {
	const d = event.data
	if (!d) return
	console.log('[rabu_garajeeditorcar] NUI message received', d)
	if (d.action === 'open') {
		open(d.data)
	} else if (d.action === 'listGarages') {
		openList(d.data || [])
	}
})

console.log('[rabu_garajeeditorcar] ui/main.js loaded')

// NUI endpoint callbacks from client scripts
// this resource sends POST requests to https://<resource>/close and /save already
// implement a simple handler for /copied so the NUI can keep things tidy
window.addEventListener('message', () => {})
