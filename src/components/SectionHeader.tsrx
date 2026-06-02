export function SectionHeader(
  { title, subtitle }: { title: string; subtitle?: string },
) {
  return <>
    <div class="section-header">
      <h2 class="section-header__title">{title}</h2>
      if (subtitle) {
        <span class="section-header__sub">{subtitle}</span>
      }
    </div>
    <style>
      .section-header {
        display: flex;
        align-items: center;
        gap: var(--gutter);
        padding-bottom: 8px;
        border-bottom: var(--border-width) solid var(--color-text);
        margin-bottom: var(--gutter);
      }

      .section-header__title {
        font-family: var(--font-family);
        font-size: var(--fs-headline-md);
        font-weight: 800;
        letter-spacing: -0.02em;
        line-height: var(--lh-headline);
        color: var(--color-text);
        margin: 0;
      }

      .section-header__sub {
        font-family: var(--font-family);
        font-size: var(--fs-metadata);
        font-weight: 700;
        letter-spacing: 0.06em;
        color: var(--color-text-muted);
        margin-left: auto;
      }
    </style>
  </>;
}
