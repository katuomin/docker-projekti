// api osoite (reitittyy proxykontin kautta)
const API_URL = '/api/notes';

// muistiinpanolista
let notes = [];

// sivupalkki muistiinpanoille
function initNotesSidebar() {
    if (document.getElementById('notesSidebar')) return;

    const toggle = document.createElement('button');
    toggle.id = 'sidebarToggle';
    toggle.textContent = 'muistiinpanot';
    toggle.title = 'Vedä muistiinpanosivupalkki auki tai kiinni';
    toggle.onclick = toggleSidebar;
    document.body.prepend(toggle);

    const sidebar = document.createElement('aside');
    sidebar.id = 'notesSidebar';
    sidebar.innerHTML =
        '<h2>Omat muistiinpanot</h2>' +
        '<p class="sidebar-hint">Tämä palkki kommunikoi <strong>notes-api</strong> -kontin kanssa (proxykontin kautta). Lue, lisää ja muokkaa muistiinpanoja.</p>' +
        '<div id="statusMessage" class="error-msg"></div>' +
        '<textarea id="noteInput" placeholder="Kirjoita uusi muistiinpano tähän..."></textarea>' +
        '<button onclick="addNote()">Tallenna muistiinpano</button>' +
        '<h3>Tallennetut muistiinpanot:</h3>' +
        '<ul id="notesList"></ul>';
    document.body.appendChild(sidebar);

    // palautetaan edellisen kerran tallennettu tila localstoragesta
    if (localStorage.getItem('notesSidebarOpen') === 'true') {
        document.body.classList.add('sidebar-open');
    }
}

function toggleSidebar() {
    const open = document.body.classList.toggle('sidebar-open');
    localStorage.setItem('notesSidebarOpen', open ? 'true' : 'false');
}

// api luku
async function fetchNotes() {
    const list = document.getElementById('notesList');
    const statusDiv = document.getElementById('statusMessage');

    try {
        const res = await fetch(API_URL);
        if (!res.ok) throw new Error('Palvelinvirhe');

        notes = await res.json();
        statusDiv.textContent = '';
        list.innerHTML = '';

        if (notes.length === 0) {
            list.innerHTML = '<li>Ei vielä muistiinpanoja. Kirjoita jotain yläpuolelle!</li>';
            return;
        }

        notes.forEach(n => {
            const li = document.createElement('li');
            li.id = 'note-' + n.id;

            const span = document.createElement('span');
            span.className = 'note-content';
            span.textContent = n.content;

            const actions = document.createElement('div');
            actions.className = 'note-actions';

            const editBtn = document.createElement('button');
            editBtn.textContent = 'Muokkaa';
            editBtn.onclick = () => startEdit(n.id);

            const deleteBtn = document.createElement('button');
            deleteBtn.textContent = 'Poista';
            deleteBtn.onclick = () => deleteNote(n.id);

            actions.append(editBtn, deleteBtn);
            li.append(span, actions);
            list.appendChild(li);
        });
    } catch (err) {
        console.error('Virhe haettaessa muistiinpanoja:', err);
        statusDiv.textContent = 'Yhteys API-konttiin epäonnistui. Varmista, että notes-api-kontti pyörii portissa 3000.';
    }
}

// api lisäys
async function addNote() {
    const input = document.getElementById('noteInput');
    const statusDiv = document.getElementById('statusMessage');
    const content = input.value.trim();

    if (!content) return;

    try {
        const res = await fetch(API_URL, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ content: content })
        });

        if (!res.ok) {
            const errorData = await res.json().catch(() => ({}));
            throw new Error(errorData.error || 'Palvelinvirhe statuksella ' + res.status);
        }

        input.value = '';
        statusDiv.textContent = '';
        fetchNotes();
    } catch (err) {
        console.error('Virhe tallennettaessa:', err);
        statusDiv.textContent = 'Virhe tallennettaessa: ' + err.message;
    }
}

// api muokkaus
function startEdit(id) {
    const note = notes.find(n => n.id === id);
    const li = document.getElementById('note-' + id);
    if (!note || !li) return;

    li.innerHTML = '';

    const ta = document.createElement('textarea');
    ta.value = note.content;
    ta.style.height = '100px';

    const actions = document.createElement('div');
    actions.className = 'note-actions';

    const saveBtn = document.createElement('button');
    saveBtn.textContent = 'Tallenna';
    saveBtn.onclick = () => saveEdit(id, ta.value);

    const cancelBtn = document.createElement('button');
    cancelBtn.textContent = 'Peruuta';
    cancelBtn.onclick = () => fetchNotes();

    actions.append(saveBtn, cancelBtn);
    li.append(ta, actions);
}

// api tallennus
async function saveEdit(id, content) {
    content = content.trim();
    if (!content) return;

    const statusDiv = document.getElementById('statusMessage');
    try {
        const res = await fetch(API_URL + '/' + id, {
            method: 'PUT',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ content: content })
        });

        if (!res.ok) {
            const errorData = await res.json().catch(() => ({}));
            throw new Error(errorData.error || 'Palvelinvirhe statuksella ' + res.status);
        }

        statusDiv.textContent = '';
        fetchNotes();
    } catch (err) {
        console.error('Virhe muokattaessa:', err);
        statusDiv.textContent = 'Virhe muokattaessa: ' + err.message;
    }
}

// api poisto
async function deleteNote(id) {
    if (!confirm('Poistetaanko muistiinpano?')) return;

    const statusDiv = document.getElementById('statusMessage');
    try {
        const res = await fetch(API_URL + '/' + id, {
            method: 'DELETE'
        });

        if (!res.ok) {
            const errorData = await res.json().catch(() => ({}));
            throw new Error(errorData.error || 'Palvelinvirhe statuksella ' + res.status);
        }

        statusDiv.textContent = '';
        fetchNotes();
    } catch (err) {
        console.error('Virhe poistettaessa:', err);
        statusDiv.textContent = 'Virhe poistettaessa: ' + err.message;
    }
}

initNotesSidebar();
fetchNotes();
