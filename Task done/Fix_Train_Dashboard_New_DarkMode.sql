CREATE OR ALTER PROCEDURE [dbo].[sp_Train_Dashboard_New_html]
    @LoginID INT = 3,
    @LanguageID VARCHAR(2) = 'EN',
    @isWeb INT = 0
as
set nocount on;
declare @html nvarchar(max) = '';
set @html=N'
<style>
  .train-dashboard-wrapper {
    font-family:
      "" Segoe UI "",
      system-ui,
      -apple-system,
      sans-serif;
  }

  /* ── Infinite Scroll ── */
  .infinite-sentinel {
    display: flex;
    justify-content: center;
    align-items: center;
    padding: 12px 0;
    min-height: 40px;
  }

  .infinite-spinner {
    width: 22px;
    height: 22px;
    border: 2.5px solid var(--paradise-color-input-border, #e2e8f0);
    border-top-color: var(--paradise-color-primary, #3b82f6);
    border-radius: 50%;
    animation: infiniteSpin 0.7s linear infinite;
  }

  @keyframes infiniteSpin {
    to {
      transform: rotate(360deg);
    }
  }

  .tkg-avatar-img {
    object-fit: cover;
    box-shadow: 0 2px 6px rgba(0, 0, 0, 0.1);
    transition: transform 0.2s ease;
  }

  .tkg-avatar-img:hover {
    transform: scale(1.1);
  }

  .tkg-avatar-placeholder svg {
    width: 100%;
    height: 100%;
  }

  /* ── Filter bar ── */
  .train-filter-bar {
    display: flex;
    align-items: flex-end;
    gap: 12px;
    padding: 14px 16px;
    border-radius: 14px;
    border: 1px solid var(--paradise-color-input-border);
    box-shadow: 0 2px 8px rgba(0, 0, 0, 0.06);
    flex-wrap: wrap;
    margin-bottom: 18px;
  }

  .tkg-btn-load {
    height: 34px;
    padding: 0 20px;
    border-radius: 8px;
    border: none;
    font-size: 0.85rem;
    font-weight: 600;
    cursor: pointer;
    display: flex;
    align-items: center;
    gap: 6px;
    transition: all 0.2s ease;
    margin-bottom: 2px;
  }

  .tkg-btn-load:active {
    transform: translateY(0);
  }

  .tkg-btn-load i {
    font-size: 1rem;
  }

  .train-filter-bar .filter-field {
    display: flex;
    flex-direction: column;
    gap: 4px;
    flex: 1;
    min-width: 160px;
  }

  .train-filter-bar label {
    font-size: var(--paradise-font-body2);
    font-weight: var(--font-weight-semi-bold);
    color: var(--paradise-color-header1);
    margin: 0;
  }

  /* ── KPI Cards ── */
  .train-kpi-grid {
    display: grid;
    grid-template-columns: repeat(4, 1fr);
    gap: 16px;
    margin-bottom: 18px;
  }

  @media (max-width: 900px) {
    .train-kpi-grid {
      grid-template-columns: repeat(2, 1fr);
    }
  }

  @media (max-width: 500px) {
    .train-kpi-grid {
      grid-template-columns: 1fr;
    }
  }

  .train-kpi-card {
    position: relative;
    background: #fff;
    border-radius: 16px;
    padding: 16px 18px;
    box-shadow: 0 4px 15px rgba(0, 0, 0, 0.05);
    overflow: hidden;
    transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
    cursor: default;
    display: flex;
    flex-direction: column;
    border: 1px solid rgba(0, 0, 0, 0.03);
  }

  .train-kpi-card:hover {
    transform: translateY(-3px);
    box-shadow: 0 8px 24px rgba(0, 0, 0, 0.1);
  }

  /* Top accent line */
  .train-kpi-card::before {
    content: "" "";
    position: absolute;
    top: 0;
    left: 0;
    right: 0;
    height: 4px;
    background: var(--kpi-accent);
    border-radius: 16px 16px 0 0;
  }

  /* Faint circle decoration (bóng mờ tròn) - Scaled down */
  .train-kpi-card::after {
    content: "" "";
    position: absolute;
    right: -25px;
    bottom: -25px;
    width: 100px;
    height: 100px;
    border-radius: 50%;
    background: var(--kpi-accent);
    opacity: 0.06;
    pointer-events: none;
    z-index: 0;
  }

  /* KPI Colors */
  .train-kpi-card.kpi-onboard {
    --kpi-accent: var(--paradise-color-success, #10b981);
    --kpi-bg: rgba(var(--paradise-color-success-rgb, 16, 185, 129), 0.08);
  }

  .train-kpi-card.kpi-completed {
    --kpi-accent: var(--paradise-color-primary, #3b82f6);
    --kpi-bg: rgba(var(--paradise-color-primary-rgb, 59, 130, 246), 0.08);
  }

  .train-kpi-card.kpi-expiring {
    --kpi-accent: var(--paradise-color-danger, #ef4444);
    --kpi-bg: rgba(var(--paradise-color-danger-rgb, 239, 68, 68), 0.08);
  }

  .train-kpi-card.kpi-progress {
    --kpi-accent: #8b5cf6;
    /* Keep Purple if no root var found, or use Info */
    --kpi-bg: rgba(139, 92, 246, 0.08);
  }

  .kpi-header {
    display: flex;
    justify-content: space-between;
    align-items: center;
    margin-bottom: 14px;
    z-index: 1;
  }

  .kpi-icon-badge {
    width: 38px;
    height: 38px;
    border-radius: 10px;
    background: var(--kpi-bg);
    color: var(--kpi-accent);
    display: flex;
    align-items: center;
    justify-content: center;
    font-size: 18px;
  }

  .kpi-menu-btn {
    background: transparent;
    border: none;
    color: #94a3b8;
    cursor: pointer;
    font-size: 16px;
    padding: 4px;
    border-radius: 6px;
    transition: background 0.2s;
  }

  .kpi-menu-btn:hover {
    background: rgba(0, 0, 0, 0.04);
  }

  .kpi-body {
    margin-bottom: 12px;
    z-index: 1;
  }

  .kpi-label {
    font-size: 0.65rem;
    font-weight: 700;
    letter-spacing: 0.05em;
    text-transform: uppercase;
    color: #64748b;
    margin-bottom: 6px;
    line-height: 1.3;
  }

  .kpi-main-val {
    font-size: 1.8rem;
    font-weight: 800;
    color: var(--kpi-accent);
    line-height: 1;
    letter-spacing: -0.02em;
    margin-bottom: 4px;
  }

  .kpi-note {
    font-size: 0.75rem;
    color: #475569;
    font-weight: 500;
  }

  /* New Discrete Progress Bar - Compact */
  .kpi-footer {
    margin-top: auto;
    z-index: 1;
  }

  .kpi-bar-track {
    height: 5px;
    background: #f1f5f9;
    border-radius: 99px;
    margin-bottom: 8px;
    overflow: hidden;
  }

  .kpi-bar-fill {
    height: 100%;
    background: var(--kpi-accent);
    border-radius: 99px;
    width: 0%;
    transition: width 1s cubic-bezier(0.4, 0, 0.2, 1);
  }

  .kpi-status-text {
    font-size: 0.68rem;
    color: #64748b;
    font-weight: 600;
  }

  /* ═══════════════════════════════════════════════
       Knowledge Group Progress Section
    ════════════════════════════════════════════════ */
  .tkg-progress-section {
    border-radius: 18px;
    padding: 22px 24px 18px;
    box-shadow: 0 4px 18px rgba(0, 0, 0, 0.07);
    border: 1px solid rgba(0, 0, 0, 0.05);
  }

  /* -- Section header -- */
  .tkg-section-header {
    display: flex;
    align-items: center;
    justify-content: space-between;
    flex-wrap: wrap;
    gap: 12px;
    margin-bottom: 20px;
  }

  .tkg-section-title-wrap {
    display: flex;
    align-items: center;
    gap: 12px;
  }

  .tkg-section-icon {
    width: 42px;
    height: 42px;
    border-radius: 12px;
    background: linear-gradient(
      135deg,
      var(--paradise-color-primary, #3b82f6),
      #60a5fa
    );
    display: flex;
    align-items: center;
    justify-content: center;
    font-size: 20px;
    color: #fff;
    flex-shrink: 0;
    box-shadow: 0 4px 12px rgba(59, 130, 246, 0.3);
  }

  .tkg-section-title {
    font-size: 1rem;
    font-weight: var(--font-weight-bold, 700);
    color: var(--paradise-color-dark);
    line-height: 1.2;
  }

  .tkg-section-sub {
    font-size: 0.74rem;
    color: var(--paradise-color-secondary);
    margin-top: 2px;
  }

  /* -- Legend & Search -- */
  .tkg-header-actions {
    display: flex;
    align-items: center;
    gap: 20px;
    flex-wrap: wrap;
  }

  .tkg-search-wrap {
    position: relative;
    min-width: 200px;
  }

  .tkg-search-input {
    width: 100%;
    padding: 7px 12px 7px 34px;
    font-size: 0.78rem;
    border-radius: 8px;
    border: 1px solid rgba(0, 0, 0, 0.08);
    transition: all 0.2s cubic-bezier(0.4, 0, 0.2, 1);
    color: var(--paradise-color-dark);
  }

  .tkg-search-input:focus {
    outline: none;
    border-color: var(--paradise-color-primary, #3b82f6);
    box-shadow: 0 0 0 3px rgba(59, 130, 246, 0.12);
    min-width: 240px;
  }

  .tkg-search-icon {
    position: absolute;
    left: 11px;
    top: 50%;
    transform: translateY(-50%);
    font-size: 14px;
    color: var(--paradise-color-secondary);
    pointer-events: none;
    opacity: 0.6;
  }

  .tkg-legend {
    display: flex;
    align-items: center;
    gap: 16px;
    flex-wrap: wrap;
  }

  .tkg-legend-item {
    display: flex;
    align-items: center;
    gap: 6px;
    font-size: 0.73rem;
    font-weight: 600;
    color: var(--paradise-color-secondary);
    letter-spacing: 0.03em;
  }

  .tkg-dot {
    width: 10px;
    height: 10px;
    border-radius: 50%;
    flex-shrink: 0;
  }

  .tkg-dot--done {
    background: var(--paradise-color-success, #22c55e);
  }

  .tkg-dot--progress {
    background: var(--paradise-color-warning, #f59e0b);
  }

  .tkg-dot--none {
    background: #d1d5db;
  }

  /* -- Smart Filter Bar -- */
  .tkg-filter-bar {
    display: flex;
    flex-wrap: wrap;
    gap: 16px;
    margin-bottom: 20px;
    padding: 16px;
    border-radius: 12px;
    align-items: flex-end;
  }

  .tkg-filter-field {
    display: flex;
    flex-direction: column;
    gap: 6px;
    min-width: 180px;
  }

  .tkg-filter-label {
    font-size: 0.72rem;
    font-weight: 700;
    text-transform: uppercase;
    color: var(--paradise-color-secondary);
    letter-spacing: 0.05em;
  }

  /* Segmented Control */
  .tkg-segment {
    display: inline-flex;
    padding: 3px;
    border-radius: 8px;
    gap: 2px;
  }

  .tkg-segment-btn {
    padding: 5px 12px;
    border-radius: 6px;
    border: none;
    background: transparent;
    font-size: 0.75rem;
    font-weight: 600;
    color: #4b5563;
    cursor: pointer;
    transition: all 0.2s;
  }

  .tkg-segment-btn:hover {
    background: rgba(255, 255, 255, 0.5);
  }

  .tkg-segment-btn.active {
    color: var(--paradise-color-primary, #3b82f6);
    box-shadow: 0 2px 4px rgba(0, 0, 0, 0.05);
  }

  /* Tagbox style (Custom Select) */
  .tkg-tagbox-wrap {
    position: relative;
  }

  .tkg-tagbox-select {
    width: 100%;
    padding: 7px 12px;
    border-radius: 8px;
    border: 1px solid rgba(0, 0, 0, 0.1);
    font-size: 0.78rem;
    cursor: pointer;
    min-height: 35px;
  }

  /* -- Employee Row -- */
  .tkg-row {
    display: grid;
    grid-template-columns: 36px 1fr auto 28px;
    align-items: flex-start;
    /* Fix align to top */
    gap: 12px;
    padding: 14px 0;
    /* Slightly more padding for breathing room */
    border-bottom: 1px solid rgba(0, 0, 0, 0.05);
    animation: tkgFadeIn 0.35s ease both;
  }

  .tkg-avatar,
  .tkg-pct,
  .tkg-toggle {
    margin-top: 2px;
    /* Slight offset to align with text baseline */
  }

  .tkg-row:last-child {
    border-bottom: none;
  }

  @keyframes tkgFadeIn {
    from {
      opacity: 0;
      transform: translateY(6px);
    }

    to {
      opacity: 1;
      transform: translateY(0);
    }
  }

  /* Avatar circle */
  .tkg-avatar {
    width: 36px;
    height: 36px;
    border-radius: 50%;
    display: flex;
    align-items: center;
    justify-content: center;
    font-size: 13px;
    font-weight: 700;
    color: #fff;
    flex-shrink: 0;
    text-transform: uppercase;
    box-shadow: 0 2px 8px rgba(0, 0, 0, 0.15);
  }

  /* Bar column */
  .tkg-bar-col {
    display: flex;
    flex-direction: column;
    gap: 5px;
    min-width: 0;
  }

  .tkg-emp-meta {
    display: flex;
    align-items: baseline;
    gap: 8px;
    min-width: 0;
  }

  .tkg-emp-name {
    font-size: 0.82rem;
    font-weight: 600;
    color: var(--paradise-color-dark);
    white-space: nowrap;
    overflow: hidden;
    text-overflow: ellipsis;
  }

  .tkg-emp-dept {
    font-size: 0.68rem;
    color: var(--paradise-color-secondary);
    white-space: nowrap;
    flex-shrink: 0;
  }

  /* Stacked bar track */
  .tkg-bar-track {
    height: 10px;
    border-radius: 99px;
    overflow: hidden;
    display: flex;
  }

  .tkg-seg {
    height: 100%;
    transition: width 0.7s cubic-bezier(0.4, 0, 0.2, 1);
    width: 0;
  }

  .tkg-seg--done {
    background: var(--paradise-color-success, #22c55e);
  }

  .tkg-seg--progress {
    background: var(--paradise-color-warning, #f59e0b);
  }

  .tkg-seg--none {
    background: #e5e7eb;
  }

  /* Group pill dots below the bar */
  .tkg-group-pills {
    display: flex;
    flex-wrap: wrap;
    gap: 6px 4px;
    /* More vertical gap between rows */
    margin-top: 8px;
    max-height: 150px;
    /* Limit height to prevent giant rows */
    overflow-y: auto;
    padding-right: 6px;
    scrollbar-width: thin;
    scrollbar-color: rgba(0, 0, 0, 0.15) transparent;
  }

  /* Custom scrollbar for pills area */
  .tkg-group-pills::-webkit-scrollbar {
    width: 4px;
  }

  .tkg-group-pills::-webkit-scrollbar-track {
    background: transparent;
  }

  .tkg-group-pills::-webkit-scrollbar-thumb {
    background: rgba(0, 0, 0, 0.15);
    border-radius: 10px;
  }

  .tkg-group-pills::-webkit-scrollbar-thumb:hover {
    background: rgba(0, 0, 0, 0.25);
  }

  .tkg-pill {
    display: inline-flex;
    align-items: center;
    gap: 4px;
    padding: 2px 8px 2px 6px;
    border-radius: 99px;
    font-size: 0.65rem;
    font-weight: 600;
    white-space: nowrap;
    max-width: 140px;
    overflow: hidden;
    text-overflow: ellipsis;
    cursor: default;
    border: 1px solid transparent;
    transition: all 0.2s;
  }

  .tkg-pill:hover {
    filter: brightness(0.95);
    transform: translateY(-1px);
  }

  .tkg-pill--done {
    background: rgba(34, 197, 94, 0.13);
    color: #166534;
  }

  .tkg-pill--progress {
    background: rgba(245, 158, 11, 0.13);
    color: #92400e;
  }

  .tkg-pill--none {
    background: rgba(0, 0, 0, 0.06);
    color: #6b7280;
  }

  .tkg-pill-dot {
    width: 5px;
    height: 5px;
    border-radius: 50%;
    flex-shrink: 0;
  }

  .tkg-pill--done .tkg-pill-dot {
    background: #22c55e;
  }

  .tkg-pill--progress .tkg-pill-dot {
    background: #f59e0b;
  }

  .tkg-pill--none .tkg-pill-dot {
    background: #9ca3af;
  }

  /* Percent label */
  .tkg-pct {
    font-size: 0.82rem;
    font-weight: 700;
    color: var(--paradise-color-dark);
    white-space: nowrap;
    text-align: right;
  }

  /* Expand toggle */
  .tkg-toggle {
    width: 24px;
    height: 24px;
    border-radius: 6px;
    border: none;
    background: rgba(0, 0, 0, 0.05);
    cursor: pointer;
    display: flex;
    align-items: center;
    justify-content: center;
    font-size: 10px;
    color: var(--paradise-color-secondary);
    transition:
      background 0.15s,
      transform 0.2s;
    flex-shrink: 0;
    padding: 0;
  }

  .tkg-toggle:hover {
    background: rgba(0, 0, 0, 0.1);
  }

  .tkg-toggle.expanded {
    transform: rotate(180deg);
  }

  /* Skeleton */
  .tkg-skeleton-wrap {
    display: flex;
    flex-direction: column;
    gap: 10px;
    padding: 4px 0;
  }

  .tkg-skel-row {
    height: 52px;
    border-radius: 10px;
    background: linear-gradient(90deg, #f0f0f0 25%, #e0e0e0 50%, #f0f0f0 75%);
    background-size: 200% 100%;
    animation: tkgShimmer 1.4s infinite;
  }

  @keyframes tkgShimmer {
    0% {
      background-position: 200% 0;
    }

    100% {
      background-position: -200% 0;
    }
  }

  /* Empty state */
  .tkg-empty {
    text-align: center;
    padding: 36px 16px;
    color: var(--paradise-color-secondary);
    font-size: 0.85rem;
  }

  .tkg-empty .tkg-empty-icon {
    font-size: 32px;
    opacity: 0.35;
    display: block;
    margin-bottom: 8px;
}

  /* Dark mode */
  .dark-mode .tkg-progress-section,
  [data-bs-theme="dark"] .tkg-progress-section {
    background: #1e2126;
    border-color: rgba(255, 255, 255, 0.07);
  }

  @media (prefers-color-scheme: dark) {
    .tkg-progress-section {
      background: #1e2126;
      border-color: rgba(255, 255, 255, 0.07);
    }
  }

  .dark-mode .tkg-bar-track,
  [data-bs-theme="dark"] .tkg-bar-track {
    background: rgba(255, 255, 255, 0.08);
  }

  .dark-mode .tkg-skel-row,
  [data-bs-theme="dark"] .tkg-skel-row {
    background: linear-gradient(90deg, #2a2d35 25%, #32363f 50%, #2a2d35 75%);
    background-size: 200% 100%;
  }

  .dark-mode .tkg-toggle,
  [data-bs-theme="dark"] .tkg-toggle {
    background: rgba(255, 255, 255, 0.07);
  }

  .dark-mode .tkg-seg--none,
  [data-bs-theme="dark"] .tkg-seg--none {
    background: rgba(255, 255, 255, 0.1);
  }

  .dark-mode .tkg-pill--none,
  [data-bs-theme="dark"] .tkg-pill--none {
    background: rgba(255, 255, 255, 0.07);
    color: #9ca3af;
  }

  .dark-mode .tkg-dot--none,
  [data-bs-theme="dark"] .tkg-dot--none {
    background: #4b5563;
  }

  @media (max-width: 640px) {
    .tkg-row {
      grid-template-columns: 36px 1fr auto;
    }

    .tkg-toggle {
      display: none;
    }

    .tkg-group-pills {
      display: none;
    }
  }

  /* -- Insights Row (Activity & Alerts) -- */
  .tkg-insights-row {
    display: grid;
    grid-template-columns: 1fr 340px;
    gap: 18px;
    margin-bottom: 20px;
  }

  /* Leaderboard specific styles */
  .tkg-leaderboard-list {
    display: flex;
    flex-direction: column;
    gap: 0;
    height: 560px;
    overflow-y: auto;
    overflow-x: hidden;
    padding-right: 4px;
    scroll-behavior: smooth;
  }

  /* Custom scrollbar — leaderboard & insight lists */
  .tkg-leaderboard-list::-webkit-scrollbar,
  .tkg-tab-content::-webkit-scrollbar {
    width: 4px;
  }

  .tkg-leaderboard-list::-webkit-scrollbar-track,
  .tkg-tab-content::-webkit-scrollbar-track {
    background: transparent;
  }

  .tkg-leaderboard-list::-webkit-scrollbar-thumb,
  .tkg-tab-content::-webkit-scrollbar-thumb {
    background: rgba(0, 0, 0, 0.15);
    border-radius: 4px;
  }

  .dark-mode .tkg-leaderboard-list::-webkit-scrollbar-thumb,
  [data-bs-theme="dark"] .tkg-leaderboard-list::-webkit-scrollbar-thumb,
  .dark-mode .tkg-tab-content::-webkit-scrollbar-thumb,
  [data-bs-theme="dark"] .tkg-tab-content::-webkit-scrollbar-thumb {
    background: rgba(255, 255, 255, 0.15);
  }

  @media (max-width: 1199px) {
    .tkg-leaderboard-list {
      height: 440px;
    }
  }

  @media (max-width: 767px) {
    .tkg-leaderboard-list {
      height: 320px;
    }
  }

  .tkg-rank-item {
    display: flex;
    align-items: center;
    gap: 12px;
    padding: 10px 0;
    border-bottom: 1px solid rgba(0, 0, 0, 0.05);
    transition: background 0.2s;
  }

  .tkg-rank-item:last-child {
    border-bottom: none;
  }

  .tkg-rank-number {
    width: 24px;
    height: 24px;
    display: flex;
    align-items: center;
    justify-content: center;
    font-size: 0.75rem;
    font-weight: 700;
    color: var(--paradise-color-secondary);
    flex-shrink: 0;
  }

  .tkg-rank-item.rank-1 .tkg-rank-number {
    background: #ffd700;
    color: #fff;
    border-radius: 50%;
    box-shadow: 0 2px 6px rgba(255, 215, 0, 0.4);
  }

  .tkg-rank-item.rank-2 .tkg-rank-number {
    background: #c0c0c0;
    color: #fff;
    border-radius: 50%;
  }

  .tkg-rank-item.rank-3 .tkg-rank-number {
    background: #cd7f32;
    color: #fff;
    border-radius: 50%;
  }

  .tkg-rank-avatar {
    width: 32px;
    height: 32px;
    border-radius: 50%;
    background: #e5e7eb;
    display: flex;
    align-items: center;
    justify-content: center;
    font-size: 11px;
    font-weight: 600;
    color: #fff;
    flex-shrink: 0;
  }

  .tkg-rank-info {
    flex: 1;
    min-width: 0;
  }

  .tkg-rank-name {
    font-size: 0.8rem;
    font-weight: 600;
    color: var(--paradise-color-dark);
    white-space: nowrap;
    overflow: hidden;
    text-overflow: ellipsis;
  }

  .tkg-rank-meta {
    display: flex;
    align-items: center;
    justify-content: space-between;
    margin-top: 2px;
  }

  .tkg-rank-dept {
    font-size: 0.65rem;
    color: var(--paradise-color-secondary);
  }

  .tkg-rank-score {
    font-size: 0.75rem;
    font-weight: 700;
    color: var(--paradise-color-primary);
  }

  .tkg-rank-progress {
    height: 3px;
    background: rgba(0, 0, 0, 0.05);
    border-radius: 4px;
    margin-top: 4px;
    overflow: hidden;
  }

  .tkg-rank-progress-bar {
    height: 100%;
    background: var(--paradise-color-primary);
    border-radius: 4px;
    transition: width 0.5s ease;
  }

  /* Dark mode for leaderboard */
  .dark-mode .tkg-rank-item,
  [data-bs-theme="dark"] .tkg-rank-item {
    border-bottom-color: rgba(255, 255, 255, 0.05);
  }

  .dark-mode .tkg-rank-progress,
  [data-bs-theme="dark"] .tkg-rank-progress {
    background: rgba(255, 255, 255, 0.08);
  }

  .tkg-card {
    background: transparent;
    border-radius: 18px;
    padding: 20px;
    border: 1px solid rgba(0, 0, 0, 0.05);
    box-shadow: 0 4px 18px rgba(0, 0, 0, 0.06);
    display: flex;
    flex-direction: column;
  }

  .tkg-card-header {
    display: flex;
    align-items: center;
    justify-content: space-between;
    margin-bottom: 16px;
  }

  .tkg-card-title {
    font-size: 0.9rem;
    font-weight: 700;
    color: var(--paradise-color-dark);
    display: flex;
    align-items: center;
    gap: 8px;
  }

  .tkg-card-title i {
    color: var(--paradise-color-primary);
  }

  /* Activity Feed Styles */
  .tkg-activity-list {
    display: flex;
    flex-direction: column;
    gap: 14px;
    max-height: 400px;
    overflow-y: auto;
    padding-right: 8px;
  }

  .activity-item {
    display: flex;
    gap: 12px;
    position: relative;
    padding-bottom: 4px;
  }

  .activity-item::before {
    content: "" "";
    position: absolute;
    left: 17px;
    top: 36px;
    bottom: -10px;
    width: 1px;
    background: rgba(0, 0, 0, 0.05);
  }

  .activity-item:last-child::before {
    display: none;
  }

  .activity-avatar {
    width: 34px;
    height: 34px;
    border-radius: 50%;
    display: flex;
    align-items: center;
    justify-content: center;
    font-size: 11px;
    font-weight: 700;
    color: #fff;
    flex-shrink: 0;
    z-index: 1;
    box-shadow: 0 2px 6px rgba(0, 0, 0, 0.1);
  }

  .activity-content {
    display: flex;
    flex-direction: column;
    gap: 2px;
    min-width: 0;
  }

  .activity-text {
    font-size: 0.78rem;
    line-height: 1.4;
    color: var(--paradise-color-dark);
  }

  .activity-text b {
    font-weight: 700;
  }

  .activity-time {
    font-size: 0.68rem;
    color: var(--paradise-color-secondary);
    opacity: 0.8;
  }

  /* Alert Insights Styles (Tabs) */
  .tkg-tabs {
    display: flex;
    gap: 20px;
    border-bottom: 1px solid rgba(0, 0, 0, 0.05);
    margin-bottom: 16px;
  }

  .tkg-tab {
    padding: 8px 4px;
    font-size: 0.82rem;
    font-weight: 600;
    color: var(--paradise-color-secondary);
    cursor: pointer;
    position: relative;
    transition: color 0.2s;
  }

  .tkg-tab.active {
    color: var(--paradise-color-primary);
  }

  .tkg-tab.active::after {
    content: "" "";
    position: absolute;
    bottom: -1px;
    left: 0;
    right: 0;
    height: 2px;
    background: var(--paradise-color-primary);
    border-radius: 2px;
  }

  .tkg-tab-content {
    display: none;
    flex-direction: column;
    gap: 12px;
    animation: tkgFadeIn 0.3s ease both;
    height: 560px;
    overflow-y: auto;
    overflow-x: hidden;
    padding-right: 4px;
    scroll-behavior: smooth;
  }

  .tkg-tab-content.active {
    display: flex;
  }

  @media (max-width: 1199px) {
    .tkg-tab-content {
      height: 440px;
    }
  }

  @media (max-width: 767px) {
    .tkg-tab-content {
      height: 320px;
    }
  }

  .insight-item {
    display: flex;
    align-items: center;
    justify-content: space-between;
    padding: 10px 10px;
    border-radius: 10px;
    background: rgba(0, 0, 0, 0.02);
    transition:
      transform 0.2s,
      background 0.2s;
    gap: 12px;
  }

  .insight-item:hover {
    background: rgba(0, 0, 0, 0.04);
    transform: translateX(4px);
  }

  .insight-info {
    display: flex;
    flex-direction: column;
    gap: 2px;
    min-width: 0;
  }

  .insight-label {
    font-size: 0.8rem;
    font-weight: 600;
    color: var(--paradise-color-dark);
    white-space: nowrap;
    overflow: hidden;
    text-overflow: ellipsis;
  }

  .insight-sub {
    font-size: 0.7rem;
    color: var(--paradise-color-secondary);
  }

  .insight-action {
    display: flex;
    align-items: center;
    gap: 10px;
  }

  .insight-value {
    font-size: 0.85rem;
    font-weight: 700;
    color: var(--paradise-color-danger, #ef4444);
  }

  .insight-btn {
    width: 28px;
    height: 28px;
    border-radius: 8px;
    border: none;
    background: rgba(var(--paradise-color-primary-rgb, 59, 130, 246), 0.1);
    color: var(--paradise-color-primary);
    cursor: pointer;
    display: flex;
    align-items: center;
    justify-content: center;
    transition: all 0.2s;
  }

  .insight-btn:hover {
    background: var(--paradise-color-primary);
    color: #fff;
  }

  @media (max-width: 1024px) {
    .tkg-insights-row {
      grid-template-columns: 1fr;
    }
  }

  /* Dark mode adjustments for insights */
  .dark-mode .tkg-card,
  [data-bs-theme="dark"] .tkg-card {
    border-color: rgba(255, 255, 255, 0.07);
    box-shadow: 0 4px 18px rgba(0, 0, 0, 0.2);
  }

  .dark-mode .insight-item,
  [data-bs-theme="dark"] .insight-item {
    background: rgba(255, 255, 255, 0.03);
  }

  .dark-mode .activity-item::before,
  [data-bs-theme="dark"] .activity-item::before {
    background: rgba(255, 255, 255, 0.07);
  }

  /* -- Charts Row -- */
  .tkg-charts-row {
    display: grid;
    grid-template-columns: 1fr 400px;
    gap: 18px;
    margin-bottom: 20px;
  }

  .chart-container {
    height: 300px;
    width: 100%;
  }

  @media (max-width: 1024px) {
    .tkg-charts-row {
      grid-template-columns: 1fr;
    }
  }

  /* Dark mode adjustments for charts */
  .dark-mode .tkg-charts-row .tkg-card,
  [data-bs-theme="dark"] .tkg-charts-row .tkg-card {
    border-color: rgba(255, 255, 255, 0.07);
  }

  /* --- BỔ SUNG DARK MODE OVERRIDES CHO DASHBOARD MỚI --- */
  .dark-mode #sp_Train_Dashboard_New_html .train-kpi-card,
  [data-bs-theme="dark"] #sp_Train_Dashboard_New_html .train-kpi-card {
    background: #242a32 !important;
    border-color: rgba(255, 255, 255, 0.08) !important;
  }

  .dark-mode #sp_Train_Dashboard_New_html .train-filter-bar,
  [data-bs-theme="dark"] #sp_Train_Dashboard_New_html .train-filter-bar,
  .dark-mode #sp_Train_Dashboard_New_html .tkg-card,
  [data-bs-theme="dark"] #sp_Train_Dashboard_New_html .tkg-card {
    background: #242a32 !important;
    border-color: rgba(255, 255, 255, 0.08) !important;
  }

  .dark-mode #sp_Train_Dashboard_New_html .kpi-label,
  [data-bs-theme="dark"] #sp_Train_Dashboard_New_html .kpi-label {
    color: #9ca3af !important;
  }

  .dark-mode #sp_Train_Dashboard_New_html .kpi-note,
  [data-bs-theme="dark"] #sp_Train_Dashboard_New_html .kpi-note,
  .dark-mode #sp_Train_Dashboard_New_html .kpi-status-text,
  [data-bs-theme="dark"] #sp_Train_Dashboard_New_html .kpi-status-text {
    color: #aab3c2 !important;
  }

  .dark-mode #sp_Train_Dashboard_New_html .kpi-bar-track,
  [data-bs-theme="dark"] #sp_Train_Dashboard_New_html .kpi-bar-track {
    background: rgba(255, 255, 255, 0.08) !important;
  }

  .dark-mode #sp_Train_Dashboard_New_html .kpi-menu-btn:hover,
  [data-bs-theme="dark"] #sp_Train_Dashboard_New_html .kpi-menu-btn:hover {
    background: rgba(255, 255, 255, 0.1) !important;
  }

</style>

<div id="sp_Train_Dashboard_New_html" class="train-dashboard-wrapper">
  <!-- Filter bar -->
  <div class="train-filter-bar">
    <div class="filter-field">
      <label>%FromDate%</label>
      <div id="P8D906A036AD94AFF8B9A17D6D4D63B89"></div>
    </div>
    <div class="filter-field">
      <label>%ToDate%</label>
      <div id="P2937B2577DBC4284819C0ADB49EAF430"></div>
    </div>
    <div class="filter-field">
      <label>%Department%</label>
      <div id="P7D212A38B0A241C886A0F977A5E32CE3"></div>
    </div>
    <button id="btnLoadDashboard" class="tkg-btn-load btn btn-success">
      <i class="bi bi-filter"></i> Làm mới
    </button>
  </div>

  <!-- KPI Cards -->
  <div class="train-kpi-grid" id="trainKpiGrid">
    <!-- New Onboarding (Green) -->
    <div class="train-kpi-card kpi-onboard">
      <div class="kpi-header">
        <div class="kpi-icon-badge"><i class="bi bi-person-plus"></i></div>
        <button class="kpi-menu-btn"><i class="bi bi-three-dots"></i></button>
      </div>
      <div class="kpi-body">
        <div class="kpi-label">Nhân viên đang học</div>
        <div class="kpi-main-val" id="kpiValueOnboard">18</div>
        <div class="kpi-note">Nhân viên đang hoàn thành các nhóm kiến thức</div>
      </div>
      <div class="kpi-footer">
        <div class="kpi-bar-track">
          <div class="kpi-bar-fill" id="kpiBarOnboard" style="width: 72%"></div>
        </div>
        <div class="kpi-status-text" id="kpiStatusOnboard">
          13/18 đã bắt đầu lộ trình
        </div>
      </div>
    </div>

    <!-- Completed (Blue) -->
    <div class="train-kpi-card kpi-completed">
      <div class="kpi-header">
        <div class="kpi-icon-badge"><i class="bi bi-check2-square"></i></div>
        <button class="kpi-menu-btn"><i class="bi bi-three-dots"></i></button>
      </div>
      <div class="kpi-body">
        <div class="kpi-label">Hoàn thành kiến thức</div>
        <div class="kpi-main-val" id="kpiValueCompleted">5</div>
        <div class="kpi-note">Tỷ lệ nhân viên hoàn thành toàn bộ kiến thức</div>
      </div>
      <div class="kpi-footer">
        <div class="kpi-bar-track">
          <div
            class="kpi-bar-fill"
            id="kpiBarCompleted"
            style="width: 28%"
          ></div>
        </div>
        <div class="kpi-status-text" id="kpiStatusCompleted">
          5/18 nhân viên
        </div>
      </div>
    </div>

    <!-- Expiring (Red) -->
    <div class="train-kpi-card kpi-expiring">
      <div class="kpi-header">
        <div class="kpi-icon-badge"><i class="bi bi-clock-history"></i></div>
        <button class="kpi-menu-btn"><i class="bi bi-three-dots"></i></button>
      </div>
      <div class="kpi-body">
        <div class="kpi-label">Các nhân viên chưa bắt đầu học</div>
        <div class="kpi-main-val" id="kpiValueExpiring">4</div>
        <div class="kpi-note">Nhân viên chưa bắt đầu học kiến thức</div>
      </div>
      <div class="kpi-footer">
        <div class="kpi-bar-track">
          <div
            class="kpi-bar-fill"
            id="kpiBarExpiring"
            style="width: 22%"
          ></div>
        </div>
        <div class="kpi-status-text" id="kpiStatusExpiring">
          Cần nhắc nhở ngay
        </div>
      </div>
    </div>

    <!-- Test Pass Rate (Purple) -->
    <div class="train-kpi-card kpi-progress">
      <div class="kpi-header">
        <div class="kpi-icon-badge"><i class="bi bi-clipboard-check"></i></div>
        <button class="kpi-menu-btn"><i class="bi bi-three-dots"></i></button>
      </div>
      <div class="kpi-body">
        <div class="kpi-label">Tỷ lệ đạt bài test</div>
        <div class="kpi-main-val" id="kpiValueAverage">85%</div>
        <div class="kpi-note">Dựa trên kết quả đánh giá kỹ năng</div>
      </div>
      <div class="kpi-footer">
        <div class="kpi-bar-track">
          <div class="kpi-bar-fill" id="kpiBarAverage" style="width: 85%"></div>
        </div>
        <div class="kpi-status-text" id="kpiStatusAverage">
          Mục tiêu: &gt; 90% đạt yêu cầu
        </div>
      </div>
    </div>
  </div>
  <!-- /kpi-grid -->

  <!-- ── Dashboard Insights (New) ── -->
  <div class="tkg-insights-row">
    <!-- Left: Recent Activity Feed (Temporarily commented out) -->
    <!--
    <div class="tkg-card">
      <div class="tkg-card-header">
        <div class="tkg-card-title">
          <i class="bi bi-lightning-charge-fill"></i> Hoạt động gần đây
        </div>
      </div>
      <div class="tkg-activity-list" id="tkgActivityFeed">
        Data rendered by JS
      </div>
    </div>
    -->

    <!-- Center: Employee Leaderboard -->
    <div class="tkg-card">
      <div class="tkg-card-header">
        <div class="tkg-card-title">
          <i class="bi bi-award-fill"></i> Bảng xếp hạng học tập
        </div>
        <!-- <div class="tkg-card-meta" style="font-size: 11px; color: var(--paradise-color-secondary);">Top 10</div> -->
      </div>
      <div class="tkg-leaderboard-list" id="tkgLeaderboard">
        <!-- Data rendered by JS -->
      </div>
    </div>

    <!-- Right: Actionable Alerts -->
    <div class="tkg-card">
      <div class="tkg-tabs">
        <div class="tkg-tab active" data-tab="tab-weak-groups">
          Nhóm kiến thức yếu
        </div>
        <div class="tkg-tab" data-tab="tab-slow-learners">
          Nhân viên cần lưu ý
        </div>
      </div>

      <!-- Tab: Weak Groups -->

      <div class="tkg-tab-content active" id="tab-weak-groups">
        <div id="tkgWeakGroupsList">
          <!-- Data rendered by JS -->
        </div>
      </div>

      <!-- Tab: Slow Learners -->
      <div class="tkg-tab-content" id="tab-slow-learners">
        <div id="tkgSlowLearnersList">
          <!-- Data rendered by JS -->
        </div>
      </div>
    </div>
  </div>
  <!-- /tkg-insights-row -->

  <!-- ── Visual Analytics (New) ── -->
  <div class="tkg-charts-row">
    <!-- Left: Department Progress Comparison -->
    <div class="tkg-card">
      <div class="tkg-card-header">
        <div class="tkg-card-title">
          <i class="bi bi-graph-up-arrow"></i> Tiến độ theo phòng ban
        </div>
      </div>
      <div id="chartDeptProgress" class="chart-container"></div>
    </div>

    <!-- Right: Overall Status Distribution -->
    <div class="tkg-card">
      <div class="tkg-card-header">
        <div class="tkg-card-title">
          <i class="bi bi-pie-chart-fill"></i> Tỉ lệ trạng thái học tập
        </div>
      </div>
      <div id="chartOverallStatus" class="chart-container"></div>
    </div>
  </div>
  <!-- /tkg-charts-row -->
</div>
<!-- /train-dashboard-wrapper -->
<script>
    (() => {
        let api = true;
        let DataSource = [];
        let _pageCache = {};
        let _currentKeyword = "";
        let dataStore_ = null;


        '
            + (select loadUI from tblCommonControlType_Signed where UID = 'P8D906A036AD94AFF8B9A17D6D4D63B89')
        +(select loadUI from tblCommonControlType_Signed where UID = 'P2937B2577DBC4284819C0ADB49EAF430')
        +(select loadUI from tblCommonControlType_Signed where UID = 'P7D212A38B0A241C886A0F977A5E32CE3')
        +N'

        // Load DataSource: sp_loadDataDepartment
        if ("sp_loadDataDepartment" && "sp_loadDataDepartment".trim() !== "") {
            loadDataSourceCommon("DepartmentID", "sp_loadDataDepartment", function (data) {
                // Data được shared qua callback
            });
        }


        // Load DataSource: sp_LoadKnowledgeGroup
        if ("sp_LoadKnowledgeGroup" && "sp_LoadKnowledgeGroup".trim() !== "") {
            loadDataSourceCommon("KnowledgeGroupID", "sp_LoadKnowledgeGroup", function (data) {
                // Data được shared qua callback
            });
        }

        function loadDataSourceCommon(columnName, dataSourceSP, onSuccessCallback) {
            if (!columnName || !dataSourceSP || dataSourceSP.trim() === "") {
                console.warn("[loadDataSourceCommon] Missing columnName or dataSourceSP");
                return;
            }

            const dataSourceKey = "DataSource_" + columnName;
            // Sử dụng format: columnNameDataSourceLoaded để tương thích với code hiện tại
            const loadedKey = columnName + "DataSourceLoaded";

            // Kiểm tra nếu đã load rồi thì không load lại

            if (window[loadedKey] === true) {
                if (typeof onSuccessCallback === "function") {
                    onSuccessCallback(window[dataSourceKey] || []);
                }
                return;
            }

            // Kiểm tra nếu đang load thì đợi
            if (window[loadedKey] === "loading") {
                // Đợi một chút rồi thử lại
                setTimeout(function () {
                    loadDataSourceCommon(columnName, dataSourceSP, onSuccessCallback);
                }, 100);

                return;
            }


     // Đánh dấu đang load để tránh load trùng lặp
            window[loadedKey] = "loading";

            return new Promise((resolve, reject) => {
                AjaxHPAParadise({
                    data: {
                        name: dataSourceSP,

                        param: ["LoginID", LoginID, "LanguageID", LanguageID]
                    },
                    success: function (res) {
                        const json = typeof res === "string" ? JSON.parse(res) : res;

                        window[dataSourceKey] = (json.data && json.data[0]) || [];
                        window[loadedKey] = true;

                        // Ưu tiên lấy từ json response (nếu API trả về explicit)
                        // Sau đó mới fallback query dataSchema
                        let idField = json.valueExpr;
                        let nameField = json.displayExpr;

                        if (!idField || !nameField) {
                            if (json.dataSchema && json.dataSchema[0]) {
                                const schema = json.dataSchema[0];
                                if (!idField) idField = schema[0]?.name;
                                if (!nameField) nameField = schema[1]?.name;
                            }
                        }

                        window["DataSourceIDField_" + columnName] = idField || "ID";
                        window["DataSourceNameField_" + columnName] = nameField || "Name";

                        const data = window[dataSourceKey];

                        // callback trước
                        if (typeof onSuccessCallback === "function") {
                            onSuccessCallback(data, json);
                        }

                        // resolve sau
                        resolve(data);
                    },
                    error: function (err) {
                        console.error("[loadDataSourceCommon] Failed to load datasource for", columnName, ":", err);
                        window[loadedKey] = false;

                        if (typeof onSuccessCallback === "function") {
                            onSuccessCallback([]);
                        }

                        reject(err);
                    }
                });
            });
        }

        // ============================================================
        // AVATAR HELPERS — handle employee images and caching
        // ============================================================
        var DEFAULT_AVATAR_SVG = ''<svg viewBox="0 0 200 200" xmlns="http://www.w3.org/2000/svg" style="background:#ebf6ff"><circle cx="100" cy="235" r="100" fill="#a4c3f5" stroke="#7192c7" stroke-width="6"/><circle cx="100" cy="76" r="43" fill="#fde69a" stroke="#e0b958" stroke-width="6"/></svg>'';

        if (!window.GlobalEmployeeAvatarCache) {
            window.GlobalEmployeeAvatarCache = {};
        }

        function getAvatarHtml(item, size, className) {
        console.log(item)
            var empId = item.EmployeeID || item.id;
            var name = item.EmployeeName || item.name || '''';
            var paramImg = item.paramImg;
            var sizePx = size || 32;
            var extraClass = className || '''';

            // Nếu đã có trong cache
            var cachedUrl = window.GlobalEmployeeAvatarCache[empId];
            console.log(cachedUrl)
            if (cachedUrl) {
                return ''<img src="'' + cachedUrl + ''" class="tkg-avatar-img '' + extraClass + ''" style="width:'' + sizePx + ''px;height:'' + sizePx + ''px;border-radius:50%;object-fit:cover" title="'' + name + ''">'';
            }

            // Nếu có paramImg thì kích hoạt load async
            if (paramImg) {
                setTimeout(function() {
                    loadAvatarAsync(empId, paramImg);
                }, 100);

                // Trả về SVG làm placeholder trong khi chờ load
return ''<div class="tkg-avatar-placeholder '' + extraClass + ''" data-emp-id="'' + empId + ''" style="width:'' + sizePx + ''px;height:'' + sizePx + ''px;border-radius:50%;overflow:hidden" title="'' + name + ''">''
                     + DEFAULT_AVATAR_SVG
                     + ''</div>'';
            }

            // Nếu không có ảnh thì dùng initials và màu nền
            var initials = name.split(/\s+/).filter(function(w){return w;}).map(function(n) { return n[0]; }).join('''').slice(-2);
            var AVATAR_COLORS = [''#3b82f6'', ''#10b981'', ''#f59e0b'', ''#ef4444'', ''#8b5cf6''];
            var color = AVATAR_COLORS[empId % AVATAR_COLORS.length] || ''#3b82f6'';

            return ''<div class="tkg-avatar-placeholder '' + extraClass + ''" style="width:'' + sizePx + ''px;height:'' + sizePx + ''px;border-radius:50%;display:flex;align-items:center;justify-content:center;background:'' + color + '';color:#fff;font-weight:600;font-size:'' + (sizePx/2.5) + ''px;overflow:hidden" title="'' + name + ''">''
                 + (name ? initials : DEFAULT_AVATAR_SVG)
                 + ''</div>'';
        }

        function loadAvatarAsync(empId, paramImg) {
            if (window.GlobalEmployeeAvatarCache[empId]) return;

            AjaxHPAParadise({
                data: {
                    name: ''paradisefile_sp_GetFileAPI'',
                    param: decodeURIComponent(paramImg)
                },
                xhrFields: { responseType: "blob" },
                success: function (blob) {
                    try {
                        var blobUrl = "";
                        if (blob instanceof Blob) {
                            blobUrl = URL.createObjectURL(blob);
                        } else if (blob instanceof ArrayBuffer) {
                            var newBlob = new Blob([blob], { type: "image/jpeg" });
                            blobUrl = URL.createObjectURL(newBlob);
                        }

                        if (blobUrl) {
                            window.GlobalEmployeeAvatarCache[empId] = blobUrl;

                            // Cập nhật tất cả các avatar đang chờ trên UI
                            var placeholders = document.querySelectorAll(''.tkg-avatar-placeholder[data-emp-id="'' + empId + ''"]'');
                            placeholders.forEach(function(ph) {
                                var img = document.createElement(''img'');
                                img.src = blobUrl;
                                img.className = ''tkg-avatar-img '' + ph.className.replace(''tkg-avatar-placeholder'', '''').trim();
                                img.style.width = ph.style.width;
                                img.style.height = ph.style.height;
                                img.style.borderRadius = ''50%'';
                                img.style.objectFit = ''cover'';
                                img.title = ph.title;
                                if (ph.parentNode) ph.parentNode.replaceChild(img, ph);
                            });
                        }
                    } catch(e) {
                        console.warn("Error processing avatar blob for " + empId, e);
                    }
                }
            });
        }

        // ============================================================
        // KPI CARDS — fill values from API data
        // ============================================================
        function renderKpiCards(kpiData, testData) {
            // kpiData = RS0: { EmpInProgress, EmpCompleted, EmpNotStarted, TotalEmp }
            // testData = RS1: { TestPassRate }
            var inProgress = 0, completed = 0, notStarted = 0, total = 1, testRate = 0;

            if (kpiData && kpiData.length > 0) {
                var row = kpiData[0];
                inProgress = row.EmpInProgress || 0;
                completed = row.EmpCompleted || 0;

       notStarted = row.EmpNotStarted || 0;
                total = row.TotalEmp || 1;
            }
            if (testData && testData.length > 0) {
                testRate = testData[0].TestPassRate || 0;
            }

            // Fill KPI values
            var elInProg = document.getElementById(''kpiValueOnboard'');
            var elComp = document.getElementById(''kpiValueCompleted'');
            var elNotStart = document.getElementById(''kpiValueExpiring'');
            var elTestRate = document.getElementById(''kpiValueAverage'');

            if (elInProg) elInProg.textContent = inProgress;
            if (elComp) elComp.textContent = completed;
            if (elNotStart) elNotStart.textContent = notStarted;
            if (elTestRate) elTestRate.textContent = testRate + ''%'';

            // Fill status text
            var pctInProg = total > 0 ? Math.round(inProgress / total * 100) : 0;
            var pctComp = total > 0 ? Math.round(completed / total * 100) : 0;
            var pctNotStart = total > 0 ? Math.round(notStarted / total * 100) : 0;

            var stInProg = document.getElementById(''kpiStatusOnboard'');
            var stComp = document.getElementById(''kpiStatusCompleted'');
            var stNotStart = document.getElementById(''kpiStatusExpiring'');
            var stTestRate = document.getElementById(''kpiStatusAverage'');

            if (stInProg) stInProg.textContent = inProgress + '' / '' + total + '' nhân viên'';
            if (stComp) stComp.textContent = completed + '' / '' + total + '' nhân viên'';
            if (stNotStart) stNotStart.textContent = notStarted > 0 ? ''Cần nhắc nhở ngay'' : ''Không có'';
            if (stTestRate) stTestRate.textContent = ''Mục tiêu: > 90 % đạt yêu cầu'';

            // Animate progress bars
            requestAnimationFrame(function () {
                setTimeout(function () {
                    var bars = [
                        { id: ''kpiBarOnboard'', val: pctInProg },
                        { id: ''kpiBarCompleted'', val: pctComp },
                        { id: ''kpiBarExpiring'', val: pctNotStart },
                        { id: ''kpiBarAverage'', val: Math.min(testRate, 100) }
                    ];
                    bars.forEach(function (b) {
                        var el = document.getElementById(b.id);
                        if (el) el.style.width = b.val + ''%'';
                    });
                }, 150);
            });
        }

        // ──────────────────────────────────────────────────────────
        // DASHBOARD INSIGHTS (Activity & Alerts)
        // ──────────────────────────────────────────────────────────

        /** Render Recent Activity Feed */
          function renderRecentActivity() {
            var feed = document.getElementById(''tkgActivityFeed'');
            if (!feed) return;

            // var AVATAR_COLORS = [''#3b82f6'', ''#10b981'', ''#f59e0b'', ''#ef4444'', ''#8b5cf6''];

            // var data = [
            //     { name: ''Nguyễn Văn An'', group: ''Thực hành 5S'', time: ''2 phút trước'', type: ''done'' },
            //     { name: ''Trần Thị Bích'', group: ''An toàn lao động'', time: ''15 phút trước'', type: ''progress'' },
            //     { name: ''Lê Minh Quân'', group: ''Phòng cháy chữa cháy'', time: ''1 giờ trước'', type: ''done'' },
            //     { name: ''Phạm Thu Hương'', group: ''Kỹ năng giao tiếp'', time: ''3 giờ trước'', type: ''progress'' },
            //     { name: ''Hoàng Đức Thắng'', group: ''Nội quy công ty'', time: ''Hôm qua'', type: ''done'' }
            // ];

            // feed.innerHTML = '''';
            // data.forEach(function (row, i) {
            //     var avatarHtml = getAvatarHtml({ id: i, name: row.name }, 34);

            //     var item = document.createElement(''div'');
            //     item.className = ''activity-item'';
            //     item.innerHTML = `
            //       ${avatarHtml}
            //             <div class="activity-content">
            //                 <div class="activity-text">
            //                     <b>${row.name}</b> ${row.type === ''done'' ? ''vừa hoàn thành'' : ''đang học''
            //         } nhóm <b> ${row.group}</b>
            //                 </div>
            //     <div class="activity-time">${row.time}</div>
            //             </div>
            //         `;
            //     feed.appendChild(item);
            // });
            feed.innerHTML = ''<div class="tkg-empty" style="padding: 40px 0;">''
                + ''<span class="tkg-empty-icon bi bi-clock-history"></span>''
                + ''Chưa có hoạt động mới''
                + ''</div>'';
        }

        // ──────────────────────────────────────────────────────────
        // INFINITE SCROLL — Server-side pagination helper
        // ──────────────────────────────────────────────────────────
        var _scrollStates = {};

        /**
         * initInfiniteScroll — Renders initial data, then loads more from a
         *                       separate SP when user scrolls to the sentinel.
         * @param {Object} opts
         *   container    : DOM element (scrollable list)
         *   initialData  : Array — first batch from sp_Train_getDataDashboard

    *   pageSize     : Number — items per page (default 20)
         *   spName       : String — SP name for pagination (e.g. ''sp_Train_getLeaderboard'')
         *   renderItem   : function(item, globalIndex) → HTMLElement
         *   emptyHTML    : String — shown when no data
         *   stateKey     : String — unique identifier
         */
        function initInfiniteScroll(opts) {
            var container = opts.container;
            var initialData = opts.initialData || [];
            var pageSize = opts.pageSize || 20;
            var spName = opts.spName;
            var renderItem = opts.renderItem;
            var emptyHTML = opts.emptyHTML || '''';
            var stateKey = opts.stateKey;

            // Cleanup previous
            if (_scrollStates[stateKey] && _scrollStates[stateKey].observer) {
                _scrollStates[stateKey].observer.disconnect();
            }

            container.innerHTML = '''';

            if (!initialData || initialData.length === 0) {
                container.innerHTML = emptyHTML;
                _scrollStates[stateKey] = null;
                return;
            }

            var state = {
                pageIndex: 2,        // Page 1 already loaded from initial SP
                loading: false,
                noMore: initialData.length < pageSize, // If first batch < pageSize → no more data
                totalRendered: 0,
                observer: null
            };
            _scrollStates[stateKey] = state;

            // Sentinel element
            var sentinel = document.createElement(''div'');
            sentinel.className = ''infinite-sentinel'';
            sentinel.innerHTML = ''<div class="infinite-spinner"></div>'';

            // Render items into container
            function appendItems(items, startIndex) {
                var frag = document.createDocumentFragment();
                items.forEach(function (item, i) {
                    var globalIdx = startIndex + i;
                    var el = renderItem(item, globalIdx);
                    if (el) {
                        el.style.opacity = ''0'';
                        el.style.transform = ''translateY(8px)'';
                        el.style.transition = ''opacity .25s ease, transform .25s ease'';
                        el.style.transitionDelay = (i * 30) + ''ms'';
                        frag.appendChild(el);
                        // Trigger animation
                        requestAnimationFrame(function () {
                            el.style.opacity = ''1'';
     el.style.transform = ''translateY(0)'';
                        });
                    }
                });

                if (sentinel.parentNode) {
                    container.insertBefore(frag, sentinel);
                } else {
                    container.appendChild(frag);
                }
                state.totalRendered += items.length;
            }

            // Load next page from server
            function loadNextPage() {
                if (state.loading || state.noMore) return;
                state.loading = true;
                sentinel.style.display = '''';

                AjaxHPAParadise({
                    data: {
                        name: spName,
                        param: [
                            ''LoginID'', LoginID,
                            ''LanguageID'', window.LanguageID || ''VN'',
                            ''DepartmentID'', typeof InstanceDepartmentIDP7D212A38B0A241C886A0F977A5E32CE3 !== "undefined" && InstanceDepartmentIDP7D212A38B0A241C886A0F977A5E32CE3 ? InstanceDepartmentIDP7D212A38B0A241C886A0F977A5E32CE3.option("value") || "" : "",
                            ''FromDate'', typeof InstanceFromDateP8D906A036AD94AFF8B9A17D6D4D63B89 !== "undefined" && InstanceFromDateP8D906A036AD94AFF8B9A17D6D4D63B89 ? InstanceFromDateP8D906A036AD94AFF8B9A17D6D4D63B89.option("value") : null,
                            ''ToDate'', typeof InstanceToDateP2937B2577DBC4284819C0ADB49EAF430 !== "undefined" && InstanceToDateP2937B2577DBC4284819C0ADB49EAF430 ? InstanceToDateP2937B2577DBC4284819C0ADB49EAF430.option("value") : null,
                            ''PageIndex'', state.pageIndex,
                            ''PageSize'', pageSize
                        ]
                    },
                    success: function (res) {
                        if (typeof res === "string" && !IsNullOrEmpty(res)) {
                            res = res.includes("{") ? res : EncryptionStringDecryption(res);
                        }
                        var json = typeof res === ''string'' ? JSON.parse(res) : res;
                        var rows = (json.data && json.data[0]) ? json.data[0] : (Array.isArray(json) ? json : []);

                        if (rows.length === 0 || rows.length < pageSize) {
                            state.noMore = true;
                        }
                        if (rows.length > 0) {
                            appendItems(rows, state.totalRendered);
                            state.pageIndex++;
                        }
                        state.loading = false;

                        // Remove sentinel if no more data
                        if (state.noMore && sentinel.parentNode) {
                            sentinel.parentNode.removeChild(sentinel);
                            if (state.observer) state.observer.disconnect();
                        }
                    },
                    error: function () {
                        state.loading = false;
                        state.noMore = true;
                        if (sentinel.parentNode) sentinel.parentNode.removeChild(sentinel);
                    }
                });
            }

            // Render initial batch
            appendItems(initialData, 0);

            // Setup sentinel + observer (only if there might be more data)
            if (!state.noMore) {
                container.appendChild(sentinel);

                if (''IntersectionObserver'' in window) {
                    state.observer = new IntersectionObserver(function (entries) {
                        if (entries[0].isIntersecting && !state.loading && !state.noMore) {
                            loadNextPage();
                        }
                    }, {
                        root: container.closest(''.tkg-card'') || container.parentElement,
                        rootMargin: ''120px'',
      threshold: 0.1
                    });
                    state.observer.observe(sentinel);
                }
            }
        }

        /** Render Weak Groups — with server-side infinite scroll */
        function renderWeakGroups(weakData) {
            var weakList = document.getElementById(''tkgWeakGroupsList'');
            if (!weakList) return;

            initInfiniteScroll({
                container: weakList,
                initialData: weakData,
                pageSize: 20,
                spName: ''sp_Train_getWeakGroups'',
                stateKey: ''weakGroups'',
                emptyHTML: ''<div class="tkg-empty"><span class="tkg-empty-icon bi bi-check-circle"></span>Tất cả nhóm kiến thức đều đạt tỷ lệ tốt</div>'',
                renderItem: function (g) {
                    var el = document.createElement(''div'');
                    el.className = ''insight-item'';
                    var empInfo = (g.EmpAttempted || 0) + ''/'' + (g.TotalEmpAssigned || 0) + '' NV đã học, ''
                        + (g.EmpPassedGroup || 0) + '' pass hết'';
                    el.innerHTML = ''<div class="insight-info">''
                        + ''<div class="insight-label">'' + (g.KnowledgeGroupName || '''') + ''</div>''
              + ''<div class="insight-sub">'' + empInfo + ''</div>''
                        + ''</div>''
                        + ''<div class="insight-action">''
                        + ''<div class="insight-value">'' + (g.GroupPassRate || 0) + ''%</div>''
                        + ''<button class="insight-btn" title="Gửi nhắc nhở cả nhóm"><i class="bi bi-bell"></i></button>''
                        + ''</div>'';

                    // Connect Notify Button (for Weak Groups, this would typically notify all assigned employees in the group)
                    var btn = el.querySelector(''.insight-btn'');
                    btn.addEventListener(''click'', function (ev) {
                        ev.stopPropagation();
                        remindKnowledge(g.KnowledgeGroupID);
                    });

                    return el;
                }
            });
        }

        /** Render Slow Learners — with server-side infinite scroll */
        function renderSlowLearners(slowData) {
            var slowList = document.getElementById(''tkgSlowLearnersList'');
            if (!slowList) return;

            initInfiniteScroll({
                container: slowList,
                initialData: slowData,
                pageSize: 20,
                spName: ''sp_Train_getSlowLearners'',
                stateKey: ''slowLearners'',
                emptyHTML: ''<div class="tkg-empty"><span class="tkg-empty-icon bi bi-check-circle"></span>Không có nhân viên cần lưu ý</div>'',
                renderItem: function (l) {
                    var el = document.createElement(''div'');
                    el.className = ''insight-item'';
                    var avatarHtml = getAvatarHtml(l, 36, ''tkg-avatar'');
                    el.innerHTML = avatarHtml
                        + ''<div class="insight-info">''
                        + ''<div class="insight-label">'' + (l.EmployeeName || '''') + ''</div>''
                        + ''<div class="insight-sub">'' + (l.Department || '''') + '' — '' + (l.AlertReason || '''') + ''</div>''
                        + ''</div>''
                        + ''<div class="insight-action">''
                        + ''<div class="insight-value">'' + (l.ProgressPct || 0) + ''%</div>''
                        + ''<button class="insight-btn" title="Nhắc nhở riêng"><i class="bi bi-chat-dots"></i></button>''
                        + ''</div>'';

                    // Connect Notify Button
                    var btn = el.querySelector(''.insight-btn'');
                    if (btn) {
                        btn.addEventListener(''click'', function (e) {
             e.stopPropagation();
                            handleRemind({
                                id: l.EmployeeID,
                                name: l.EmployeeName
                            });
                        });
                    }

                    return el;
                }
            });
        }

        /** Render Leaderboard — with server-side infinite scroll */
        function renderLeaderboard(leaderData) {
            var container = document.getElementById(''tkgLeaderboard'');
            if (!container) return;

            initInfiniteScroll({
                container: container,
                initialData: leaderData,
                pageSize: 20,
                spName: ''sp_Train_getLeaderboard'',
                stateKey: ''leaderboard'',
                emptyHTML: ''<div class="tkg-empty"><span class="tkg-empty-icon bi bi-trophy"></span>Chưa có dữ liệu xếp hạng</div>'',
                renderItem: function (item, index) {
                    var rank = index + 1;
                    var progress = item.ProgressPct || 0;
                    var avatarHtml = getAvatarHtml(item, 32, ''tkg-rank-avatar'');

                    var el = document.createElement(''div'');
                    el.className = ''tkg-rank-item rank-'' + rank;
                    el.innerHTML = ''<div class="tkg-rank-number">'' + rank + ''</div>''
                        + avatarHtml
                        + ''<div class="tkg-rank-info">''
                        + ''<div class="tkg-rank-name">'' + (item.EmployeeName || '''') + ''</div>''
                        + ''<div class="tkg-rank-meta">''
                        + ''<span class="tkg-rank-dept">'' + (item.Department || '''') + ''</span>''
                        + ''<span class="tkg-rank-score">'' + progress + ''%</span>''
                        + ''</div>''
                        + ''<div class="tkg-rank-progress">''
                        + ''<div class="tkg-rank-progress-bar" style="width:'' + progress + ''%"></div>''
                        + ''</div></div>'';
                    return el;
                }
            });
        }

        // ──────────────────────────────────────────────────────────
        // VISUAL ANALYTICS (Charts)
        // ──────────────────────────────────────────────────────────

        /** Initialize Charts using DevExtreme */
        function initDashboardCharts(kpiObj, deptData) {
            // Check if DevExtreme is loaded (avoid errors if not)
            if (typeof $ === "undefined" || !$.fn.dxChart) {
                console.warn("DevExtreme not found. Skipping charts.");
                return;
            }

            kpiObj = kpiObj || {};
            deptData = deptData || [];

            var isMany = deptData.length > 7;

            $("#chartDeptProgress").dxChart({
                rotated: isMany, // Tự động xoay nếu nhiều dữ liệu
                dataSource: deptData,
                commonSeriesSettings: {
                    argumentField: "dept",
                    type: "bar",
                    barPadding: isMany ? 0.2 : 0.4
                },
                series: [
                    { valueField: "completed", name: "Hoàn thành", color: "#22c55e" },
                    { valueField: "inProgress", name: "Đang học", color: "#f59e0b" }
                ],
                legend: {
                    verticalAlignment: "bottom",
                    horizontalAlignment: "center",
                    itemTextPosition: "right"
                },
                tooltip: {
                    enabled: true,
                    customizeTooltip: function (arg) {
                        return { text: arg.seriesName + ": " + arg.valueText + "%" };
                    }
                },
                argumentAxis: {
                    label: {
                        // Nếu đứng thì xoay nhãn 45 độ cho đẹp, nếu ngang thì để ngang

                        displayMode: isMany ? "standard" : "rotate",
                        rotationAngle: isMany ? 0 : 45
                    },
                    visualRange: isMany ? { length: 6 } : undefined
                },
                valueAxis: {
                    max: 100,
                    label: {
                        customizeText: function () { return this.valueText + "%"; }
                    }
                },
                scrollBar: {
                    visible: isMany
                },
                zoomAndPan: {
                    argumentAxis: isMany ? "pan" : "none",
                    allowMouseWheel: false
                }
            });

            // 2. Overall Status Distribution (Doughnut Chart)
            var doughnutData = [
                { status: ''Hoàn thành'', val: kpiObj.EmpCompleted || 0 },
                { status: ''Đang học'', val: kpiObj.EmpInProgress || 0 },
                { status: ''Chưa học'', val: kpiObj.EmpNotStarted || 0 }
            ];

            $("#chartOverallStatus").dxPieChart({
                type: "doughnut",
                palette: ["#22c55e", "#f59e0b", "#9ca3af"],
                dataSource: doughnutData,
                innerRadius: 0.65,
                series: [{
                    argumentField: "status",
                    valueField: "val",
                    label: {
                        visible: true,
                        connector: { visible: true },
                        format: "percent",
                        position: "outside",
                        customizeText: function (arg) {
                            return arg.argumentText + " (" + arg.percentText + ")";
                        }
                    }
                }],
                legend: { visible: false }
            });
        }

        /** Init Tab Switching */
        function initInsightTabs() {
            var tabs = document.querySelectorAll(''.tkg-tab'');
            tabs.forEach(function (tab) {
                tab.addEventListener(''click'', function () {
                    // Reset
                    tabs.forEach(function (t) { t.classList.remove(''active''); });
                    document.querySelectorAll(''.tkg-tab-content'').forEach(function (c) { c.classList.remove(''active''); });

                    // Set active
                    tab.classList.add(''active'');
                    var targetId = tab.getAttribute(''data-tab'');
                    var target = document.getElementById(targetId);
                    if (target) target.classList.add(''active'');
                });
            });
        }

        // ──────────────────────────────────────────────────────────
        // CENTRAL API CALL — sp_Train_getDataDashboard
        // ──────────────────────────────────────────────────────────
        function loadDashboardData() {
            AjaxHPAParadise({
                data: {
                    name: ''sp_Train_getDataDashboard'',
                    param: [
                        ''LoginID'', LoginID,
                        ''LanguageID'', window.LanguageID || ''VN'',
                        ''DepartmentID'', typeof InstanceDepartmentIDP7D212A38B0A241C886A0F977A5E32CE3 !== "undefined" && InstanceDepartmentIDP7D212A38B0A241C886A0F977A5E32CE3 ? InstanceDepartmentIDP7D212A38B0A241C886A0F977A5E32CE3.option("value") || "" : "",
                        ''FromDate'', typeof InstanceFromDateP8D906A036AD94AFF8B9A17D6D4D63B89 !== "undefined" && InstanceFromDateP8D906A036AD94AFF8B9A17D6D4D63B89 ? InstanceFromDateP8D906A036AD94AFF8B9A17D6D4D63B89.option("value") : null,
                        ''ToDate'', typeof InstanceToDateP2937B2577DBC4284819C0ADB49EAF430 !== "undefined" && InstanceToDateP2937B2577DBC4284819C0ADB49EAF430 ? InstanceToDateP2937B2577DBC4284819C0ADB49EAF430.option("value") : null,
          ]
},
                success: function (res) {
                    if (typeof res === "string" && !IsNullOrEmpty(res)) {
                        res = res.includes("{") ? res : EncryptionStringDecryption(res);
                    }
                    var json = typeof res === ''string'' ? JSON.parse(res) : res;
                    var data = json.data || [];
                    console.log(data)
                    // RS0: KPI Summary
                    var kpiData = data[0] || [];
                    // RS1: Tỷ lệ đạt bài test
                    var testData = data[1] || [];
                    // RS2: Xếp hạng học tập (Top 20)
                    var leaderData = data[2] || [];
                    // RS3: Nhóm kiến thức yếu (Top 20)
                    var weakData = data[3] || [];
                    // RS4: Nhân viên cần lưu ý (Top 20)
                    var slowData = data[4] || [];
                    // RS5: Biểu đồ Tiến độ phòng ban
                    var deptData = data[5] || [];

                    renderKpiCards(kpiData, testData);
                    renderLeaderboard(leaderData);
                    renderWeakGroups(weakData);
                    renderSlowLearners(slowData);
                    initDashboardCharts(kpiData[0], deptData);
                },
                error: function (err) {
                    console.error(''[loadDashboardData] Failed:'', err);
                    renderKpiCards([], []);
                    renderLeaderboard([]);
                    renderWeakGroups([]);
                    renderSlowLearners([]);
                }
            });
        }

        var isSendingRemindKnowledge = false;
        function remindKnowledge(knowledgeGroupID) {
            if (!knowledgeGroupID) return;
            if (isSendingRemindKnowledge) return;

            var lastSentKey = ''TrainingRemindGroup_'' + knowledgeGroupID;
            var lastSent = localStorage.getItem(lastSentKey);
            if (lastSent) {
                var diff = new Date().getTime() - parseInt(lastSent, 10);
                if (diff < 24 * 60 * 60 * 1000) { // 24 hour
                    uiManager.showAlert({ type: "warning", message: "Đã gửi thông báo cho nhóm này trong vòng 24 tiếng qua. Vui lòng chờ!" });
                    return;
                }
            }

            isSendingRemindKnowledge = true;
            if (typeof uiManager !== ''undefined'' && uiManager.showLoading) {
                uiManager.showLoading();
            }

            AjaxHPAParadise({
                data: {
                    name: "sp_Train_Notification_Knowledge",
                    param: [
                        "LoginID", window.LoginID || LoginID,
                        "KnowledgeGroupID", knowledgeGroupID
                    ]
                },
                success: function (data) {
                    isSendingRemindKnowledge = false;
                    if (typeof uiManager !== ''undefined'' && uiManager.hideLoading) {
                        uiManager.hideLoading();
                    }
                    if (typeof data == "string" && !IsNullOrEmpty(data)) {
                        data = data.includes("{") ? data : EncryptionStringDecryption(data);
                    }
                    localStorage.setItem(lastSentKey, new Date().getTime());
                    uiManager.showAlert({ type: "success", message: "Gửi thông báo thành công!" });
                },
                error: function () {
                    isSendingRemindKnowledge = false;
                    if (typeof uiManager !== ''undefined'' && uiManager.hideLoading) {
                        uiManager.hideLoading();
                    }
                    uiManager.showAlert({ type: "error", message: "Lỗi khi gửi thông báo." });
                }
            });
        }

        /** Handling Reminder (Sync with Knowledge module) */
        var isSendingHandleRemind = false;
        function handleRemind(emp) {
            if (!emp || !emp.id) return;
            if (isSendingHandleRemind) return;

            var lastSentKey = ''TrainingRemindEmp_'' + emp.id;
            var lastSent = localStorage.getItem(lastSentKey);
            if (lastSent) {
                var diff = new Date().getTime() - parseInt(lastSent, 10);
                if (diff < 24 * 60 * 60 * 1000) { // 24 hour
                    uiManager.showAlert({ type: "warning", message: "Đã nhắc nhở nhân viên này trong vòng 24 tiếng qua. Vui lòng chờ!" });
                    return;
                }
            }

            isSendingHandleRemind = true;
            if (typeof uiManager !== ''undefined'' && uiManager.showLoading) {
                uiManager.showLoading();
            }

            AjaxHPAParadise({
                data: {
                    name: "sp_TrainingNotificationKnowledge",
                    param: [
                        "LoginID", window.LoginID || LoginID,
                        "EmployeeIDs", emp.id
                    ]
                },
                success: function (data) {
                    isSendingHandleRemind = false;
                    if (typeof uiManager !== ''undefined'' && uiManager.hideLoading) {
                        uiManager.hideLoading();
                    }
                    if (typeof data == "string" && !IsNullOrEmpty(data)) {
                        data = data.includes("{") ? data : EncryptionStringDecryption(data);
                    }
                    localStorage.setItem(lastSentKey, new Date().getTime());
                    uiManager.showAlert({ type: "success", message: "Gửi thông báo thành công!" });
                },
                error: function () {
                    isSendingHandleRemind = false;
                    if (typeof uiManager !== ''undefined'' && uiManager.hideLoading) {
                        uiManager.hideLoading();
                    }
                    uiManager.showAlert({ type: "error", message: "Lỗi khi gửi thông báo." });
                }
            });
        }

        // ── Initialize everything ──
        loadDashboardData();

        renderRecentActivity();
        initInsightTabs();

        // Load button click event
        var btnLoad = document.getElementById(''btnLoadDashboard'');
  if (btnLoad) {
            btnLoad.addEventListener(''click'', function () {
                loadDashboardData();
            });
        }
    })();
</script>
'+@html

select @html as html

--exec sptblCommonControlType_Signed_DUC 'sp_Train_Dashboard_New_html'
--EXEC sp_GenerateHTMLScript_new 'sp_Train_Dashboard_New_html'
