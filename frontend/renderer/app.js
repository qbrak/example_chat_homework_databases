// Prison Management System - Frontend Application

const API_URL = window.config?.apiUrl || 'http://localhost:8000';

// State management
let currentPage = 'dashboard';
let prisoners = [];
let cells = [];
let cellBlocks = [];
let staff = [];
let staffRoles = [];
let crimeTypes = [];
let programTypes = [];
let visitors = [];
let prisonersPagination = { limit: 20, offset: 0, total: 0 };

// ============================================
// UTILITY FUNCTIONS
// ============================================

async function api(endpoint, options = {}) {
    try {
        const response = await fetch(`${API_URL}${endpoint}`, {
            ...options,
            headers: {
                'Content-Type': 'application/json',
                ...options.headers,
            },
        });

        if (!response.ok) {
            const error = await response.json().catch(() => ({ detail: 'Request failed' }));
            throw new Error(error.detail || 'Request failed');
        }

        return await response.json();
    } catch (error) {
        console.error('API Error:', error);
        throw error;
    }
}

function showToast(message, type = 'info') {
    const container = document.getElementById('toast-container');
    const toast = document.createElement('div');
    toast.className = `toast ${type}`;
    toast.textContent = message;
    container.appendChild(toast);

    setTimeout(() => {
        toast.style.animation = 'slideIn 0.3s ease reverse';
        setTimeout(() => toast.remove(), 300);
    }, 3000);
}

function formatDate(dateString) {
    if (!dateString) return '-';
    return new Date(dateString).toLocaleDateString('pl-PL');
}

function formatDateTime(dateString) {
    if (!dateString) return '-';
    return new Date(dateString).toLocaleString('pl-PL');
}

function translateStatus(status) {
    const translations = {
        'incarcerated': 'Osadzony',
        'released': 'Zwolniony',
        'transferred': 'Przeniesiony',
        'deceased': 'Zmarły',
        'escaped': 'Zbiegł',
        'scheduled': 'Zaplanowana',
        'completed': 'Zakończona',
        'cancelled': 'Anulowana',
        'no_show': 'Nieobecność',
        'enrolled': 'Zapisany',
        'dropped': 'Zrezygnował',
        'expelled': 'Wydalony',
        'minor': 'Drobny',
        'moderate': 'Umiarkowany',
        'major': 'Poważny',
        'critical': 'Krytyczny'
    };
    return translations[status] || status;
}

function translateIncidentType(type) {
    const translations = {
        'fight': 'Bójka',
        'contraband': 'Kontrabanda',
        'escape_attempt': 'Próba ucieczki',
        'assault_staff': 'Napaść na personel',
        'property_damage': 'Zniszczenie mienia',
        'disobedience': 'Nieposłuszeństwo',
        'other': 'Inne'
    };
    return translations[type] || type;
}

// ============================================
// NAVIGATION
// ============================================

document.querySelectorAll('.nav-item').forEach(item => {
    item.addEventListener('click', () => {
        const page = item.dataset.page;
        navigateTo(page);
    });
});

function navigateTo(page) {
    currentPage = page;

    // Update nav
    document.querySelectorAll('.nav-item').forEach(item => {
        item.classList.toggle('active', item.dataset.page === page);
    });

    // Update pages
    document.querySelectorAll('.page').forEach(p => {
        p.classList.toggle('active', p.id === `page-${page}`);
    });

    // Load page data
    loadPageData(page);
}

async function loadPageData(page) {
    try {
        switch (page) {
            case 'dashboard':
                await loadDashboard();
                break;
            case 'prisoners':
                await loadPrisoners();
                break;
            case 'cells':
                await loadCells();
                break;
            case 'staff':
                await loadStaff();
                break;
            case 'visits':
                await loadVisits();
                break;
            case 'programs':
                await loadPrograms();
                break;
            case 'incidents':
                await loadIncidents();
                break;
            case 'reports':
                await loadReport('prisoner-details');
                break;
        }
    } catch (error) {
        showToast('Błąd ładowania danych: ' + error.message, 'error');
    }
}

// ============================================
// DASHBOARD
// ============================================

async function loadDashboard() {
    try {
        const stats = await api('/api/stats');

        document.getElementById('stat-prisoners').textContent = stats.total_prisoners;
        document.getElementById('stat-cells').textContent = stats.total_cells;
        document.getElementById('stat-staff').textContent = stats.active_staff;
        document.getElementById('stat-visits').textContent = stats.scheduled_visits;
        document.getElementById('stat-incidents').textContent = stats.unresolved_incidents;

        // Render prisoners by block chart
        const chartContainer = document.getElementById('prisoners-by-block');
        const maxCount = Math.max(...stats.prisoners_by_block.map(b => b.count), 1);

        chartContainer.innerHTML = stats.prisoners_by_block.map(block => `
            <div class="block-bar">
                <span class="block-name">${block.name}</span>
                <div class="block-bar-fill">
                    <div class="block-bar-value" style="width: ${(block.count / maxCount) * 100}%">
                        ${block.count}
                    </div>
                </div>
            </div>
        `).join('');
    } catch (error) {
        showToast('Błąd ładowania statystyk', 'error');
    }
}

// ============================================
// PRISONERS
// ============================================

async function loadPrisoners() {
    const search = document.getElementById('prisoner-search').value;
    const status = document.getElementById('prisoner-status-filter').value;

    let url = `/api/prisoners?limit=${prisonersPagination.limit}&offset=${prisonersPagination.offset}`;
    if (search) url += `&search=${encodeURIComponent(search)}`;
    if (status) url += `&status=${status}`;

    const result = await api(url);
    prisoners = result.data;
    prisonersPagination.total = result.total;

    renderPrisoners();
    renderPrisonersPagination();
}

function renderPrisoners() {
    const tbody = document.querySelector('#prisoners-table tbody');

    if (prisoners.length === 0) {
        tbody.innerHTML = `<tr><td colspan="7" class="empty-state">Brak więźniów do wyświetlenia</td></tr>`;
        return;
    }

    tbody.innerHTML = prisoners.map(p => `
        <tr>
            <td>${p.prisoner_number}</td>
            <td>${p.first_name} ${p.last_name}</td>
            <td>${formatDate(p.date_of_birth)}</td>
            <td>${p.cell_code || '-'}</td>
            <td>${p.block_name || '-'}</td>
            <td><span class="status-badge ${p.status}">${translateStatus(p.status)}</span></td>
            <td class="action-buttons">
                <button class="btn btn-sm btn-secondary" onclick="viewPrisoner(${p.id})">Szczegóły</button>
                <button class="btn btn-sm btn-secondary" onclick="editPrisoner(${p.id})">Edytuj</button>
                <button class="btn btn-sm btn-danger" onclick="deletePrisoner(${p.id})">Usuń</button>
            </td>
        </tr>
    `).join('');
}

