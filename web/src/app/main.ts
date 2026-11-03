import { createApp } from 'vue'
import { createPinia } from 'pinia'
import '@fontsource/space-grotesk/400.css'
import '@fontsource/space-grotesk/500.css'
import '@fontsource/space-grotesk/600.css'
import '@fontsource/space-grotesk/700.css'
import '@fontsource/bebas-neue/400.css'
import 'bootstrap/dist/css/bootstrap.min.css'
import 'bootstrap-icons/font/bootstrap-icons.min.css'
import 'vue-sonner/style.css'
import '@/styles/theme.css'
import App from './App.vue'
import { router } from './router'
import { i18n } from './i18n'
import { useAuthStore } from '@/features/auth/store'

const app = createApp(App)
app.use(createPinia())
app.use(i18n)
void useAuthStore().init()
app.use(router)
app.mount('#app')
