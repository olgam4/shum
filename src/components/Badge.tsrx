export function Badge(
  { variant, children }: { variant?: 'default' | 'accent'; children?: any },
) {
  return <>
    <span
      class={`badge${variant === 'accent' ? ' badge--accent' : ''}`}
    >
      {children}
    </span>
    <style>
      .badge {
        display: inline-block;
        padding: 1px 6px;
        border: 2px solid var(--color-text);
        background: var(--color-surface-dim);
        color: var(--color-text);
        font-family: var(--font-family);
        font-size: var(--fs-metadata);
        font-weight: 700;
        letter-spacing: 0.04em;
        line-height: 1.3;
        white-space: nowrap;
      }

      .badge--accent {
        background: var(--color-primary);
        color: var(--color-on-primary);
      }
    </style>
  </>;
}