function renderPrisonersPagination() {
    const container = document.getElementById('prisoners-pagination');
    const totalPages = Math.ceil(prisonersPagination.total / prisonersPagination.limit);
    const currentPageNum = Math.floor(prisonersPagination.offset / prisonersPagination.limit) + 1;

    if (totalPages <= 1) {
        container.innerHTML = '';
        return;
    }

    let html = `
        <button ${currentPageNum === 1 ? 'disabled' : ''} onclick="changePrisonersPage(${currentPageNum - 1})">&lt;</button>
    `;

    for (let i = 1; i <= totalPages; i++) {
        if (i === 1 || i === totalPages || (i >= currentPageNum - 2 && i <= currentPageNum + 2)) {
            html += `<button class="${i === currentPageNum ? 'active' : ''}" onclick="changePrisonersPage(${i})">${i}</button>`;
        } else if (i === currentPageNum - 3 || i === currentPageNum + 3) {
            html += `<span>...</span>`;
        }
    }

    html += `<button ${currentPageNum === totalPages ? 'disabled' : ''} onclick="changePrisonersPage(${currentPageNum + 1})">&gt;</button>`;

    container.innerHTML = html;
}

function changePrisonersPage(page) {
    prisonersPagination.offset = (page - 1) * prisonersPagination.limit;
    loadPrisoners();
}

async function showPrisonerForm(prisonerId = null) {
    // Load required data
    if (cells.length === 0) cells = await api('/api/cells?available_only=false');
    if (cellBlocks.length === 0) cellBlocks = await api('/api/cell-blocks');

    let prisoner = null;
    if (prisonerId) {
        prisoner = await api(`/api/prisoners/${prisonerId}`);
    }

    document.getElementById('modal-title').textContent = prisoner ? 'Edytuj więźnia' : 'Dodaj więźnia';

    document.getElementById('modal-body').innerHTML = `
        <form id="prisoner-form" onsubmit="savePrisoner(event, ${prisonerId})">
            <div class="form-row">
                <div class="form-group">
                    <label class="form-label">Numer więźnia *</label>
                    <input type="text" class="form-input" name="prisoner_number" required
                           value="${prisoner?.prisoner_number || ''}"
                           placeholder="np. P2025-0001">
                </div>
                <div class="form-group">
                    <label class="form-label">Status</label>
                    <select class="form-select" name="status">
                        <option value="incarcerated" ${prisoner?.status === 'incarcerated' ? 'selected' : ''}>Osadzony</option>
                        <option value="released" ${prisoner?.status === 'released' ? 'selected' : ''}>Zwolniony</option>
                        <option value="transferred" ${prisoner?.status === 'transferred' ? 'selected' : ''}>Przeniesiony</option>
                    </select>
                </div>
            </div>
            <div class="form-row">
                <div class="form-group">
                    <label class="form-label">Imię *</label>
                    <input type="text" class="form-input" name="first_name" required value="${prisoner?.first_name || ''}">
                </div>
                <div class="form-group">
                    <label class="form-label">Nazwisko *</label>
                    <input type="text" class="form-input" name="last_name" required value="${prisoner?.last_name || ''}">
                </div>
            </div>
            <div class="form-row">
                <div class="form-group">
                    <label class="form-label">Data urodzenia *</label>
                    <input type="date" class="form-input" name="date_of_birth" required
                           value="${prisoner?.date_of_birth || ''}" max="${new Date(Date.now() - 18*365*24*60*60*1000).toISOString().split('T')[0]}">
                </div>
                <div class="form-group">
                    <label class="form-label">Płeć *</label>
                    <select class="form-select" name="gender" required>
                        <option value="male" ${prisoner?.gender === 'male' ? 'selected' : ''}>Mężczyzna</option>
                        <option value="female" ${prisoner?.gender === 'female' ? 'selected' : ''}>Kobieta</option>
                        <option value="other" ${prisoner?.gender === 'other' ? 'selected' : ''}>Inna</option>
                    </select>
                </div>
            </div>
            <div class="form-row">
                <div class="form-group">
                    <label class="form-label">Narodowość *</label>
                    <input type="text" class="form-input" name="nationality" required value="${prisoner?.nationality || 'Polish'}">
                </div>
                <div class="form-group">
                    <label class="form-label">Grupa krwi</label>
                    <select class="form-select" name="blood_type">
                        <option value="">Nieznana</option>
                        <option value="A+" ${prisoner?.blood_type === 'A+' ? 'selected' : ''}>A+</option>
                        <option value="A-" ${prisoner?.blood_type === 'A-' ? 'selected' : ''}>A-</option>
                        <option value="B+" ${prisoner?.blood_type === 'B+' ? 'selected' : ''}>B+</option>
                        <option value="B-" ${prisoner?.blood_type === 'B-' ? 'selected' : ''}>B-</option>
                        <option value="AB+" ${prisoner?.blood_type === 'AB+' ? 'selected' : ''}>AB+</option>
                        <option value="AB-" ${prisoner?.blood_type === 'AB-' ? 'selected' : ''}>AB-</option>
                        <option value="O+" ${prisoner?.blood_type === 'O+' ? 'selected' : ''}>O+</option>
                        <option value="O-" ${prisoner?.blood_type === 'O-' ? 'selected' : ''}>O-</option>
                    </select>
                </div>
            </div>
            <div class="form-row">
                <div class="form-group">
                    <label class="form-label">Cela</label>
                    <select class="form-select" name="cell_id">
                        <option value="">Brak przypisania</option>
                        ${cells.map(c => `
                            <option value="${c.id}" ${prisoner?.cell_id === c.id ? 'selected' : ''}>
                                ${c.cell_code} (${c.block_name}) - ${c.current_occupancy}/${c.capacity}
                            </option>
                        `).join('')}
                    </select>
                </div>
                <div class="form-group">
                    <label class="form-label">Data przyjęcia</label>
                    <input type="date" class="form-input" name="admission_date"
                           value="${prisoner?.admission_date || new Date().toISOString().split('T')[0]}">
                </div>
            </div>
            <div class="form-row">
                <div class="form-group">
                    <label class="form-label">Kontakt alarmowy - imię</label>
                    <input type="text" class="form-input" name="emergency_contact_name"
                           value="${prisoner?.emergency_contact_name || ''}">
                </div>
                <div class="form-group">
                    <label class="form-label">Kontakt alarmowy - telefon</label>
                    <input type="text" class="form-input" name="emergency_contact_phone"
                           value="${prisoner?.emergency_contact_phone || ''}">
                </div>
            </div>
            <div class="form-group">
                <label class="form-label">Notatki</label>
                <textarea class="form-textarea" name="notes">${prisoner?.notes || ''}</textarea>
            </div>
            <div class="form-actions">
                <button type="button" class="btn btn-secondary" onclick="closeModal()">Anuluj</button>
                <button type="submit" class="btn btn-primary">Zapisz</button>
            </div>
        </form>
    `;

    openModal();
}

