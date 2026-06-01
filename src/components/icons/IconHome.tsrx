export function IconHome(&{ active }: { active: boolean }) {
  return <>
    <svg viewBox="0 0 24 24" class="icon" data-active={active} fill="none"
         stroke="currentColor" stroke-width="3" stroke-linecap="square" stroke-linejoin="miter">
      <path d="M3 10L12 3L21 10" />
      <path d="M5 9V20H19V9" />
      <path d="M9 20V13H15V20" />
    </svg>
  </>;
}
