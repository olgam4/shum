export function Header() {
  return <>
    <div class="header">
      <h1 class="wordmark" aria-label="SHUM">
        <span class="char char-a">{'Ш'}</span>
        <span class="char char-b">{'У'}</span>
        <span class="char char-c">{'М'}</span>
      </h1>
    </div>

    <style>
      .header {
        display: flex;
        flex-direction: column;
        align-items: center;
        padding: clamp(8px, 2vh, 16px) clamp(8px, 2vw, 20px);
        flex-shrink: 0;
      }

      .wordmark {
        display: flex;
        gap: clamp(3px, 0.8vw, 10px);
        font-size: clamp(2rem, 8vw, 5rem);
        font-weight: 900;
        letter-spacing: -0.04em;
        line-height: 1;
        margin: 0;
      }

      .char {
        display: inline-block;
        border: var(--border-width) solid currentColor;
        padding: clamp(3px, 0.8vw, 10px) clamp(6px, 1.5vw, 16px);
        background: var(--color-surface);
        transition: transform 0.1s ease;
      }

      .char-a {
        color: var(--color-tertiary);
        box-shadow: var(--shadow-offset) var(--shadow-offset) 0px var(--color-primary);
      }

      .char-b {
        color: var(--color-primary);
        box-shadow: var(--shadow-offset) var(--shadow-offset) 0px var(--color-secondary);
      }

      .char-c {
        color: var(--color-secondary);
        box-shadow: var(--shadow-offset) var(--shadow-offset) 0px var(--color-tertiary);
      }
    </style>
  </>;
}