async function savePrisoner(event, prisonerId) {
    event.preventDefault();
    const form = event.target;
    const formData = new FormData(form);
    const data = Object.fromEntries(formData.entries());

    // Convert empty strings to null for optional fields
    if (data.cell_id === '') data.cell_id = null;
    if (data.blood_type === '') data.blood_type = null;

    try {
        if (prisonerId) {
            await api(`/api/prisoners/${prisonerId}`, {
                method: 'PUT',
                body: JSON.stringify(data)
            });
            showToast('Więzień zaktualizowany', 'success');
        } else {
            await api('/api/prisoners', {
                method: 'POST',
                body: JSON.stringify(data)
            });
            showToast('Więzień dodany', 'success');
        }
        closeModal();
        loadPrisoners();
    } catch (error) {
        showToast('Błąd: ' + error.message, 'error');
    }
}

function editPrisoner(id) {
    showPrisonerForm(id);
}

async function viewPrisoner(id) {
    try {
        const history = await api(`/api/prisoners/${id}/history`);

        document.getElementById('modal-title').textContent = 'Szczegóły więźnia';
        document.getElementById('modal-body').innerHTML = `
            <div class="prisoner-details">
                <h4>${history.prisoner.first_name} ${history.prisoner.last_name}</h4>
                <p><strong>Numer:</strong> ${history.prisoner.prisoner_number}</p>
                <p><strong>Status:</strong> ${translateStatus(history.prisoner.status)}</p>
                <p><strong>Data przyjęcia:</strong> ${formatDate(history.prisoner.admission_date)}</p>

                <h4 style="margin-top: 1rem;">Statystyki</h4>
                <p><strong>Wyroki:</strong> ${history.statistics.total_sentences}</p>
                <p><strong>Incydenty:</strong> ${history.statistics.total_incidents}</p>
                <p><strong>Wizyty:</strong> ${history.statistics.total_visits}</p>
                <p><strong>Ukończone programy:</strong> ${history.statistics.programs_completed}</p>
                <p><strong>Dni w izolatce:</strong> ${history.statistics.total_solitary_days}</p>

                ${history.sentences.length > 0 ? `
                    <h4 style="margin-top: 1rem;">Wyroki</h4>
                    <ul>
                        ${history.sentences.map(s => `
                            <li>${s.crime_type} - ${s.sentence_years} lat ${s.sentence_months > 0 ? s.sentence_months + ' mies.' : ''}
                                (od ${formatDate(s.sentence_start_date)})</li>
                        `).join('')}
                    </ul>
                ` : ''}

                ${history.incidents.length > 0 ? `
                    <h4 style="margin-top: 1rem;">Ostatnie incydenty</h4>
                    <ul>
                        ${history.incidents.slice(0, 5).map(i => `
                            <li>${formatDate(i.incident_date)} - ${translateIncidentType(i.incident_type)} (${translateStatus(i.severity)})</li>
                        `).join('')}
                    </ul>
                ` : ''}
            </div>
            <div class="form-actions">
                <button type="button" class="btn btn-secondary" onclick="closeModal()">Zamknij</button>
            </div>
        `;
        openModal();
    } catch (error) {
        showToast('Błąd ładowania szczegółów', 'error');
    }
}

async function deletePrisoner(id) {
    if (!confirm('Czy na pewno chcesz usunąć tego więźnia? Ta operacja jest nieodwracalna.')) {
        return;
    }

    try {
        await api(`/api/prisoners/${id}`, { method: 'DELETE' });
        showToast('Więzień usunięty', 'success');
        loadPrisoners();
    } catch (error) {
        showToast('Błąd usuwania: ' + error.message, 'error');
    }
}

// Search and filter handlers for prisoners
document.getElementById('prisoner-search')?.addEventListener('input', debounce(() => {
    prisonersPagination.offset = 0;
    loadPrisoners();
}, 300));

document.getElementById('prisoner-status-filter')?.addEventListener('change', () => {
    prisonersPagination.offset = 0;
    loadPrisoners();
});

function debounce(func, wait) {
    let timeout;
    return function executedFunction(...args) {
        const later = () => {
            clearTimeout(timeout);
            func(...args);
        };
        clearTimeout(timeout);
        timeout = setTimeout(later, wait);
    };
}

// ============================================
// CELLS
// ============================================

async function loadCells() {
    const blockId = document.getElementById('cell-block-filter').value;
    let url = '/api/cells';
    if (blockId) url += `?block_id=${blockId}`;

    cells = await api(url);

    // Load cell blocks for filter if not loaded
    if (cellBlocks.length === 0) {
        cellBlocks = await api('/api/cell-blocks');
        const select = document.getElementById('cell-block-filter');
        select.innerHTML = '<option value="">Wszystkie bloki</option>' +
            cellBlocks.map(b => `<option value="${b.id}">${b.name}</option>`).join('');
    }

    renderCells();
}

function renderCells() {
    const tbody = document.querySelector('#cells-table tbody');

    tbody.innerHTML = cells.map(c => `
        <tr>
            <td>${c.cell_code}</td>
            <td>${c.block_name}</td>
            <td>${c.floor_number}</td>
            <td>${c.cell_type}</td>
            <td>${c.capacity}</td>
            <td>
                <span class="status-badge ${c.current_occupancy >= c.capacity ? 'critical' : c.current_occupancy > 0 ? 'moderate' : 'minor'}">
                    ${c.current_occupancy}/${c.capacity}
                </span>
            </td>
            <td>${c.has_window ? 'Tak' : 'Nie'}</td>
            <td class="action-buttons">
                <button class="btn btn-sm btn-secondary" onclick="editCell(${c.id})">Edytuj</button>
                <button class="btn btn-sm btn-danger" onclick="deleteCell(${c.id})">Usuń</button>
            </td>
        </tr>
    `).join('');
}

