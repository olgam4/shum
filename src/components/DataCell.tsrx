export function DataCell(
  { label, value }: { label: string; value: string },
) {
  return <>
    <div class="data-cell">
      <span class="data-cell__label">{label}</span>
      <span class="data-cell__value">{value}</span>
    </div>
    <style>
      .data-cell {
        display: flex;
        flex-direction: column;
        gap: 4px;
        padding: 8px 10px;
        border: var(--border-width) solid var(--color-text);
        box-shadow: var(--shadow-offset) var(--shadow-offset) 0 var(--color-text);
        background: var(--color-surface-lowest);
      }

      .data-cell__label {
        font-family: var(--font-family);
        font-size: var(--fs-metadata);
        font-weight: 700;
        letter-spacing: 0.06em;
        color: var(--color-outline);
      }

      .data-cell__value {
        font-family: var(--font-family);
        font-size: var(--fs-label);
        font-weight: 600;
        color: var(--color-text);
        word-break: break-word;
      }
    </style>
  </>;
}
