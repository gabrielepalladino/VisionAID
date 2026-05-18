<?php
// pages/dispositivi.php
require_once '../app/auth/auth.php';
checkAuth();

$db   = getDB();
$user = currentUser();

$success = '';
$error   = '';

// Filtri
$f_device_id  = $_GET['device_id']  ?? '';
$f_user_id    = $_GET['user_id']    ?? '';
$f_firmware   = $_GET['firmware']   ?? '';
$f_data_da    = $_GET['data_da']    ?? '';
$f_data_a     = $_GET['data_a']     ?? '';
$f_aperti     = $_GET['aperti']     ?? '';

$where  = ['1=1'];
$having = [];
$params = [];

if ($f_device_id) {
    $where[] = 'd.internal_device_id LIKE ?';
    $params[] = "%$f_device_id%";
}
if ($f_user_id) {
    $where[] = 'd.user_id LIKE ?';
    $params[] = "%$f_user_id%";
}
if ($f_firmware) {
    $where[] = 'd.firmware_version LIKE ?';
    $params[] = "%$f_firmware%";
}
if ($f_data_da) {
    $where[] = 'd.linked_at >= ?';
    $params[] = $f_data_da . ' 00:00:00';
}
if ($f_data_a) {
    $where[] = 'd.linked_at <= ?';
    $params[] = $f_data_a . ' 23:59:59';
}
if ($f_aperti === '1') {
    $having[] = 'ticket_aperti > 0';
}

$having_sql = $having ? 'HAVING ' . implode(' AND ', $having) : '';

$sql = "
    SELECT
        d.internal_device_id,
        d.firmware_version,
        d.linked_at,
        u.user_id,
        u.email             AS utente_email,
        u.os,
        u.device_model,
        u.app_version,
        COUNT(t.ticket_id)                                        AS n_ticket,
        SUM(CASE WHEN t.status = 'open'   THEN 1 ELSE 0 END)     AS ticket_aperti,
        SUM(CASE WHEN t.status = 'closed' THEN 1 ELSE 0 END)     AS ticket_chiusi,
        MAX(t.created_at)                                         AS ultimo_ticket
    FROM devices d
    LEFT JOIN users u ON d.user_id = u.user_id
    LEFT JOIN support_tickets t ON t.user_id = d.user_id
    WHERE " . implode(' AND ', $where) . "
    GROUP BY d.internal_device_id, d.firmware_version, d.linked_at,
             u.user_id, u.email, u.os, u.device_model, u.app_version
    $having_sql
    ORDER BY d.linked_at DESC
";

$stmt = $db->prepare($sql);
$stmt->execute($params);
$dispositivi = $stmt->fetchAll(PDO::FETCH_ASSOC);