async function showCellForm(cellId = null) {
    if (cellBlocks.length === 0) cellBlocks = await api('/api/cell-blocks');

    let cell = null;
    if (cellId) {
        cell = await api(`/api/cells/${cellId}`);
    }

    document.getElementById('modal-title').textContent = cell ? 'Edytuj celę' : 'Dodaj celę';

    document.getElementById('modal-body').innerHTML = `
        <form id="cell-form" onsubmit="saveCell(event, ${cellId})">
            <div class="form-row">
                <div class="form-group">
                    <label class="form-label">Kod celi *</label>
                    <input type="text" class="form-input" name="cell_code" required
                           value="${cell?.cell_code || ''}" placeholder="np. A-101">
                </div>
                <div class="form-group">
                    <label class="form-label">Blok *</label>
                    <select class="form-select" name="cell_block_id" required>
                        ${cellBlocks.map(b => `
                            <option value="${b.id}" ${cell?.cell_block_id === b.id ? 'selected' : ''}>${b.name}</option>
                        `).join('')}
                    </select>
                </div>
            </div>
            <div class="form-row">
                <div class="form-group">
                    <label class="form-label">Piętro *</label>
                    <input type="number" class="form-input" name="floor_number" required min="1"
                           value="${cell?.floor_number || 1}">
                </div>
                <div class="form-group">
                    <label class="form-label">Pojemność *</label>
                    <input type="number" class="form-input" name="capacity" required min="1" max="4"
                           value="${cell?.capacity || 1}">
                </div>
            </div>
            <div class="form-row">
                <div class="form-group">
                    <label class="form-label">Typ celi</label>
                    <select class="form-select" name="cell_type">
                        <option value="standard" ${cell?.cell_type === 'standard' ? 'selected' : ''}>Standardowa</option>
                        <option value="solitary" ${cell?.cell_type === 'solitary' ? 'selected' : ''}>Izolatka</option>
                        <option value="medical" ${cell?.cell_type === 'medical' ? 'selected' : ''}>Medyczna</option>
                        <option value="protective" ${cell?.cell_type === 'protective' ? 'selected' : ''}>Ochronna</option>
                    </select>
                </div>
                <div class="form-group">
                    <label class="form-label">Okno</label>
                    <select class="form-select" name="has_window">
                        <option value="true" ${cell?.has_window !== false ? 'selected' : ''}>Tak</option>
                        <option value="false" ${cell?.has_window === false ? 'selected' : ''}>Nie</option>
                    </select>
                </div>
            </div>
            <div class="form-actions">
                <button type="button" class="btn btn-secondary" onclick="closeModal()">Anuluj</button>
                <button type="submit" class="btn btn-primary">Zapisz</button>
            </div>
        </form>
    `;

    openModal();
}

async function saveCell(event, cellId) {
    event.preventDefault();
    const form = event.target;
    const formData = new FormData(form);
    const data = Object.fromEntries(formData.entries());
    data.has_window = data.has_window === 'true';
    data.capacity = parseInt(data.capacity);
    data.floor_number = parseInt(data.floor_number);
    data.cell_block_id = parseInt(data.cell_block_id);

    try {
        if (cellId) {
            await api(`/api/cells/${cellId}`, { method: 'PUT', body: JSON.stringify(data) });
            showToast('Cela zaktualizowana', 'success');
        } else {
            await api('/api/cells', { method: 'POST', body: JSON.stringify(data) });
            showToast('Cela dodana', 'success');
        }
        closeModal();
        loadCells();
    } catch (error) {
        showToast('Błąd: ' + error.message, 'error');
    }
}

function editCell(id) {
    showCellForm(id);
}

async function deleteCell(id) {
    if (!confirm('Czy na pewno chcesz usunąć tę celę?')) return;

    try {
        await api(`/api/cells/${id}`, { method: 'DELETE' });
        showToast('Cela usunięta', 'success');
        loadCells();
    } catch (error) {
        showToast('Błąd: ' + error.message, 'error');
    }
}

document.getElementById('cell-block-filter')?.addEventListener('change', loadCells);

// ============================================
// STAFF
// ============================================

async function loadStaff() {
    const roleId = document.getElementById('staff-role-filter').value;
    let url = '/api/staff';
    if (roleId) url += `?role_id=${roleId}`;

    staff = await api(url);

    if (staffRoles.length === 0) {
        staffRoles = await api('/api/staff-roles');
        const select = document.getElementById('staff-role-filter');
        select.innerHTML = '<option value="">Wszystkie role</option>' +
            staffRoles.map(r => `<option value="${r.id}">${r.name}</option>`).join('');
    }

    renderStaff();
}

function renderStaff() {
    const tbody = document.querySelector('#staff-table tbody');

    tbody.innerHTML = staff.map(s => `
        <tr>
            <td>${s.employee_id}</td>
            <td>${s.first_name} ${s.last_name}</td>
            <td>${s.role_name}</td>
            <td>${s.block_name || '-'}</td>
            <td>${s.email || '-'}</td>
            <td>${s.phone || '-'}</td>
            <td><span class="status-badge ${s.is_active ? 'completed' : 'cancelled'}">${s.is_active ? 'Aktywny' : 'Nieaktywny'}</span></td>
            <td class="action-buttons">
                <button class="btn btn-sm btn-secondary" onclick="editStaff(${s.id})">Edytuj</button>
                <button class="btn btn-sm btn-danger" onclick="deleteStaff(${s.id})">Usuń</button>
            </td>
        </tr>
    `).join('');
}

