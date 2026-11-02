import { defineCustomElement } from 'vue'
import BouncewithEvents from './BouncewithEvents.ce.vue'

if (!customElements.get('bouncewith-events')) {
  customElements.define('bouncewith-events', defineCustomElement(BouncewithEvents))
}