$filtri_attivi = $f_device_id || $f_user_id || $f_firmware || $f_data_da || $f_data_a || $f_aperti;
?>
<!DOCTYPE html>
<html lang="it">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Dispositivi — Gestionale</title>
    <link rel="stylesheet" href="../styles/dashboard.css">
    <link rel="stylesheet" href="../styles/sidebar.css"/>
    <style>
        /* ── Filtri ── */
        .filters-grid {
            display: grid;
            grid-template-columns: 1fr 1fr;
            gap: 12px;
            margin-bottom: 16px;
        }
        .filter-group {
            display: flex;
            flex-direction: column;
            gap: 6px;
        }
        .filter-group label {
            font-size: 11px;
            font-weight: 600;
            text-transform: uppercase;
            letter-spacing: .6px;
            color: var(--muted);
        }
        .filter-group input {
            width: 100%;
            height: 38px;
            padding: 0 12px;
            border-radius: 8px;
            border: 1px solid var(--border);
            background: var(--surface2);
            color: var(--text);
            font-size: 13px;
            box-sizing: border-box;
            transition: border-color .2s, background .2s;
        }
        .filter-group input:focus {
            outline: none;
            border-color: var(--accent2);
        }
        .filter-group input::placeholder {
            color: var(--muted);
        }
        .date-range {
            display: flex;
            align-items: center;
            gap: 8px;
        }
        .date-range input { flex: 1; }
        .date-range span {
            font-size: 12px;
            color: var(--muted);
            flex-shrink: 0;
        }
        input[type="date"] { color-scheme: light; }
        [data-theme="dark"] input[type="date"] { color-scheme: dark; }
        .filters-row {
            display: flex;
            gap: 8px;
            align-items: center;
            margin-top: 4px;
        }
        .filter-active-tag {
            display: inline-flex;
            align-items: center;
            gap: 4px;
            background: var(--accent-g);
            color: #fff;
            font-size: 11px;
            font-weight: 600;
            padding: 3px 10px;
            border-radius: 20px;
        }

        /* ── Custom select ── */
        .custom-select {
            position: relative;
            width: 100%;
        }
        .custom-select-trigger {
            height: 38px;
            padding: 0 36px 0 12px;
            border-radius: 8px;
            border: 1px solid var(--border);
            font-size: 13px;
            cursor: pointer;
            display: flex;
            align-items: center;
            justify-content: space-between;
            transition: border-color .2s, background .2s;
            user-select: none;
            background: #ffffff;
            color: #18181b;
        }
        [data-theme="dark"] .custom-select-trigger {
            background: #1C1C21;
            color: var(--text);
            border-color: var(--border);
        }
        .custom-select-trigger:hover,
        .custom-select.open .custom-select-trigger {
            border-color: var(--accent2);
        }
        .custom-select-trigger .arrow {
            font-size: 12px;
            color: var(--muted);
            transition: transform .2s;
            flex-shrink: 0;
        }
        .custom-select.open .custom-select-trigger .arrow {
            transform: rotate(180deg);
        }
        .custom-select-dropdown {
            display: none;
            position: absolute;
            top: calc(100% + 4px);
            left: 0;
            right: 0;
            border: 1px solid var(--border);
            border-radius: 8px;
            overflow: hidden;
            z-index: 200;
            background: #ffffff;
            box-shadow: 0 8px 24px rgba(0,0,0,.12);
        }
        [data-theme="dark"] .custom-select-dropdown {
            background: #1C1C21;
            box-shadow: 0 8px 24px rgba(0,0,0,.35);
        }
        .custom-select.open .custom-select-dropdown { display: block; }
        .custom-select-option {
            padding: 10px 14px;
            font-size: 13px;
            cursor: pointer;
            display: flex;
            align-items: center;
            gap: 8px;
            transition: background .15s;
            color: #18181b;
        }
        [data-theme="dark"] .custom-select-option { color: var(--text); }
        .custom-select-option:hover { background: #f4f4f5; }
        [data-theme="dark"] .custom-select-option:hover { background: #37373d; }
        .custom-select-option.selected {
            color: var(--accent2);
            font-weight: 600;
        }
        .custom-select-option.selected::after {
            content: '✓';
            margin-left: auto;
            font-size: 12px;
        }

        /* ── Status indicator ── */
        .device-status {
            display: inline-flex;
            align-items: center;
            gap: 6px;
            font-size: 12px;
            font-weight: 600;
            padding: 3px 10px;
            border-radius: 20px;
        }
        .device-status.danger {
            background: rgba(220,38,38,.1);
            color: var(--danger, #dc2626);
        }
        .device-status .dot {
            width: 6px; height: 6px;
            border-radius: 50%;
            background: currentColor;
            flex-shrink: 0;
        }

        /* ── Modal ── */
        .modal-overlay {
            display: none;
            position: fixed;
            inset: 0;
            background: rgba(0,0,0,0.55);
            z-index: 300;
            align-items: center;
            justify-content: center;
            backdrop-filter: blur(4px);
        }
        .modal-overlay.open { display: flex; }
        .modal {
            background: var(--surface);
            border: 1px solid var(--border);
            border-radius: 16px;
            padding: 28px;
            width: 600px;
            max-width: 95vw;
            max-height: 88vh;
            overflow-y: auto;
            animation: fadeUp .2s ease;
        }
        @keyframes fadeUp {
            from { opacity:0; transform:translateY(12px); }
            to   { opacity:1; transform:translateY(0); }
        }
        .modal-title { font-size: 17px; font-weight: 700; margin-bottom: 4px; }
        .modal-sub { font-size: 12px; color: var(--muted); font-family: monospace; margin-bottom: 20px; }
        .meta-row {
            display: flex;
            justify-content: space-between;
            align-items: flex-start;
            padding: 9px 0;
            border-bottom: 1px solid var(--border);
            font-size: 13px;
            gap: 12px;
        }
        .meta-row:last-child { border-bottom: none; }
        .meta-label { color: var(--muted); white-space: nowrap; }
        .meta-value { text-align: right; word-break: break-all; }
        .stat-row {
            display: grid;
            grid-template-columns: repeat(3, 1fr);
            gap: 10px;
            margin-bottom: 20px;
        }
        .stat-box {
            background: var(--surface2);
            border-radius: 10px;
            padding: 12px;
            text-align: center;
        }
        .stat-box .stat-val { font-size: 22px; font-weight: 700; line-height: 1; }
        .stat-box .stat-lbl {
            font-size: 11px;
            color: var(--muted);
            margin-top: 4px;
            text-transform: uppercase;
            letter-spacing: .5px;
        }
        .section-label {
            font-size: 11px;
            font-weight: 600;
            text-transform: uppercase;
            letter-spacing: .6px;
            color: var(--muted);
            margin-bottom: 8px;
        }
        .ticket-row {
            display: flex;
            align-items: center;
            justify-content: space-between;
            padding: 10px 0;
            border-bottom: 1px solid var(--border);
            gap: 12px;
            font-size: 13px;
        }
        .ticket-row:last-child { border-bottom: none; }
        .ticket-row a { color: var(--text); text-decoration: none; font-weight: 500; }
        .ticket-row a:hover { color: var(--accent2); }
        .device-id-cell {
            font-family: monospace;
            font-size: 12px;
            background: var(--surface2);
            padding: 2px 8px;
            border-radius: 5px;
            white-space: nowrap;
        }
    </style>
</head>
<body>
<div class="app-layout">
    <?php require_once '../app/partials/sidebar.php'; ?>

    <main class="main-content">
        <div class="page-header">
            <div>
                <h1 class="page-title">Dispositivi</h1>
                <p class="page-sub"><?= count($dispositivi) ?> dispositivi trovati</p>
            </div>
        </div>

        <?php if ($success): ?>
            <div class="alert alert-success"><?= htmlspecialchars($success) ?></div>
        <?php endif; ?>
        <?php if ($error): ?>
            <div class="alert alert-error"><?= htmlspecialchars($error) ?></div>
        <?php endif; ?>

        <!-- Filtri -->
        <div class="card" style="margin-bottom:16px;padding:20px 25px">
            <form method="GET">
                <div class="filters-grid">

                    <div class="filter-group">
                        <label>ID Dispositivo</label>
                        <input type="text" name="device_id"
                               placeholder="Cerca per ID dispositivo..."
                               value="<?= htmlspecialchars($f_device_id) ?>">
                    </div>

                    <div class="filter-group">
                        <label>ID Utente</label>
                        <input type="text" name="user_id"
                               placeholder="UUID utente..."
                               value="<?= htmlspecialchars($f_user_id) ?>">
                    </div>

                    <div class="filter-group">
                        <label>Versione firmware</label>
                        <input type="text" name="firmware"
                               placeholder="es. 1.0.3..."
                               value="<?= htmlspecialchars($f_firmware) ?>">
                    </div>

                    <div class="filter-group">
                        <label>Ticket aperti</label>
                        <input type="hidden" name="aperti" id="aperti-value" value="<?= htmlspecialchars($f_aperti) ?>">
                        <div class="custom-select" id="aperti-select">
                            <div class="custom-select-trigger" onclick="toggleSelect('aperti-select')">
                                <span id="aperti-label">
                                    <?= $f_aperti === '1' ? 'Solo con ticket aperti' : 'Tutti' ?>
                                </span>
                                <span class="arrow">▾</span>
                            </div>
                            <div class="custom-select-dropdown">
                                <div class="custom-select-option <?= $f_aperti === '' ? 'selected' : '' ?>"
                                     onclick="selectOption('aperti-select','aperti-value','aperti-label','','Tutti')">
                                    Tutti
                                </div>
                                <div class="custom-select-option <?= $f_aperti === '1' ? 'selected' : '' ?>"
                                     onclick="selectOption('aperti-select','aperti-value','aperti-label','1','Solo con ticket aperti')">
                                    Solo con ticket aperti
                                </div>
                            </div>
                        </div>
                    </div>

                    <div class="filter-group" style="grid-column: span 2">
                        <label>Data collegamento</label>
                        <div class="date-range">
                            <input type="date" name="data_da" value="<?= htmlspecialchars($f_data_da) ?>">
                            <span>→</span>
                            <input type="date" name="data_a"  value="<?= htmlspecialchars($f_data_a) ?>">
                        </div>
                    </div>

                </div>

                <div class="filters-row">
                    <button type="submit" class="btn btn-primary btn-sm">Filtra</button>
                    <?php if ($filtri_attivi): ?>
                        <a href="devices.php" class="btn btn-secondary btn-sm" style="color:var(--danger)">✕ Reset filtri</a>
                    <?php endif; ?>
                </div>
            </form>
        </div>

        <!-- Tabella -->
        <div class="card">
            <div class="table-wrap">
                <table>
                    <thead>
                        <tr>
                            <th>ID Dispositivo</th>
                            <th>Modello</th>
                            <th>OS</th>
                            <th>Firmware</th>
                            <th>Proprietario</th>
                            <th>Collegato il</th>
                            <th>Ticket</th>
                            <th>Aperti</th>
                            <th>Stato</th>
                            <th></th>
                        </tr>
                    </thead>
                    <tbody>
                    <?php if (empty($dispositivi)): ?>
                        <tr>
                            <td colspan="10">
                                <div class="empty-state">
                                    <h3>Nessun dispositivo trovato</h3>
                                </div>
                            </td>
                        </tr>
                    <?php else: ?>
                        <?php
                        $os_labels = ['android' => 'Android', 'ios' => 'iOS', 'other' => 'Altro'];
                        foreach ($dispositivi as $dev):
                        ?>
                        <tr>
                            <td>
                                <span class="device-id-cell"><?= htmlspecialchars($dev['internal_device_id']) ?></span>
                            </td>
                            <td class="text-sm"><?= htmlspecialchars($dev['device_model'] ?? '—') ?></td>
                            <td class="text-sm"><?= $os_labels[$dev['os']] ?? '—' ?></td>
                            <td class="text-sm text-muted">
                                <?= $dev['firmware_version'] ? htmlspecialchars($dev['firmware_version']) : '—' ?>
                            </td>
                            <td class="text-sm">
                                <?php if ($dev['utente_email']): ?>
                                    <div style="display:flex;align-items:center;gap:8px">
                                        <div style="width:26px;height:26px;border-radius:50%;background:var(--accent-g);display:flex;align-items:center;justify-content:center;font-weight:700;font-size:11px;flex-shrink:0">
                                            <?= strtoupper(substr($dev['utente_email'], 0, 1)) ?>
                                        </div>
                                        <span style="font-size:13px"><?= htmlspecialchars($dev['utente_email']) ?></span>
                                    </div>
                                <?php else: ?>
                                    <span class="text-muted">—</span>
                                <?php endif; ?>
                            </td>
                            <td class="text-sm text-muted">
                                <?= $dev['linked_at'] ? date('d/m/Y H:i', strtotime($dev['linked_at'])) : '—' ?>
                            </td>
                            <td class="text-sm"><?= (int)$dev['n_ticket'] ?></td>
                            <td class="text-sm">
                                <?php if ($dev['ticket_aperti'] > 0): ?>
                                    <span style="color:var(--danger);font-weight:600"><?= (int)$dev['ticket_aperti'] ?></span>
                                <?php else: ?>
                                    <span class="text-muted">0</span>
                                <?php endif; ?>
                            </td>
                            <td>
                                <?php if ($dev['ticket_aperti'] > 0): ?>
                                    <span class="device-status danger">
                                        <span class="dot"></span>
                                        Ticket aperto
                                    </span>
                                <?php else: ?>
                                    <span class="text-muted">—</span>
                                <?php endif; ?>
                            </td>
                            <td>
                                <button class="btn btn-secondary btn-sm"
                                        onclick="apriDettaglio(<?= htmlspecialchars(json_encode($dev), ENT_QUOTES) ?>)">
                                    Dettaglio
                                </button>
                            </td>
                        </tr>
                        <?php endforeach; ?>
                    <?php endif; ?>
                    </tbody>
                </table>
            </div>
        </div>
    </main>
</div>

<!-- Modal dettaglio dispositivo -->
<div class="modal-overlay" id="modal-dettaglio"
     onclick="if(event.target===this)this.classList.remove('open')">
    <div class="modal">
        <h2 class="modal-title" id="modal-device-id">—</h2>
        <div class="modal-sub" id="modal-device-model">—</div>

        <div class="stat-row">
            <div class="stat-box">
                <div class="stat-val" id="modal-n-ticket">—</div>
                <div class="stat-lbl">Ticket totali</div>
            </div>
            <div class="stat-box">
                <div class="stat-val" id="modal-aperti" style="color:var(--danger)">—</div>
                <div class="stat-lbl">Aperti</div>
            </div>
            <div class="stat-box">
                <div class="stat-val" id="modal-chiusi" style="color:var(--success)">—</div>
                <div class="stat-lbl">Chiusi</div>
            </div>
        </div>

        <div style="margin-bottom:20px">
            <div class="section-label">Dispositivo</div>
            <div class="meta-row">
                <div class="meta-label">ID Dispositivo</div>
                <div class="meta-value" id="modal-id" style="font-family:monospace;font-size:12px">—</div>
            </div>
            <div class="meta-row">
                <div class="meta-label">Modello</div>
                <div class="meta-value" id="modal-modello">—</div>
            </div>
            <div class="meta-row">
                <div class="meta-label">Sistema operativo</div>
                <div class="meta-value" id="modal-os">—</div>
            </div>
            <div class="meta-row">
                <div class="meta-label">Firmware</div>
                <div class="meta-value" id="modal-firmware">—</div>
            </div>
            <div class="meta-row">
                <div class="meta-label">Versione app</div>
                <div class="meta-value" id="modal-app-version">—</div>
            </div>
            <div class="meta-row">
                <div class="meta-label">Collegato il</div>
                <div class="meta-value" id="modal-linked-at">—</div>
            </div>
        </div>

        <div style="margin-bottom:20px">
            <div class="section-label">Proprietario</div>
            <div class="meta-row">
                <div class="meta-label">Email</div>
                <div class="meta-value">
                    <a id="modal-utente-email" href="#" style="color:var(--accent2)">—</a>
                </div>
            </div>
            <div class="meta-row">
                <div class="meta-label">ID Utente</div>
                <div class="meta-value" id="modal-user-id" style="font-family:monospace;font-size:11px">—</div>
            </div>
        </div>

        <div>
            <div class="section-label">Storico ticket</div>
            <div id="modal-tickets">
                <div class="text-muted text-sm">Caricamento...</div>
            </div>
        </div>

        <div style="display:flex;justify-content:flex-end;margin-top:20px">
            <button class="btn btn-secondary"
                    onclick="document.getElementById('modal-dettaglio').classList.remove('open')">
                Chiudi
            </button>
        </div>
    </div>
</div>

<script>
/* ── Custom select ── */
function toggleSelect(id) {
    const el = document.getElementById(id);
    const isOpen = el.classList.contains('open');
    document.querySelectorAll('.custom-select.open').forEach(s => s.classList.remove('open'));
    if (!isOpen) el.classList.add('open');
}

function selectOption(selectId, inputId, labelId, value, label) {
    document.getElementById(inputId).value = value;
    document.getElementById(labelId).textContent = label;
    document.querySelectorAll('#' + selectId + ' .custom-select-option').forEach(opt => {
        opt.classList.remove('selected');
    });
    event.currentTarget.classList.add('selected');
    document.getElementById(selectId).classList.remove('open');
}

document.addEventListener('click', function(e) {
    if (!e.target.closest('.custom-select')) {
        document.querySelectorAll('.custom-select.open').forEach(s => s.classList.remove('open'));
    }
});

/* ── Modal dettaglio ── */
const os_map = { android: 'Android', ios: 'iOS', other: 'Altro' };

function apriDettaglio(dev) {
    document.getElementById('modal-device-id').textContent    = 'Dispositivo: ' + dev.internal_device_id;
    document.getElementById('modal-device-model').textContent = dev.device_model ?? '—';
    document.getElementById('modal-id').textContent           = dev.internal_device_id;
    document.getElementById('modal-modello').textContent      = dev.device_model ?? '—';
    document.getElementById('modal-os').textContent           = os_map[dev.os] ?? '—';
    document.getElementById('modal-firmware').textContent     = dev.firmware_version ?? '—';
    document.getElementById('modal-app-version').textContent  = dev.app_version ? 'v' + dev.app_version : '—';
    document.getElementById('modal-n-ticket').textContent     = dev.n_ticket;
    document.getElementById('modal-aperti').textContent       = dev.ticket_aperti;
    document.getElementById('modal-chiusi').textContent       = dev.ticket_chiusi;
    document.getElementById('modal-user-id').textContent      = dev.user_id ?? '—';

    const emailEl = document.getElementById('modal-utente-email');
    emailEl.textContent = dev.utente_email ?? '—';
    emailEl.href = dev.utente_email ? 'mailto:' + dev.utente_email : '#';

    document.getElementById('modal-linked-at').textContent = dev.linked_at
        ? new Date(dev.linked_at).toLocaleString('it-IT') : '—';

    const ticketBox = document.getElementById('modal-tickets');
    ticketBox.innerHTML = '<div class="text-muted text-sm">Caricamento...</div>';

    if (!dev.user_id) {
        ticketBox.innerHTML = '<div class="text-muted text-sm">Nessun utente associato.</div>';
        document.getElementById('modal-dettaglio').classList.add('open');
        return;
    }

    fetch('utenti_tickets.php?user_id=' + encodeURIComponent(dev.user_id))
        .then(r => r.json())
        .then(tickets => {
            if (!tickets.length) {
                ticketBox.innerHTML = '<div class="text-muted text-sm">Nessun ticket.</div>';
                return;
            }
            ticketBox.innerHTML = tickets.map(t => `
                <div class="ticket-row">
                    <div>
                        <a href="ticket_detail.php?id=${t.ticket_id}">${escHtml(t.subject)}</a>
                        <div style="font-size:11px;color:var(--muted);margin-top:2px">${t.created_at}</div>
                    </div>
                    <span class="badge badge-${t.status}">
                        <span class="badge-dot"></span>
                        ${t.status === 'open' ? 'Aperto' : 'Chiuso'}
                    </span>
                </div>
            `).join('');
        })
        .catch(() => {
            ticketBox.innerHTML = '<div class="text-muted text-sm">Errore nel caricamento.</div>';
        });

    document.getElementById('modal-dettaglio').classList.add('open');
}

function escHtml(str) {
    return str.replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;').replace(/"/g,'&quot;');
}
</script>
</body>
</html>