async function showStaffForm(staffId = null) {
    if (staffRoles.length === 0) staffRoles = await api('/api/staff-roles');
    if (cellBlocks.length === 0) cellBlocks = await api('/api/cell-blocks');

    let staffMember = null;
    if (staffId) {
        staffMember = await api(`/api/staff/${staffId}`);
    }

    document.getElementById('modal-title').textContent = staffMember ? 'Edytuj pracownika' : 'Dodaj pracownika';

    document.getElementById('modal-body').innerHTML = `
        <form id="staff-form" onsubmit="saveStaff(event, ${staffId})">
            <div class="form-row">
                <div class="form-group">
                    <label class="form-label">ID pracownika *</label>
                    <input type="text" class="form-input" name="employee_id" required
                           value="${staffMember?.employee_id || ''}" placeholder="np. EMP016">
                </div>
                <div class="form-group">
                    <label class="form-label">Rola *</label>
                    <select class="form-select" name="role_id" required>
                        ${staffRoles.map(r => `
                            <option value="${r.id}" ${staffMember?.role_id === r.id ? 'selected' : ''}>${r.name}</option>
                        `).join('')}
                    </select>
                </div>
            </div>
            <div class="form-row">
                <div class="form-group">
                    <label class="form-label">Imię *</label>
                    <input type="text" class="form-input" name="first_name" required value="${staffMember?.first_name || ''}">
                </div>
                <div class="form-group">
                    <label class="form-label">Nazwisko *</label>
                    <input type="text" class="form-input" name="last_name" required value="${staffMember?.last_name || ''}">
                </div>
            </div>
            <div class="form-row">
                <div class="form-group">
                    <label class="form-label">Data urodzenia *</label>
                    <input type="date" class="form-input" name="date_of_birth" required value="${staffMember?.date_of_birth || ''}">
                </div>
                <div class="form-group">
                    <label class="form-label">Płeć *</label>
                    <select class="form-select" name="gender" required>
                        <option value="male" ${staffMember?.gender === 'male' ? 'selected' : ''}>Mężczyzna</option>
                        <option value="female" ${staffMember?.gender === 'female' ? 'selected' : ''}>Kobieta</option>
                        <option value="other" ${staffMember?.gender === 'other' ? 'selected' : ''}>Inna</option>
                    </select>
                </div>
            </div>
            <div class="form-row">
                <div class="form-group">
                    <label class="form-label">Email</label>
                    <input type="email" class="form-input" name="email" value="${staffMember?.email || ''}">
                </div>
                <div class="form-group">
                    <label class="form-label">Telefon</label>
                    <input type="text" class="form-input" name="phone" value="${staffMember?.phone || ''}">
                </div>
            </div>
            <div class="form-row">
                <div class="form-group">
                    <label class="form-label">Przypisany blok</label>
                    <select class="form-select" name="assigned_block_id">
                        <option value="">Brak</option>
                        ${cellBlocks.map(b => `
                            <option value="${b.id}" ${staffMember?.assigned_block_id === b.id ? 'selected' : ''}>${b.name}</option>
                        `).join('')}
                    </select>
                </div>
                <div class="form-group">
                    <label class="form-label">Wynagrodzenie</label>
                    <input type="number" class="form-input" name="salary" step="0.01" value="${staffMember?.salary || ''}">
                </div>
            </div>
            <div class="form-group">
                <label class="form-label">Status</label>
                <select class="form-select" name="is_active">
                    <option value="true" ${staffMember?.is_active !== false ? 'selected' : ''}>Aktywny</option>
                    <option value="false" ${staffMember?.is_active === false ? 'selected' : ''}>Nieaktywny</option>
                </select>
            </div>
            <div class="form-actions">
                <button type="button" class="btn btn-secondary" onclick="closeModal()">Anuluj</button>
                <button type="submit" class="btn btn-primary">Zapisz</button>
            </div>
        </form>
    `;

    openModal();
}

async function saveStaff(event, staffId) {
    event.preventDefault();
    const form = event.target;
    const formData = new FormData(form);
    const data = Object.fromEntries(formData.entries());

    data.is_active = data.is_active === 'true';
    data.role_id = parseInt(data.role_id);
    if (data.assigned_block_id === '') data.assigned_block_id = null;
    else data.assigned_block_id = parseInt(data.assigned_block_id);
    if (data.salary === '') data.salary = null;
    else data.salary = parseFloat(data.salary);

    try {
        if (staffId) {
            await api(`/api/staff/${staffId}`, { method: 'PUT', body: JSON.stringify(data) });
            showToast('Pracownik zaktualizowany', 'success');
        } else {
            data.hire_date = new Date().toISOString().split('T')[0];
            await api('/api/staff', { method: 'POST', body: JSON.stringify(data) });
            showToast('Pracownik dodany', 'success');
        }
        closeModal();
        loadStaff();
    } catch (error) {
        showToast('Błąd: ' + error.message, 'error');
    }
}

function editStaff(id) {
    showStaffForm(id);
}

async function deleteStaff(id) {
    if (!confirm('Czy na pewno chcesz usunąć tego pracownika?')) return;

    try {
        await api(`/api/staff/${id}`, { method: 'DELETE' });
        showToast('Pracownik usunięty', 'success');
        loadStaff();
    } catch (error) {
        showToast('Błąd: ' + error.message, 'error');
    }
}

document.getElementById('staff-role-filter')?.addEventListener('change', loadStaff);

// ============================================
// VISITS
// ============================================

async function loadVisits() {
    const status = document.getElementById('visit-status-filter').value;
    let url = '/api/visits?limit=50';
    if (status) url += `&status=${status}`;

    const visits = await api(url);
    renderVisits(visits);
}

function renderVisits(visits) {
    const tbody = document.querySelector('#visits-table tbody');

    tbody.innerHTML = visits.map(v => `
        <tr>
            <td>${formatDate(v.visit_date)}</td>
            <td>${v.scheduled_start_time} - ${v.scheduled_end_time}</td>
            <td>${v.prisoner_first_name} ${v.prisoner_last_name} (${v.prisoner_number})</td>
            <td>${v.visitor_first_name} ${v.visitor_last_name}</td>
            <td>${v.relationship_type}</td>
            <td>${v.visit_type}</td>
            <td><span class="status-badge ${v.status}">${translateStatus(v.status)}</span></td>
            <td class="action-buttons">
                <button class="btn btn-sm btn-secondary" onclick="editVisit(${v.id})">Edytuj</button>
                <button class="btn btn-sm btn-danger" onclick="deleteVisit(${v.id})">Usuń</button>
            </td>
        </tr>
    `).join('');
}

async function showVisitForm(visitId = null) {
    if (prisoners.length === 0) {
        const result = await api('/api/prisoners?status=incarcerated&limit=1000');
        prisoners = result.data;
    }
    if (visitors.length === 0) visitors = await api('/api/visitors?blacklisted=false');
    if (staff.length === 0) staff = await api('/api/staff');

    document.getElementById('modal-title').textContent = visitId ? 'Edytuj wizytę' : 'Zaplanuj wizytę';

    document.getElementById('modal-body').innerHTML = `
        <form id="visit-form" onsubmit="saveVisit(event, ${visitId})">
            <div class="form-row">
                <div class="form-group">
                    <label class="form-label">Więzień *</label>
                    <select class="form-select" name="prisoner_id" required>
                        ${prisoners.map(p => `
                            <option value="${p.id}">${p.prisoner_number} - ${p.first_name} ${p.last_name}</option>
                        `).join('')}
                    </select>
                </div>
                <div class="form-group">
                    <label class="form-label">Odwiedzający *</label>
                    <select class="form-select" name="visitor_id" required>
                        ${visitors.map(v => `
                            <option value="${v.id}">${v.first_name} ${v.last_name} (${v.relationship_type})</option>
                        `).join('')}
                    </select>
                </div>
            </div>
            <div class="form-row">
                <div class="form-group">
                    <label class="form-label">Data wizyty *</label>
                    <input type="date" class="form-input" name="visit_date" required
                           min="${new Date().toISOString().split('T')[0]}">
                </div>
                <div class="form-group">
                    <label class="form-label">Typ wizyty</label>
                    <select class="form-select" name="visit_type">
                        <option value="regular">Zwykła</option>
                        <option value="family">Rodzinna</option>
                        <option value="legal">Prawna</option>
                        <option value="conjugal">Intymna</option>
                    </select>
                </div>
            </div>
            <div class="form-row">
                <div class="form-group">
                    <label class="form-label">Godzina rozpoczęcia *</label>
                    <input type="time" class="form-input" name="scheduled_start_time" required value="10:00">
                </div>
                <div class="form-group">
                    <label class="form-label">Godzina zakończenia *</label>
                    <input type="time" class="form-input" name="scheduled_end_time" required value="11:00">
                </div>
            </div>
            <div class="form-group">
                <label class="form-label">Zatwierdzający</label>
                <select class="form-select" name="approved_by_staff_id">
                    <option value="">Wybierz</option>
                    ${staff.map(s => `
                        <option value="${s.id}">${s.first_name} ${s.last_name} (${s.role_name})</option>
                    `).join('')}
                </select>
            </div>
            <div class="form-group">
                <label class="form-label">Notatki</label>
                <textarea class="form-textarea" name="notes"></textarea>
            </div>
            <div class="form-actions">
                <button type="button" class="btn btn-secondary" onclick="closeModal()">Anuluj</button>
                <button type="submit" class="btn btn-primary">Zapisz</button>
            </div>
        </form>
    `;

    openModal();
}

