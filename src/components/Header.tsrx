export function Header() {
  return <>
    <div class="shum-header">
      <h1 class="shum-wordmark" aria-label="SHUM">
        <span class="shum-char shum-char-a">{'S'}</span>
        <span class="shum-char shum-char-b">{'H'}</span>
        <span class="shum-char shum-char-c">{'U'}</span>
        <span class="shum-char shum-char-d">{'M'}</span>
      </h1>
      <span class="shum-subtitle">{'Шум'}</span>
    </div>

    <style>
      .shum-header {
        display: flex;
        flex-direction: column;
        align-items: center;
        gap: 0;
      }

      .shum-wordmark {
        display: flex;
        gap: clamp(4px, 1vw, 12px);
        font-size: clamp(3rem, 10vw, 7rem);
        font-weight: 900;
        letter-spacing: -0.04em;
        line-height: 1;
        margin: 0;
      }

      .shum-char {
        display: inline-block;
        border: var(--shum-border) solid currentColor;
        padding: clamp(4px, 1vw, 12px) clamp(8px, 2vw, 20px);
        background: var(--shum-color-surface);
        transition: transform 0.1s ease;
      }

      .shum-char-a {
        color: var(--shum-color-danger);
        box-shadow: var(--shum-shadow) var(--shum-shadow) 0px var(--shum-color-brand);
      }

      .shum-char-b {
        color: var(--shum-color-brand);
        box-shadow: var(--shum-shadow) var(--shum-shadow) 0px var(--shum-color-accent);
      }

      .shum-char-c {
        color: var(--shum-color-brand);
        box-shadow: var(--shum-shadow) var(--shum-shadow) 0px var(--shum-color-danger);
      }

      .shum-char-d {
        color: var(--shum-color-accent);
        box-shadow: var(--shum-shadow) var(--shum-shadow) 0px var(--shum-color-brand);
      }

      .shum-subtitle {
        font-size: clamp(0.75rem, 2vw, 1rem);
        letter-spacing: 0.5em;
        color: var(--shum-color-danger);
        opacity: 0.7;
        margin-top: 4px;
      }
    </style>
  </>;
}
