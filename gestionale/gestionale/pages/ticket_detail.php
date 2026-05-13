<?php
// pages/ticket_detail.php
require_once '../app/auth/auth.php';
checkAuth();

$db   = getDB();
$user = currentUser();
$id   = $_GET['id'] ?? '';

if (!$id) {
    header('Location: tickets.php');
    exit;
}

$stmt = $db->prepare("
    SELECT 
        t.*,
        u.email             AS richiedente_email,
        u.os                AS dispositivo_os,
        u.device_model      AS dispositivo_modello,
        u.app_version       AS app_version,
        d.internal_device_id AS device_id,
        d.firmware_version  AS firmware_version,
        d.linked_at         AS device_linked_at
    FROM support_tickets t
    LEFT JOIN users u ON t.user_id = u.user_id
    LEFT JOIN devices d ON d.user_id = t.user_id
    WHERE t.ticket_id = ?
");
$stmt->execute([$id]);
$t = $stmt->fetch();

if (!$t) {
    header('Location: tickets.php');
    exit;
}

$success = '';
$error   = '';

if ($_SERVER['REQUEST_METHOD'] === 'POST') {

    // Unica action che salva tutto
    $status      = $_POST['status'] ?? $t['status'];
    $resolved_at = $t['resolved_at'];
    $resolved_by = $t['resolved_by'];

    if ($status === 'closed' && $t['status'] !== 'closed') {
        $resolved_at = date('Y-m-d H:i:s');
        $resolved_by = $user['email'];
    }
    if ($status === 'open') {
        $resolved_at = null;
        $resolved_by = null;
    }

    $note_operatore   = trim($_POST['note_operatore'] ?? '');
    $importo_raw      = str_replace(',', '.', trim($_POST['importo_addebito'] ?? ''));
    $importo_addebito = (is_numeric($importo_raw) && (float)$importo_raw > 0)
        ? (float)$importo_raw
        : null;

    $db->prepare("
        UPDATE support_tickets 
        SET status = ?, resolved_at = ?, resolved_by = ?,
            note_operatore = ?, importo_addebito = ?
        WHERE ticket_id = ?
    ")->execute([
        $status,
        $resolved_at,
        $resolved_by,
        $note_operatore ?: null,
        $importo_addebito,
        $id
    ]);

    $success = 'Ticket aggiornato con successo.';

    // Ricarica il ticket con i dati aggiornati
    $stmt->execute([$id]);
    $t = $stmt->fetch();
}