async function saveVisit(event, visitId) {
    event.preventDefault();
    const form = event.target;
    const formData = new FormData(form);
    const data = Object.fromEntries(formData.entries());

    data.prisoner_id = parseInt(data.prisoner_id);
    data.visitor_id = parseInt(data.visitor_id);
    if (data.approved_by_staff_id === '') data.approved_by_staff_id = null;
    else data.approved_by_staff_id = parseInt(data.approved_by_staff_id);

    try {
        if (visitId) {
            await api(`/api/visits/${visitId}`, { method: 'PUT', body: JSON.stringify(data) });
            showToast('Wizyta zaktualizowana', 'success');
        } else {
            await api('/api/visits', { method: 'POST', body: JSON.stringify(data) });
            showToast('Wizyta zaplanowana', 'success');
        }
        closeModal();
        loadVisits();
    } catch (error) {
        showToast('Błąd: ' + error.message, 'error');
    }
}

function editVisit(id) {
    showVisitForm(id);
}

async function deleteVisit(id) {
    if (!confirm('Czy na pewno chcesz usunąć tę wizytę?')) return;

    try {
        await api(`/api/visits/${id}`, { method: 'DELETE' });
        showToast('Wizyta usunięta', 'success');
        loadVisits();
    } catch (error) {
        showToast('Błąd: ' + error.message, 'error');
    }
}

document.getElementById('visit-status-filter')?.addEventListener('change', loadVisits);

// ============================================
// PROGRAMS
// ============================================

async function loadPrograms() {
    const programs = await api('/api/programs');
    const enrollments = await api('/api/prisoner-programs');

    renderPrograms(programs);
    renderEnrollments(enrollments);
}

function renderPrograms(programs) {
    const grid = document.getElementById('programs-grid');

    grid.innerHTML = programs.map(p => `
        <div class="program-card">
            <h4>${p.name}</h4>
            <div class="program-type">${p.type_name}</div>
            <div class="program-info">
                <span>Czas trwania: ${p.duration_weeks} tygodni</span>
                <span>Zapisanych: ${p.current_enrolled}/${p.max_participants}</span>
                ${p.instructor_first_name ? `<span>Instruktor: ${p.instructor_first_name} ${p.instructor_last_name}</span>` : ''}
            </div>
        </div>
    `).join('');
}

function renderEnrollments(enrollments) {
    const tbody = document.querySelector('#enrollments-table tbody');

    tbody.innerHTML = enrollments.map(e => `
        <tr>
            <td>${e.first_name} ${e.last_name} (${e.prisoner_number})</td>
            <td>${e.program_name}</td>
            <td>${e.program_type}</td>
            <td>${formatDate(e.enrollment_date)}</td>
            <td><span class="status-badge ${e.status}">${translateStatus(e.status)}</span></td>
            <td>${e.grade || '-'}</td>
            <td class="action-buttons">
                <button class="btn btn-sm btn-secondary" onclick="editEnrollment(${e.id})">Edytuj</button>
            </td>
        </tr>
    `).join('');
}

async function showProgramForm() {
    if (programTypes.length === 0) programTypes = await api('/api/program-types');
    if (staff.length === 0) staff = await api('/api/staff');

    document.getElementById('modal-title').textContent = 'Dodaj program';

    document.getElementById('modal-body').innerHTML = `
        <form id="program-form" onsubmit="saveProgram(event)">
            <div class="form-group">
                <label class="form-label">Nazwa *</label>
                <input type="text" class="form-input" name="name" required>
            </div>
            <div class="form-row">
                <div class="form-group">
                    <label class="form-label">Typ *</label>
                    <select class="form-select" name="program_type_id" required>
                        ${programTypes.map(t => `<option value="${t.id}">${t.name}</option>`).join('')}
                    </select>
                </div>
                <div class="form-group">
                    <label class="form-label">Czas trwania (tygodnie) *</label>
                    <input type="number" class="form-input" name="duration_weeks" required min="1">
                </div>
            </div>
            <div class="form-row">
                <div class="form-group">
                    <label class="form-label">Maks. uczestników *</label>
                    <input type="number" class="form-input" name="max_participants" required min="1">
                </div>
                <div class="form-group">
                    <label class="form-label">Instruktor</label>
                    <select class="form-select" name="instructor_staff_id">
                        <option value="">Brak</option>
                        ${staff.map(s => `<option value="${s.id}">${s.first_name} ${s.last_name}</option>`).join('')}
                    </select>
                </div>
            </div>
            <div class="form-group">
                <label class="form-label">Opis</label>
                <textarea class="form-textarea" name="description"></textarea>
            </div>
            <div class="form-actions">
                <button type="button" class="btn btn-secondary" onclick="closeModal()">Anuluj</button>
                <button type="submit" class="btn btn-primary">Zapisz</button>
            </div>
        </form>
    `;

    openModal();
}

async function saveProgram(event) {
    event.preventDefault();
    const form = event.target;
    const formData = new FormData(form);
    const data = Object.fromEntries(formData.entries());

    data.program_type_id = parseInt(data.program_type_id);
    data.duration_weeks = parseInt(data.duration_weeks);
    data.max_participants = parseInt(data.max_participants);
    if (data.instructor_staff_id === '') data.instructor_staff_id = null;
    else data.instructor_staff_id = parseInt(data.instructor_staff_id);

    try {
        await api('/api/programs', { method: 'POST', body: JSON.stringify(data) });
        showToast('Program dodany', 'success');
        closeModal();
        loadPrograms();
    } catch (error) {
        showToast('Błąd: ' + error.message, 'error');
    }
}

