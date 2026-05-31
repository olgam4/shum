export function EmptyState() {
  return <>
    <div class="empty-state">
      <div class="empty-glyph">~</div>
      <p class="empty-label">NOISE AWAITS</p>
      <p class="empty-hint">Select a track from your Navidrome library</p>
    </div>

    <style>
      .empty-state {
        display: flex;
        flex-direction: column;
        align-items: center;
        gap: 12px;
        border: var(--shum-border) dashed oklch(53% 0.28 12 / 0.4);
        padding: clamp(32px, 8vw, 56px) clamp(24px, 6vw, 48px);
      }

      .empty-glyph {
        font-size: clamp(3rem, 8vw, 5rem);
        color: oklch(53% 0.28 12 / 0.3);
        animation: empty-pulse 2s ease-in-out infinite;
      }

      @keyframes empty-pulse {
        0%, 100% { opacity: 0.3; transform: scale(1); }
        50% { opacity: 1; transform: scale(1.1); }
      }

      .empty-label {
        font-size: clamp(1rem, 3vw, 1.5rem);
        font-weight: 900;
        letter-spacing: 0.2em;
        color: oklch(53% 0.28 12 / 0.5);
        margin: 0;
      }

      .empty-hint {
        font-size: clamp(0.75rem, 2vw, 0.875rem);
        color: var(--shum-color-text-muted);
        margin: 0;
      }
    </style>
  </>;
}