switch($t['dispositivo_os']) {
    case 'android': $os_label = 'Android'; break;
    case 'ios':     $os_label = 'iOS';     break;
    default:        $os_label = 'Altro';   break;
}
?>
<!DOCTYPE html>
<html lang="it">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>#<?= substr($t['ticket_id'], 0, 8) ?> — <?= htmlspecialchars($t['subject']) ?></title>
    <link rel="stylesheet" href="../styles/dashboard.css">
    <link rel="stylesheet" href="../styles/sidebar.css"/>
    <style>
        .detail-grid {
            display: grid;
            grid-template-columns: 1fr 320px;
            gap: 20px;
            align-items: start;
        }
        @media (max-width: 768px) {
            .detail-grid { grid-template-columns: 1fr; }
        }
        .meta-row {
            display: flex;
            justify-content: space-between;
            align-items: flex-start;
            padding: 10px 0;
            border-bottom: 1px solid var(--border);
            font-size: 14px;
            gap: 12px;
        }
        .meta-row:last-child { border-bottom: none; }
        .meta-label { color: var(--muted); white-space: nowrap; }
        .meta-value { text-align: right; word-break: break-all; }
        .device-badge {
            display: inline-flex;
            align-items: center;
            background: var(--surface2);
            border-radius: 6px;
            padding: 3px 10px;
            font-size: 13px;
            font-weight: 500;
        }
        .form-label {
            font-size: 11px;
            font-weight: 600;
            text-transform: uppercase;
            letter-spacing: .6px;
            color: var(--muted);
            margin-bottom: 6px;
            display: block;
        }
        .note-box {
            width: 100%;
            min-height: 130px;
            padding: 10px 12px;
            border-radius: 8px;
            border: 1px solid var(--border);
            background: #ffffff;
            color: #18181b;
            font-size: 13px;
            line-height: 1.6;
            resize: vertical;
            box-sizing: border-box;
            font-family: inherit;
            transition: border-color .2s;
        }
        [data-theme="dark"] .note-box {
            background: #25252c;
            color: var(--text);
        }
        .note-box:focus {
            outline: none;
            border-color: var(--accent2);
        }
        .note-box::placeholder { color: var(--muted); }
        .importo-wrap { position: relative; }
        .importo-wrap .currency {
            position: absolute;
            left: 12px;
            top: 50%;
            transform: translateY(-50%);
            color: var(--muted);
            font-size: 13px;
            pointer-events: none;
        }
        .importo-input {
            width: 100%;
            height: 40px;
            padding: 0 12px 0 28px;
            border-radius: 8px;
            border: 1px solid var(--border);
            background: #ffffff;
            color: #18181b;
            font-size: 13px;
            box-sizing: border-box;
            transition: border-color .2s;
        }
        [data-theme="dark"] .importo-input {
            background: #25252c;
            color: var(--text);
        }
        .importo-input:focus {
            outline: none;
            border-color: var(--accent2);
        }
        .addebito-indicator {
            margin-top: 8px;
            font-size: 12px;
            font-weight: 600;
            color: var(--danger);
        }
        .addebito-indicator.none {
            color: var(--muted);
            font-weight: 400;
        }

        /* Custom select */
        .custom-select { position: relative; width: 100%; }
        .custom-select-trigger {
            height: 40px;
            padding: 0 36px 0 12px;
            border-radius: 8px;
            border: 1px solid var(--border);
            font-size: 13px;
            cursor: pointer;
            display: flex;
            align-items: center;
            justify-content: space-between;
            transition: border-color .2s;
            user-select: none;
            background: #ffffff;
            color: #18181b;
        }
        [data-theme="dark"] .custom-select-trigger {
            background: #25252c;
            color: var(--text);
            border-color: var(--border);
        }
        .custom-select-trigger:hover,
        .custom-select.open .custom-select-trigger { border-color: var(--accent2); }
        .custom-select-trigger .arrow {
            font-size: 12px;
            color: var(--muted);
            transition: transform .2s;
            flex-shrink: 0;
        }
        .custom-select.open .custom-select-trigger .arrow { transform: rotate(180deg); }
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
            background: #25252c;
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
        .custom-select-option.selected { color: var(--accent2); font-weight: 600; }
        .custom-select-option.selected::after {
            content: '✓';
            margin-left: auto;
            font-size: 12px;
        }
    </style>
