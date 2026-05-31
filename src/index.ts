import { mount } from 'ripple';
// @ts-expect-error known issue with .tsrx imports
import { App } from './App.tsrx';

mount(App, {
  target: document.getElementById('root')!,
});
