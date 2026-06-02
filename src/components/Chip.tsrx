export function Chip(
  { label, active, onClick }: {
    label: string;
    active?: boolean;
    onClick?: () => void;
  },
) {
  return <>
    <button
      class={`chip${active ? ' chip--active' : ''}`}
      data-active={active ? 'true' : 'false'}
      onClick={() => onClick?.()}
    >
      {label}
    </button>
    <style>
      .chip {
        flex-shrink: 0;
        padding: 6px 14px;
        border: var(--border-width) solid var(--color-text);
        box-shadow: var(--shadow-offset) var(--shadow-offset) 0 var(--color-text);
        background: var(--color-surface-lowest);
        color: var(--color-text);
        font-family: var(--font-family);
        font-size: var(--fs-label);
        font-weight: 600;
        letter-spacing: 0.04em;
        white-space: nowrap;
        cursor: pointer;
        min-height: var(--tap-min);
        -webkit-tap-highlight-color: transparent;
        outline: none;
        transition: transform 0.05s ease, box-shadow 0.05s ease, background 0.15s ease;
      }

      .chip:active {
        transform: translate(var(--shadow-offset), var(--shadow-offset));
        box-shadow: none;
      }

      .chip--active {
        background: var(--color-primary);
        color: var(--color-on-primary);
      }

      .chip:hover:not(.chip--active):not(:active) {
        background: var(--color-primary-container);
      }
    </style>
  </>;
}
