export function IconButton(
  { icon, label, variant, size, onClick }: {
    icon: string;
    label?: string;
    variant?: 'default' | 'primary' | 'secondary' | 'tertiary';
    size?: 'sm' | 'md' | 'lg' | 'xl';
    onClick?: (e: Event) => void;
  },
) {
  const v = variant ?? 'default';
  const s = size ?? 'md';
  return <>
    <button
      class={`icon-btn icon-btn--${v} icon-btn--${s}`}
      onClick={(e: Event) => {
        e.stopPropagation?.();
        onClick?.(e);
      }}
    >
      <span class="icon-btn__icon">{icon}</span>
      if (label) {
        <span class="icon-btn__label">{label}</span>
      }
    </button>
    <style>
      .icon-btn {
        display: flex;
        align-items: center;
        justify-content: center;
        gap: 6px;
        border: var(--border-width) solid var(--color-text);
        background: var(--color-surface-lowest);
        color: var(--color-text);
        font-family: var(--font-family);
        cursor: pointer;
        -webkit-tap-highlight-color: transparent;
        outline: none;
        transition: transform 0.05s ease, box-shadow 0.05s ease, background 0.15s ease;
        padding: 0;
      }

      .icon-btn:active {
        transform: translate(var(--shadow-offset), var(--shadow-offset));
        box-shadow: none;
      }

      .icon-btn--default {
        box-shadow: var(--shadow-offset) var(--shadow-offset) 0 var(--color-text);
      }

      .icon-btn--primary {
        background: var(--color-primary);
        color: var(--color-on-primary);
        box-shadow: var(--shadow-offset) var(--shadow-offset) 0 var(--color-text);
      }

      .icon-btn--secondary {
        border-color: var(--color-secondary);
        color: var(--color-secondary);
        background: var(--color-surface);
        box-shadow: var(--shadow-offset) var(--shadow-offset) 0 var(--color-secondary);
      }

      .icon-btn--tertiary {
        background: var(--color-tertiary);
        color: var(--color-on-tertiary);
        box-shadow: var(--shadow-offset) var(--shadow-offset) 0 var(--color-text);
      }

      .icon-btn--sm {
        width: 32px; height: 32px;
      }

      .icon-btn--md {
        min-width: var(--tap-min);
        min-height: var(--tap-min);
        padding: 8px 14px;
      }

      .icon-btn--lg {
        min-width: 52px;
        min-height: 52px;
        padding: 10px 20px;
      }

      .icon-btn--xl {
        min-width: 64px;
        min-height: 64px;
        padding: 14px 28px;
      }

      .icon-btn__icon {
        font-size: clamp(0.875rem, 2.5vw, 1.25rem);
        line-height: 1;
      }

      .icon-btn--lg .icon-btn__icon {
        font-size: clamp(1.25rem, 3.5vw, 1.75rem);
      }

      .icon-btn--xl .icon-btn__icon {
        font-size: clamp(1.75rem, 5vw, 2.5rem);
      }

      .icon-btn__label {
        font-size: var(--fs-metadata);
        font-weight: 700;
        letter-spacing: 0.06em;
        line-height: 1;
      }
    </style>
  </>;
}
