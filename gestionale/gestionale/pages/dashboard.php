<?php
// pages/dashboard.php — schema reale DB
require_once '../app/auth/auth.php';
checkAuth();

$db   = getDB();
$user = currentUser();

// ── Statistiche generali ──────────────────────────────────────────────────────
$stats['totale'] = (int) $db->query("SELECT COUNT(*) FROM support_tickets")->fetchColumn();

$st = $db->prepare("SELECT COUNT(*) FROM support_tickets WHERE status = 'open'");
$st->execute();
$stats['open'] = (int) $st->fetchColumn();

$st = $db->prepare("SELECT COUNT(*) FROM support_tickets WHERE status = 'closed'");
$st->execute();
$stats['closed'] = (int) $st->fetchColumn();

// ── Ticket per OS (con etichette italiane, include 'other') ───────────────────
$per_os_raw = $db->query("
    SELECT u.os, COUNT(*) as totale
    FROM support_tickets t
    LEFT JOIN users u ON t.user_id = u.user_id
    WHERE u.os IS NOT NULL
    GROUP BY u.os
    ORDER BY totale DESC
")->fetchAll(PDO::FETCH_ASSOC);

$os_label_map = ['android' => 'Android', 'ios' => 'iOS', 'other' => 'Altro'];
$per_os = [];
foreach ($per_os_raw as $row) {
    $per_os[] = [
        'os'     => $os_label_map[$row['os']] ?? ucfirst($row['os']),
        'totale' => $row['totale'],
    ];
}

// ── Ticket per stato (etichette italiane) ─────────────────────────────────────
$per_stato_raw = $db->query("
    SELECT status, COUNT(*) as totale
    FROM support_tickets
    GROUP BY status
")->fetchAll(PDO::FETCH_ASSOC);

$stato_label_map = ['open' => 'Aperti', 'closed' => 'Chiusi'];
$per_stato = [];
foreach ($per_stato_raw as $row) {
    $per_stato[] = [
        'status' => $stato_label_map[$row['status']] ?? ucfirst($row['status']),
        'totale' => $row['totale'],
    ];
}

// ── Ultimi 10 ticket ─────────────────────────────────────────────────────────
$recenti = $db->query("
    SELECT
        t.ticket_id,
        t.subject,
        t.status,
        t.created_at,
        t.resolved_at,
        t.resolved_by,
        u.email              AS user_email,
        u.app_version,
        u.os,
        u.device_model,
        d.internal_device_id AS device_id,
        d.firmware_version
    FROM support_tickets t
    LEFT JOIN users u ON t.user_id = u.user_id
    LEFT JOIN devices d ON d.user_id = t.user_id
    ORDER BY t.created_at DESC
    LIMIT 10
")->fetchAll(PDO::FETCH_ASSOC);

// ── JSON per Chart.js ─────────────────────────────────────────────────────────
$os_labels    = json_encode(array_column($per_os,    'os'));
$os_values    = json_encode(array_column($per_os,    'totale'));
$stato_labels = json_encode(array_column($per_stato, 'status'));
$stato_values = json_encode(array_column($per_stato, 'totale'));
?>
<!DOCTYPE html>
<html lang="it" data-theme="light">
<head>
  <meta charset="UTF-8"/>
  <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
  <title>Dashboard — Gestionale</title>
  <link rel="stylesheet" href="../styles/dashboard.css"/>
  <link rel="stylesheet" href="../styles/sidebar.css"/>
  <script src="https://cdnjs.cloudflare.com/ajax/libs/Chart.js/4.4.1/chart.umd.min.js"></script>
  <script>
    (function() {
      const t = localStorage.getItem('theme');
      if (t) document.documentElement.setAttribute('data-theme', t);
    })();
  </script>
  <style>
    .charts-grid {
      display: grid;
      grid-template-columns: 1fr 1fr;
      gap: 20px;
      margin-bottom: 24px;
    }
    @media (max-width: 900px) {
      .charts-grid { grid-template-columns: 1fr; }
    }
    .chart-card {
      background: var(--surface);
      border: 1px solid var(--border);
      border-radius: var(--radius-lg);
      padding: 22px 24px;
      box-shadow: var(--shadow);
      transition: background var(--transition), border-color var(--transition);
    }
    .chart-header {
      display: flex;
      align-items: center;
      justify-content: space-between;
      margin-bottom: 20px;
    }
    .chart-title {
      font-size: 14px;
      font-weight: 600;
      color: var(--text);
      letter-spacing: -0.2px;
    }
    .chart-sub {
      font-size: 11px;
      color: var(--text-muted);
      font-family: 'DM Mono', monospace;
      margin-top: 2px;
    }
    .chart-wrap {
      position: relative;
      height: 220px;
      display: flex;
      align-items: center;
      justify-content: center;
    }
    .chart-legend {
      display: flex;
      flex-wrap: wrap;
      gap: 10px;
      margin-top: 16px;
    }
    .legend-item {
      display: flex;
      align-items: center;
      gap: 6px;
      font-size: 12px;
      color: var(--text-secondary);
    }
    .legend-dot {
      width: 8px; height: 8px;
      border-radius: 50%;
      flex-shrink: 0;
    }
    .ticket-link {
      color: var(--text);
      font-weight: 500;
      transition: color .15s;
    }
    .ticket-link:hover { color: var(--accent); }
    .empty-state {
      text-align: center;
      padding: 48px 20px;
      color: var(--text-muted);
    }
    .empty-state svg { opacity: .3; margin-bottom: 12px; }
    .empty-state p { font-size: 13px; font-family: 'DM Mono', monospace; }
  </style>
</head>
<body>
<div class="app-layout">

  <?php require_once '../app/partials/sidebar.php'; ?>

  <button class="sidebar-hamburger" id="sidebarHamburger" aria-label="Apri menu">
    <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round">
      <line x1="3" y1="6"  x2="21" y2="6"/>
      <line x1="3" y1="12" x2="21" y2="12"/>
      <line x1="3" y1="18" x2="21" y2="18"/>
    </svg>
  </button>

  <div class="sidebar-overlay" id="sidebarOverlay"></div>

  <main class="main-content">

    <div class="page-header">
      <div>
        <h1 class="page-title">Dashboard</h1>
        <p class="page-sub">Benvenuto, <?= htmlspecialchars($user['email']) ?> — <?= strftime('%d %B %Y') ?? date('d F Y') ?></p>
      </div>
    </div>

    <!-- ── Stat cards ────────────────────────────────────────────────────── -->
    <div class="stat-grid">
      <div class="stat-card">
        <div class="stat-icon" style="background:var(--accent-light)">
          <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="var(--accent)" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
            <path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"/>
            <polyline points="14 2 14 8 20 8"/>
          </svg>
        </div>
        <div>
          <div class="stat-val"><?= $stats['totale'] ?></div>
          <div class="stat-lbl">Ticket totali</div>
        </div>
      </div>

      <div class="stat-card">
        <div class="stat-icon" style="background:var(--info-light)">
          <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="var(--info)" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
            <circle cx="12" cy="12" r="10"/><line x1="12" y1="8" x2="12" y2="12"/><line x1="12" y1="16" x2="12.01" y2="16"/>
          </svg>
        </div>
        <div>
          <div class="stat-val" style="color:var(--info)"><?= $stats['open'] ?></div>
          <div class="stat-lbl">Aperti</div>
        </div>
      </div>

      <div class="stat-card">
        <div class="stat-icon" style="background:var(--success-light)">
          <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="var(--success)" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
            <polyline points="20 6 9 17 4 12"/>
          </svg>
        </div>
        <div>
          <div class="stat-val" style="color:var(--success)"><?= $stats['closed'] ?></div>
          <div class="stat-lbl">Chiusi</div>
        </div>
      </div>
    </div>

    <!-- ── Grafici ───────────────────────────────────────────────────────── -->
    <div class="charts-grid">

      <div class="chart-card">
        <div class="chart-header">
          <div>
            <div class="chart-title">Ticket per sistema operativo</div>
            <div class="chart-sub">Distribuzione per OS degli utenti</div>
          </div>
        </div>
        <div class="chart-wrap">
          <canvas id="chartOs"></canvas>
        </div>
        <div class="chart-legend" id="legendOs"></div>
      </div>

      <div class="chart-card">
        <div class="chart-header">
          <div>
            <div class="chart-title">Ticket per stato</div>
            <div class="chart-sub">Aperti vs Chiusi</div>
          </div>
        </div>
        <div class="chart-wrap">
          <canvas id="chartStato"></canvas>
        </div>
        <div class="chart-legend" id="legendStato"></div>
      </div>

    </div>

    <!-- ── Tabella ticket recenti ────────────────────────────────────────── -->
    <div class="card">
      <div style="display:flex;align-items:center;justify-content:space-between;margin-bottom:20px">
        <div>
          <h2 class="card-title" style="margin-bottom:2px">Ticket Recenti</h2>
          <p style="font-size:12px;color:var(--text-muted);font-family:'DM Mono',monospace">Ultimi 10 inseriti</p>
        </div>
        <a href="tickets.php" class="btn btn-secondary btn-sm">Vedi tutti →</a>
      </div>

      <div class="table-wrap">
        <table>
          <thead>
            <tr>
              <th>ID</th>
              <th>Oggetto</th>
              <th>Utente</th>
              <th>Dispositivo</th>
              <th>Device ID</th>
              <th>Stato</th>
              <th>Creato il</th>
              <th>Risolto da</th>
              <th></th>
            </tr>
          </thead>
          <tbody>
            <?php if (empty($recenti)): ?>
              <tr>
                <td colspan="9">
                  <div class="empty-state">
                    <svg width="40" height="40" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5">
                      <path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"/>
                      <polyline points="14 2 14 8 20 8"/>
                    </svg>
                    <p>Nessun ticket trovato</p>
                  </div>
                </td>
              </tr>
            <?php else: ?>
              <?php
              $os_labels_it = ['android' => 'Android', 'ios' => 'iOS', 'other' => 'Altro'];
              foreach ($recenti as $t):
              ?>
              <tr>
                <td class="text-sm text-muted" style="font-family:'DM Mono',monospace">
                  <?= htmlspecialchars(substr($t['ticket_id'], 0, 8)) ?>…
                </td>
                <td style="max-width:220px">
                  <a href="ticket_detail.php?id=<?= urlencode($t['ticket_id']) ?>" class="ticket-link">
                    <?= htmlspecialchars($t['subject']) ?>
                  </a>
                </td>
                <td class="text-sm"><?= htmlspecialchars($t['user_email'] ?? '—') ?></td>
                <td>
                  <?php if ($t['device_model'] || $t['os']): ?>
                    <div class="text-sm"><?= htmlspecialchars($t['device_model'] ?? '—') ?></div>
                    <div class="text-sm text-muted" style="font-family:'DM Mono',monospace;margin-top:2px">
                      <?= htmlspecialchars($os_labels_it[$t['os']] ?? strtoupper($t['os'] ?? '')) ?>
                      <?php if ($t['app_version']): ?>· v<?= htmlspecialchars($t['app_version']) ?><?php endif; ?>
                    </div>
                  <?php else: ?>
                    <span class="text-muted">—</span>
                  <?php endif; ?>
                </td>
                <td class="text-sm text-muted" style="font-family:'DM Mono',monospace;font-size:11px">
                  <?= $t['device_id'] ? htmlspecialchars($t['device_id']) : '—' ?>
                </td>
                <td>
                  <?php if ($t['status'] === 'open'): ?>
                    <span class="badge badge-aperto"><span class="badge-dot"></span>Aperto</span>
                  <?php else: ?>
                    <span class="badge badge-chiuso"><span class="badge-dot"></span>Chiuso</span>
                  <?php endif; ?>
                </td>
                <td class="text-sm text-muted" style="white-space:nowrap">
                  <?= date('d/m/Y H:i', strtotime($t['created_at'])) ?>
                </td>
                <td class="text-sm text-muted">
                  <?= htmlspecialchars($t['resolved_by'] ?? '—') ?>
                </td>
                <td>
                  <a href="ticket_detail.php?id=<?= urlencode($t['ticket_id']) ?>" class="btn btn-secondary btn-sm">Apri</a>
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

<script>
function cssVar(name) {
  return getComputedStyle(document.documentElement).getPropertyValue(name).trim();
}

const paletteOs    = ['#2563eb', '#7c3aed', '#0891b2', '#16a34a', '#d97706'];
const paletteStato = { 'Aperti': '#2563eb', 'Chiusi': '#16a34a' };

const osLabels    = <?= $os_labels ?>;
const osValues    = <?= $os_values ?>;
const statoLabels = <?= $stato_labels ?>;
const statoValues = <?= $stato_values ?>;

function donutOptions(total) {
  return {
    responsive: true,
    maintainAspectRatio: false,
    cutout: '68%',
    plugins: {
      legend: { display: false },
      tooltip: {
        callbacks: {
          label: ctx => {
            const pct = total > 0 ? Math.round(ctx.parsed / total * 100) : 0;
            return ` ${ctx.label}: ${ctx.parsed} (${pct}%)`;
          }
        },
        backgroundColor: cssVar('--surface'),
        titleColor: cssVar('--text'),
        bodyColor: cssVar('--text-secondary'),
        borderColor: cssVar('--border'),
        borderWidth: 1,
        padding: 10,
        cornerRadius: 8,
      }
    }
  };
}

function buildLegend(containerId, labels, colors) {
  const el = document.getElementById(containerId);
  if (!el) return;
  el.innerHTML = labels.map((l, i) => `
    <div class="legend-item">
      <div class="legend-dot" style="background:${Array.isArray(colors) ? colors[i % colors.length] : (colors[l] || '#9ca3af')}"></div>
      ${l}
    </div>
  `).join('');
}

// Grafico OS
const totalOs = osValues.reduce((a, b) => a + b, 0);
new Chart(document.getElementById('chartOs'), {
  type: 'doughnut',
  data: { labels: osLabels, datasets: [{ data: osValues, backgroundColor: paletteOs, borderWidth: 0, hoverOffset: 6 }] },
  options: donutOptions(totalOs)
});
buildLegend('legendOs', osLabels, paletteOs);

// Grafico stato
const totalStato  = statoValues.reduce((a, b) => a + b, 0);
const statoColors = statoLabels.map(l => paletteStato[l] || '#9ca3af');
new Chart(document.getElementById('chartStato'), {
  type: 'doughnut',
  data: { labels: statoLabels, datasets: [{ data: statoValues, backgroundColor: statoColors, borderWidth: 0, hoverOffset: 6 }] },
  options: donutOptions(totalStato)
});
buildLegend('legendStato', statoLabels, statoColors);

// ── Hamburger menu mobile ─────────────────────────────────────────────────────
(function () {
  const hamburger = document.getElementById('sidebarHamburger');
  const overlay   = document.getElementById('sidebarOverlay');
  const sidebar   = document.getElementById('sidebar');
  if (!hamburger || !overlay || !sidebar) return;
  function openSidebar()  { sidebar.classList.add('open');    overlay.classList.add('visible'); }
  function closeSidebar() { sidebar.classList.remove('open'); overlay.classList.remove('visible'); }
  hamburger.addEventListener('click', openSidebar);
  overlay.addEventListener('click', closeSidebar);
})();
</script>
</body>
</html>