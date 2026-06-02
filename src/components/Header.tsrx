export function Header() {
  return <>
    <header class="header">
      <button class="header-btn">{'☰'}</button>
      <h1 class="wordmark">{'ШУМ'}</h1>
      <button class="header-btn">{'⚙'}</button>
    </header>

    <style>
      .header {
        display: flex;
        align-items: center;
        justify-content: space-between;
        flex-shrink: 0;
        width: 100%;
        padding: var(--unit) var(--margin);
        border-bottom: var(--border-width) solid var(--color-text);
        box-shadow: var(--shadow-offset) var(--shadow-offset) 0 var(--color-text);
        background: var(--color-surface);
        z-index: 40;
      }

      .header-btn {
        display: flex;
        align-items: center;
        justify-content: center;
        width: var(--tap-min);
        height: var(--tap-min);
        border: var(--border-width) solid transparent;
        background: transparent;
        color: var(--color-text);
        font-size: clamp(1.5rem, 4vw, 2rem);
        font-weight: 800;
        cursor: pointer;
        padding: 0;
        -webkit-tap-highlight-color: transparent;
        outline: none;
        transition: border-color 0.15s ease, background 0.15s ease, color 0.15s ease;
      }

      .header-btn:hover {
        border-color: var(--color-text);
        background: var(--color-primary);
        color: var(--color-on-primary);
      }

      .header-btn:active {
        transform: translate(2px, 2px);
      }

      .wordmark {
        font-family: var(--font-family);
        font-size: var(--fs-headline-lg);
        font-weight: 900;
        letter-spacing: -0.04em;
        line-height: 1;
        color: var(--color-text);
        margin: 0;
        text-transform: uppercase;
      }
    </style>
  </>;
}
