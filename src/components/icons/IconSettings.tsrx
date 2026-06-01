export function IconSettings(&{ active }: { active: boolean }) {
  return <>
    <svg viewBox="0 0 24 24" class="icon" data-active={active} fill="none"
         stroke="currentColor" stroke-width="3" stroke-linecap="square" stroke-linejoin="miter">
      <rect x="3" y="8" width="6" height="8" />
      <rect x="9" y="5" width="6" height="14" />
      <rect x="15" y="8" width="6" height="8" />
      <rect x="11" y="3" width="2" height="2" />
      <rect x="11" y="19" width="2" height="2" />
    </svg>
  </>;
}