async function editEnrollment(id) {
    document.getElementById('modal-title').textContent = 'Edytuj zapis';

    document.getElementById('modal-body').innerHTML = `
        <form id="enrollment-form" onsubmit="saveEnrollment(event, ${id})">
            <div class="form-row">
                <div class="form-group">
                    <label class="form-label">Status</label>
                    <select class="form-select" name="status">
                        <option value="enrolled">Zapisany</option>
                        <option value="completed">Ukończony</option>
                        <option value="dropped">Zrezygnował</option>
                        <option value="expelled">Wydalony</option>
                    </select>
                </div>
                <div class="form-group">
                    <label class="form-label">Ocena</label>
                    <select class="form-select" name="grade">
                        <option value="">Brak</option>
                        <option value="A">A</option>
                        <option value="B">B</option>
                        <option value="C">C</option>
                        <option value="D">D</option>
                        <option value="F">F</option>
                    </select>
                </div>
            </div>
            <div class="form-group">
                <label class="form-label">Data ukończenia</label>
                <input type="date" class="form-input" name="completion_date">
            </div>
            <div class="form-group">
                <label class="form-label">Notatki</label>
                <textarea class="form-textarea" name="notes"></textarea>
            </div>
            <div class="form-actions">
                <button type="button" class="btn btn-secondary" onclick="closeModal()">Anuluj</button>
                <button type="submit" class="btn btn-primary">Zapisz</button>
            </div>
        </form>
    `;

    openModal();
}

async function saveEnrollment(event, id) {
    event.preventDefault();
    const form = event.target;
    const formData = new FormData(form);
    const data = Object.fromEntries(formData.entries());

    if (data.grade === '') data.grade = null;
    if (data.completion_date === '') data.completion_date = null;

    try {
        await api(`/api/prisoner-programs/${id}`, { method: 'PUT', body: JSON.stringify(data) });
        showToast('Zapis zaktualizowany', 'success');
        closeModal();
        loadPrograms();
    } catch (error) {
        showToast('Błąd: ' + error.message, 'error');
    }
}

// ============================================
// INCIDENTS
// ============================================

async function loadIncidents() {
    const severity = document.getElementById('incident-severity-filter').value;
    const resolved = document.getElementById('incident-resolved-filter').value;

    let url = '/api/incidents?limit=50';
    if (severity) url += `&severity=${severity}`;
    if (resolved !== '') url += `&resolved=${resolved}`;

    const incidents = await api(url);
    renderIncidents(incidents);
}

function renderIncidents(incidents) {
    const tbody = document.querySelector('#incidents-table tbody');

    tbody.innerHTML = incidents.map(i => `
        <tr>
            <td>${formatDateTime(i.incident_date)}</td>
            <td>${i.first_name} ${i.last_name} (${i.prisoner_number})</td>
            <td>${translateIncidentType(i.incident_type)}</td>
            <td><span class="status-badge ${i.severity}">${translateStatus(i.severity)}</span></td>
            <td>${i.location || '-'}</td>
            <td>${i.reporter_first_name ? `${i.reporter_first_name} ${i.reporter_last_name}` : '-'}</td>
            <td><span class="status-badge ${i.is_resolved ? 'resolved' : 'unresolved'}">${i.is_resolved ? 'Rozwiązany' : 'Nierozwiązany'}</span></td>
            <td class="action-buttons">
                <button class="btn btn-sm btn-secondary" onclick="editIncident(${i.id})">Edytuj</button>
                <button class="btn btn-sm btn-danger" onclick="deleteIncident(${i.id})">Usuń</button>
            </td>
        </tr>
    `).join('');
}

async function showIncidentForm(incidentId = null) {
    if (prisoners.length === 0) {
        const result = await api('/api/prisoners?status=incarcerated&limit=1000');
        prisoners = result.data;
    }
    if (staff.length === 0) staff = await api('/api/staff');

    document.getElementById('modal-title').textContent = incidentId ? 'Edytuj incydent' : 'Zgłoś incydent';

    document.getElementById('modal-body').innerHTML = `
        <form id="incident-form" onsubmit="saveIncident(event, ${incidentId})">
            <div class="form-row">
                <div class="form-group">
                    <label class="form-label">Więzień *</label>
                    <select class="form-select" name="prisoner_id" required>
                        ${prisoners.map(p => `
                            <option value="${p.id}">${p.prisoner_number} - ${p.first_name} ${p.last_name}</option>
                        `).join('')}
                    </select>
                </div>
                <div class="form-group">
                    <label class="form-label">Zgłaszający</label>
                    <select class="form-select" name="reported_by_staff_id">
                        <option value="">Wybierz</option>
                        ${staff.map(s => `
                            <option value="${s.id}">${s.first_name} ${s.last_name}</option>
                        `).join('')}
                    </select>
                </div>
            </div>
            <div class="form-row">
                <div class="form-group">
                    <label class="form-label">Typ incydentu *</label>
                    <select class="form-select" name="incident_type" required>
                        <option value="fight">Bójka</option>
                        <option value="contraband">Kontrabanda</option>
                        <option value="escape_attempt">Próba ucieczki</option>
                        <option value="assault_staff">Napaść na personel</option>
                        <option value="property_damage">Zniszczenie mienia</option>
                        <option value="disobedience">Nieposłuszeństwo</option>
                        <option value="other">Inne</option>
                    </select>
                </div>
                <div class="form-group">
                    <label class="form-label">Poziom *</label>
                    <select class="form-select" name="severity" required>
                        <option value="minor">Drobny</option>
                        <option value="moderate">Umiarkowany</option>
                        <option value="major">Poważny</option>
                        <option value="critical">Krytyczny</option>
                    </select>
                </div>
            </div>
            <div class="form-row">
                <div class="form-group">
                    <label class="form-label">Data i godzina</label>
                    <input type="datetime-local" class="form-input" name="incident_date"
                           value="${new Date().toISOString().slice(0, 16)}">
                </div>
                <div class="form-group">
                    <label class="form-label">Lokalizacja</label>
                    <input type="text" class="form-input" name="location">
                </div>
            </div>
            <div class="form-group">
                <label class="form-label">Opis *</label>
                <textarea class="form-textarea" name="description" required></textarea>
            </div>
            <div class="form-row">
                <div class="form-group">
                    <label class="form-label">Podjęte działania</label>
                    <textarea class="form-textarea" name="action_taken"></textarea>
                </div>
                <div class="form-group">
                    <label class="form-label">Dni w izolatce</label>
                    <input type="number" class="form-input" name="solitary_days" min="0" value="0">
                </div>
            </div>
            <div class="form-actions">
                <button type="button" class="btn btn-secondary" onclick="closeModal()">Anuluj</button>
                <button type="submit" class="btn btn-primary">Zapisz</button>
            </div>
        </form>
    `;

    openModal();
}