</head>
<body>
<div class="app-layout">
    <?php require_once '../app/partials/sidebar.php'; ?>

    <main class="main-content">

        <?php if ($success): ?>
            <div class="alert alert-success"><?= htmlspecialchars($success) ?></div>
        <?php endif; ?>
        <?php if ($error): ?>
            <div class="alert alert-error"><?= htmlspecialchars($error) ?></div>
        <?php endif; ?>

        <div class="page-header">
            <div>
                <div style="display:flex;align-items:center;gap:10px;margin-bottom:6px">
                    <span style="font-family:monospace;color:var(--muted);font-size:13px">
                        #<?= substr($t['ticket_id'], 0, 8) ?>
                    </span>
                    <span class="badge badge-<?= $t['status'] ?>">
                        <span class="badge-dot"></span>
                        <?= $t['status'] === 'open' ? 'Aperto' : 'Chiuso' ?>
                    </span>
                    <?php if ($t['importo_addebito'] > 0): ?>
                        <span style="font-size:13px;font-weight:600;color:var(--danger)">
                            Addebito: €<?= number_format($t['importo_addebito'], 2, ',', '.') ?>
                        </span>
                    <?php endif; ?>
                </div>
                <h1 class="page-title" style="font-size:22px"><?= htmlspecialchars($t['subject']) ?></h1>
            </div>
            <a href="tickets.php" class="btn btn-secondary">← Tutti i ticket</a>
        </div>

        <!-- Unico form che racchiude tutto -->
        <form method="POST">
            <input type="hidden" name="action" value="aggiorna">

            <div class="detail-grid">

                <!-- Colonna sinistra: messaggio, note, dispositivo -->
                <div>

                    <!-- Messaggio originale dell'utente -->
                    <div class="card" style="margin-bottom:16px">
                        <h2 class="card-title">Messaggio</h2>
                        <div style="font-size:15px;line-height:1.8;">
                            <?= nl2br(htmlspecialchars($t['message'])) ?>
                        </div>
                        <div style="margin-top:16px;padding-top:16px;border-top:1px solid var(--border);display:flex;flex-wrap:wrap;gap:16px;font-size:13px">
                            <div>
                                <span class="text-muted">Richiedente: </span>
                                <a href="mailto:<?= htmlspecialchars($t['richiedente_email']) ?>"
                                   style="color:var(--accent2)">
                                    <?= htmlspecialchars($t['richiedente_email'] ?? '—') ?>
                                </a>
                            </div>
                            <div>
                                <span class="text-muted">User ID: </span>
                                <span style="font-family:monospace;font-size:12px">
                                    <?= htmlspecialchars($t['user_id']) ?>
                                </span>
                            </div>
                        </div>
                    </div>

                    <!-- Note interne e addebito -->
                    <div class="card" style="margin-bottom:16px">
                        <h2 class="card-title">Note operatore</h2>
                        <div style="display:flex;flex-direction:column;gap:16px">
                            <div>
                                <label class="form-label">Note interne</label>
                                <textarea name="note_operatore" class="note-box"
                                    placeholder="Dettagli..."><?= htmlspecialchars($t['note_operatore'] ?? '') ?></textarea>
                            </div>
                            <div>
                                <label class="form-label">Importo addebito al cliente</label>
                                <div class="importo-wrap">
                                    <span class="currency">€</span>
                                    <input type="number"
                                           name="importo_addebito"
                                           class="importo-input"
                                           min="0"
                                           step="0.01"
                                           placeholder="0.00"
                                           value="<?= $t['importo_addebito'] ? number_format((float)$t['importo_addebito'], 2, '.', '') : '' ?>">
                                </div>
                                <?php if ($t['importo_addebito'] > 0): ?>
                                    <div class="addebito-indicator">
                                        Addebito attivo: €<?= number_format($t['importo_addebito'], 2, ',', '.') ?>
                                    </div>
                                <?php else: ?>
                                    <div class="addebito-indicator none">
                                        Nessun addebito impostato
                                    </div>
                                <?php endif; ?>
                            </div>
                        </div>
                    </div>

                    <!-- Informazioni sul dispositivo dell'utente -->
                    <div class="card">
                        <h2 class="card-title">Dispositivo & App</h2>
                        <div class="meta-row">
                            <div class="meta-label">Sistema operativo</div>
                            <div class="meta-value">
                                <span class="device-badge"><?= $os_label ?></span>
                            </div>
                        </div>
                        <div class="meta-row">
                            <div class="meta-label">Modello dispositivo</div>
                            <div class="meta-value"><?= htmlspecialchars($t['dispositivo_modello'] ?? '—') ?></div>
                        </div>
                        <div class="meta-row">
                            <div class="meta-label">Versione app</div>
                            <div class="meta-value">
                                <span class="device-badge">v<?= htmlspecialchars($t['app_version'] ?? '—') ?></span>
                            </div>
                        </div>
                        <div class="meta-row">
                            <div class="meta-label">Device ID</div>
                            <div class="meta-value">
                                <span style="font-family:monospace;font-size:11px">
                                    <?= $t['device_id'] ? htmlspecialchars($t['device_id']) : '—' ?>
                                </span>
                            </div>
                        </div>
                        <div class="meta-row">
                            <div class="meta-label">Firmware</div>
                            <div class="meta-value">
                                <?php if ($t['firmware_version']): ?>
                                    <span class="device-badge"><?= htmlspecialchars($t['firmware_version']) ?></span>
                                <?php else: ?>
                                    —
                                <?php endif; ?>
                            </div>
                        </div>
                        <div class="meta-row">
                            <div class="meta-label">Dispositivo collegato il</div>
                            <div class="meta-value text-sm">
                                <?= $t['device_linked_at']
                                    ? date('d/m/Y H:i', strtotime($t['device_linked_at']))
                                    : '—' ?>
                            </div>
                        </div>
                    </div>

                </div>

                <!-- Colonna destra: gestione stato e riepilogo -->
                <div>

                    <!-- Stato e pulsante salva -->
                    <div class="card" style="margin-bottom:16px">
                        <h2 class="card-title">Gestione</h2>
                        <div style="display:flex;flex-direction:column;gap:14px">
                            <div>
                                <label class="form-label">Stato</label>
                                <input type="hidden" name="status" id="status-value" value="<?= htmlspecialchars($t['status']) ?>">
                                <div class="custom-select" id="status-select">
                                    <div class="custom-select-trigger" onclick="toggleSelect('status-select')">
                                        <span id="status-label">
                                            <?= $t['status'] === 'open' ? 'Aperto' : 'Chiuso' ?>
                                        </span>
                                        <span class="arrow">▾</span>
                                    </div>
                                    <div class="custom-select-dropdown">
                                        <div class="custom-select-option <?= $t['status'] === 'open' ? 'selected' : '' ?>"
                                             onclick="selectOption('status-select','status-value','status-label','open','Aperto')">
                                            Aperto
                                        </div>
                                        <div class="custom-select-option <?= $t['status'] === 'closed' ? 'selected' : '' ?>"
                                             onclick="selectOption('status-select','status-value','status-label','closed','Chiuso')">
                                            Chiuso
                                        </div>
                                    </div>
                                </div>
                            </div>
                            <button type="submit" class="btn btn-primary" style="width:100%">
                                Salva modifiche
                            </button>
                        </div>
                    </div>

                    <!-- Riepilogo metadati ticket -->
                    <div class="card">
                        <h2 class="card-title">Dettagli ticket</h2>
                        <div class="meta-row">
                            <div class="meta-label">Ticket ID</div>
                            <div class="meta-value">
                                <span style="font-family:monospace;font-size:11px">
                                    <?= htmlspecialchars($t['ticket_id']) ?>
                                </span>
                            </div>
                        </div>
                        <div class="meta-row">
                            <div class="meta-label">Aperto il</div>
                            <div class="meta-value text-sm">
                                <?= date('d/m/Y H:i', strtotime($t['created_at'])) ?>
                            </div>
                        </div>
                        <div class="meta-row">
                            <div class="meta-label">Risolto il</div>
                            <div class="meta-value text-sm" style="color:<?= $t['resolved_at'] ? 'var(--success)' : 'var(--muted)' ?>">
                                <?= $t['resolved_at'] ? date('d/m/Y H:i', strtotime($t['resolved_at'])) : '—' ?>
                            </div>
                        </div>
                        <div class="meta-row">
                            <div class="meta-label">Risolto da</div>
                            <div class="meta-value text-sm">
                                <?= $t['resolved_by'] ? htmlspecialchars($t['resolved_by']) : '—' ?>
                            </div>
                        </div>
                        <div class="meta-row">
                            <div class="meta-label">Addebito</div>
                            <div class="meta-value text-sm" style="font-weight:600;color:<?= $t['importo_addebito'] > 0 ? 'var(--danger)' : 'var(--muted)' ?>">
                                <?= $t['importo_addebito'] > 0 ? '€' . number_format($t['importo_addebito'], 2, ',', '.') : 'Nessuno' ?>
                            </div>
                        </div>
                    </div>

                </div>
            </div>
        </form>

    </main>
</div>

<script>
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
</script>
</body>
</html>