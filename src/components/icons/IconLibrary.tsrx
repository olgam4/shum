export function IconLibrary(&{ active }: { active: boolean }) {
  return <>
    <svg viewBox="0 0 24 24" class="icon" data-active={active} fill="none"
         stroke="currentColor" stroke-width="3" stroke-linecap="square" stroke-linejoin="miter">
      <rect x="3" y="4" width="18" height="3" />
      <rect x="3" y="10" width="14" height="3" />
      <rect x="3" y="16" width="10" height="3" />
    </svg>
  </>;
}
