export function SearchInput(
  { placeholder, value, onInput }: {
    placeholder?: string;
    value: string;
    onInput?: (e: Event) => void;
  },
) {
  return <>
    <div class="search-wrap">
      <span class="search-icon">{'🔍'}</span>
      <input
        class="search-input"
        type="text"
        placeholder={placeholder ?? 'Search...'}
        value={value}
        onInput={(e: Event) => onInput?.(e)}
      />
    </div>
    <style>
      .search-wrap {
        position: relative;
        width: 100%;
      }

      .search-icon {
        position: absolute;
        inset-y: 0;
        left: 0;
        display: flex;
        align-items: center;
        padding-left: 14px;
        font-size: clamp(1.25rem, 3vw, 1.5rem);
        pointer-events: none;
        color: var(--color-text-muted);
      }

      .search-input {
        width: 100%;
        min-height: var(--tap-min);
        border: var(--border-width) solid var(--color-text);
        box-shadow: var(--shadow-offset-lg) var(--shadow-offset-lg) 0 var(--color-text);
        background: var(--color-surface-lowest);
        color: var(--color-text);
        font-family: var(--font-family);
        font-size: var(--fs-headline-md);
        font-weight: 800;
        letter-spacing: -0.02em;
        padding: 12px 14px 12px 48px;
        outline: none;
        -webkit-appearance: none;
        box-sizing: border-box;
      }

      .search-input:focus {
        border-color: var(--color-secondary);
        box-shadow: var(--shadow-offset-lg) var(--shadow-offset-lg) 0 var(--color-secondary);
      }

      .search-input::placeholder {
        color: var(--color-text-muted);
        font-weight: 400;
        font-size: var(--fs-body-reg);
        letter-spacing: 0;
        opacity: 0.5;
      }
    </style>
  </>;
}