async function saveIncident(event, incidentId) {
    event.preventDefault();
    const form = event.target;
    const formData = new FormData(form);
    const data = Object.fromEntries(formData.entries());

    data.prisoner_id = parseInt(data.prisoner_id);
    if (data.reported_by_staff_id === '') data.reported_by_staff_id = null;
    else data.reported_by_staff_id = parseInt(data.reported_by_staff_id);
    data.solitary_days = parseInt(data.solitary_days) || 0;

    try {
        if (incidentId) {
            await api(`/api/incidents/${incidentId}`, { method: 'PUT', body: JSON.stringify(data) });
            showToast('Incydent zaktualizowany', 'success');
        } else {
            await api('/api/incidents', { method: 'POST', body: JSON.stringify(data) });
            showToast('Incydent zgłoszony', 'success');
        }
        closeModal();
        loadIncidents();
    } catch (error) {
        showToast('Błąd: ' + error.message, 'error');
    }
}

function editIncident(id) {
    showIncidentForm(id);
}

async function deleteIncident(id) {
    if (!confirm('Czy na pewno chcesz usunąć ten incydent?')) return;

    try {
        await api(`/api/incidents/${id}`, { method: 'DELETE' });
        showToast('Incydent usunięty', 'success');
        loadIncidents();
    } catch (error) {
        showToast('Błąd: ' + error.message, 'error');
    }
}

document.getElementById('incident-severity-filter')?.addEventListener('change', loadIncidents);
document.getElementById('incident-resolved-filter')?.addEventListener('change', loadIncidents);

// ============================================
// REPORTS
// ============================================

document.querySelectorAll('.report-tab').forEach(tab => {
    tab.addEventListener('click', () => {
        const report = tab.dataset.report;

        document.querySelectorAll('.report-tab').forEach(t => t.classList.remove('active'));
        tab.classList.add('active');

        document.querySelectorAll('.report-view').forEach(v => v.classList.remove('active'));
        document.getElementById(`report-${report}`).classList.add('active');

        loadReport(report);
    });
});

async function loadReport(reportName) {
    const endpoints = {
        'prisoner-details': '/api/views/prisoner-details',
        'cell-occupancy': '/api/views/cell-occupancy',
        'upcoming-releases': '/api/views/upcoming-releases',
        'block-summary': '/api/views/block-summary',
        'staff-overview': '/api/views/staff-overview'
    };

    try {
        const data = await api(endpoints[reportName]);
        renderReportTable(reportName, data);
    } catch (error) {
        showToast('Błąd ładowania raportu', 'error');
    }
}

function renderReportTable(reportName, data) {
    const table = document.getElementById(`report-${reportName}-table`);

    if (data.length === 0) {
        table.innerHTML = '<tr><td>Brak danych do wyświetlenia</td></tr>';
        return;
    }

    // Get column names from first row
    const columns = Object.keys(data[0]);

    // Build header
    table.querySelector('thead').innerHTML = `
        <tr>
            ${columns.map(col => `<th>${formatColumnName(col)}</th>`).join('')}
        </tr>
    `;

    // Build body
    table.querySelector('tbody').innerHTML = data.map(row => `
        <tr>
            ${columns.map(col => `<td>${formatCellValue(row[col])}</td>`).join('')}
        </tr>
    `).join('');
}

function formatColumnName(name) {
    const translations = {
        'prisoner_id': 'ID więźnia',
        'prisoner_number': 'Nr więźnia',
        'first_name': 'Imię',
        'last_name': 'Nazwisko',
        'full_name': 'Imię i nazwisko',
        'date_of_birth': 'Data urodzenia',
        'age': 'Wiek',
        'gender': 'Płeć',
        'nationality': 'Narodowość',
        'status': 'Status',
        'admission_date': 'Data przyjęcia',
        'cell_code': 'Cela',
        'cell_type': 'Typ celi',
        'block_name': 'Blok',
        'security_level': 'Poziom bezpieczeństwa',
        'crime': 'Przestępstwo',
        'sentence_years': 'Lata wyroku',
        'expected_release_date': 'Przewidywana data zwolnienia',
        'total_incidents': 'Incydenty',
        'total_visits': 'Wizyty',
        'completed_programs': 'Ukończone programy',
        'current_occupancy': 'Aktualna zajętość',
        'cell_capacity': 'Pojemność',
        'available_spots': 'Wolne miejsca',
        'occupancy_percentage': '% zajętości',
        'cell_status': 'Status celi',
        'block_id': 'ID bloku',
        'total_cells': 'Liczba cel',
        'total_bed_capacity': 'Całkowita pojemność',
        'current_prisoners': 'Aktualni więźniowie',
        'occupancy_rate': 'Wskaźnik zajętości',
        'assigned_guards': 'Przypisani strażnicy',
        'incidents_last_30_days': 'Incydenty (30 dni)',
        'staff_id': 'ID pracownika',
        'employee_id': 'Nr pracownika',
        'role': 'Rola',
        'access_level': 'Poziom dostępu',
        'hire_date': 'Data zatrudnienia',
        'years_employed': 'Lata pracy',
        'is_active': 'Aktywny',
        'assigned_block': 'Przypisany blok',
        'release_date': 'Data zwolnienia',
        'days_until_release': 'Dni do zwolnienia',
        'incident_count': 'Liczba incydentów',
        'programs_completed': 'Ukończone programy',
        'parole_eligible': 'Możliwość warunkowego'
    };
    return translations[name] || name.replace(/_/g, ' ');
}

function formatCellValue(value) {
    if (value === null || value === undefined) return '-';
    if (typeof value === 'boolean') return value ? 'Tak' : 'Nie';
    if (typeof value === 'string' && value.match(/^\d{4}-\d{2}-\d{2}/)) {
        return formatDate(value);
    }
    if (typeof value === 'object') return JSON.stringify(value);
    return value;
}

// ============================================
// MODAL
// ============================================

function openModal() {
    document.getElementById('modal').classList.add('active');
}

function closeModal() {
    document.getElementById('modal').classList.remove('active');
}

// Close modal on outside click
document.getElementById('modal')?.addEventListener('click', (e) => {
    if (e.target.id === 'modal') {
        closeModal();
    }
});

// Close modal on Escape key
document.addEventListener('keydown', (e) => {
    if (e.key === 'Escape') {
        closeModal();
    }
});

// ============================================
// INITIALIZATION
// ============================================

document.addEventListener('DOMContentLoaded', () => {
    loadDashboard();
});
