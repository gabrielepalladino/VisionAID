<!-- sidebar.php -->
<?php
// Calcola i ticket aperti se non già definiti dalla pagina che include la sidebar
if (!isset($ticket_aperti)) {
    $ticket_aperti = (int) getDB()->query("SELECT COUNT(*) FROM support_tickets WHERE status = 'open'")->fetchColumn();
}
?>
<aside class="sidebar" id="sidebar">

  <!-- Header / Logo -->
  <div class="sidebar-header">
    <div class="logo-mark">G</div>
    <div class="logo-text">
      <span class="logo-name">Gestionale</span>
      <span class="logo-sub">v1.0.0</span>
    </div>
    <button class="toggle-btn" id="toggleBtn" title="Comprimi sidebar">
      <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round">
        <polyline points="15 18 9 12 15 6"/>
      </svg>
    </button>
  </div>

  <!-- Nav principale -->
  <nav class="sidebar-nav">
    <span class="nav-section-label">Menu</span>

    <a href="dashboard.php" class="nav-item <?= basename($_SERVER['PHP_SELF']) === 'dashboard.php' ? 'active' : '' ?>" data-tooltip="Dashboard">
      <span class="nav-icon">
        <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
          <rect x="3" y="3" width="7" height="9" rx="1.5"/>
          <rect x="14" y="3" width="7" height="5" rx="1.5"/>
          <rect x="14" y="12" width="7" height="9" rx="1.5"/>
          <rect x="3" y="16" width="7" height="5" rx="1.5"/>
        </svg>
      </span>
      <span class="nav-text">Dashboard</span>
    </a>

    <a href="tickets.php" class="nav-item <?= basename($_SERVER['PHP_SELF']) === 'tickets.php' ? 'active' : '' ?>" data-tooltip="Ticket">
      <span class="nav-icon">
        <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
          <path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"/>
          <polyline points="14 2 14 8 20 8"/>
          <line x1="9" y1="13" x2="15" y2="13"/>
          <line x1="9" y1="17" x2="13" y2="17"/>
        </svg>
      </span>
      <span class="nav-text">Gestione Ticket</span>
      <?php if ($ticket_aperti > 0): ?>
        <span class="nav-badge"><?= $ticket_aperti ?></span>
      <?php endif; ?>
    </a>

    <a href="utenti.php" class="nav-item <?= basename($_SERVER['PHP_SELF']) === 'utenti.php' ? 'active' : '' ?>" data-tooltip="Utenti">
      <span class="nav-icon">
        <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
          <circle cx="12" cy="8" r="4"/>
          <path d="M4 20c0-4 3.6-7 8-7s8 3 8 7"/>
        </svg>
      </span>
      <span class="nav-text">Utenti</span>
    </a>

    <a href="devices.php" class="nav-item <?= basename($_SERVER['PHP_SELF']) === 'dispositivi.php' ? 'active' : '' ?>" data-tooltip="Dispositivi">
      <span class="nav-icon">
        <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
          <rect x="5" y="2" width="14" height="20" rx="2"/>
          <circle cx="12" cy="17" r="1"/>
        </svg>
      </span>
      <span class="nav-text">Dispositivi</span>
    </a>
  </nav>

  <!-- Footer -->
  <div class="sidebar-footer">

    <!-- Toggle tema -->
    <button class="theme-toggle" id="themeToggle" data-tooltip="Tema">
      <span class="nav-icon">
        <svg id="iconMoon" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
          <path d="M21 12.79A9 9 0 1 1 11.21 3 7 7 0 0 0 21 12.79z"/>
        </svg>
        <svg id="iconSun" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" style="display:none">
          <circle cx="12" cy="12" r="5"/>
          <line x1="12" y1="1" x2="12" y2="3"/><line x1="12" y1="21" x2="12" y2="23"/>
          <line x1="4.22" y1="4.22" x2="5.64" y2="5.64"/><line x1="18.36" y1="18.36" x2="19.78" y2="19.78"/>
          <line x1="1" y1="12" x2="3" y2="12"/><line x1="21" y1="12" x2="23" y2="12"/>
          <line x1="4.22" y1="19.78" x2="5.64" y2="18.36"/><line x1="18.36" y1="5.64" x2="19.78" y2="4.22"/>
        </svg>
      </span>
      <span class="theme-toggle-text" id="themeLabel">Tema scuro</span>
      <div class="theme-switch"></div>
    </button>

    <div class="sidebar-divider"></div>

    <!-- Logout -->
    <a href="/gestionale/app/partials/logout.php" class="nav-item danger" data-tooltip="Logout">
      <span class="nav-icon">
        <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
          <path d="M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4"/>
          <polyline points="16 17 21 12 16 7"/>
          <line x1="21" y1="12" x2="9" y2="12"/>
        </svg>
      </span>
      <span class="nav-text">Logout</span>
    </a>
  </div>
</aside>

<script>
(function () {
  const sidebar     = document.getElementById('sidebar');
  const toggleBtn   = document.getElementById('toggleBtn');
  const themeToggle = document.getElementById('themeToggle');
  const themeLabel  = document.getElementById('themeLabel');
  const iconMoon    = document.getElementById('iconMoon');
  const iconSun     = document.getElementById('iconSun');
  const mainContent = document.querySelector('.main-content');

  // ── Sidebar collapse ──────────────────────────────────────────────────────
  let collapsed = localStorage.getItem('sidebar_collapsed') === 'true';

  function applyCollapse() {
    sidebar.classList.toggle('collapsed', collapsed);
    if (mainContent) mainContent.classList.toggle('collapsed', collapsed);
  }

  applyCollapse();

  toggleBtn.addEventListener('click', () => {
    collapsed = !collapsed;
    localStorage.setItem('sidebar_collapsed', collapsed);
    applyCollapse();
  });

  // ── Theme ─────────────────────────────────────────────────────────────────
  let dark = localStorage.getItem('theme') === 'dark';

  function applyTheme() {
    document.documentElement.setAttribute('data-theme', dark ? 'dark' : 'light');
    themeLabel.textContent = dark ? 'Tema chiaro' : 'Tema scuro';
    iconMoon.style.display = dark ? 'none'  : 'block';
    iconSun.style.display  = dark ? 'block' : 'none';
  }

  applyTheme();

  themeToggle.addEventListener('click', () => {
    dark = !dark;
    localStorage.setItem('theme', dark ? 'dark' : 'light');
    applyTheme();
  });
})();
</script>