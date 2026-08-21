import type { VerticalNavItems } from '@layouts/types'

export default [
  {
    title: 'Dashboard',
    to: { path: '/admin/dashboard' },
    icon: { icon: 'ri-dashboard-line' },
  },
  {
    title: 'Resultados Públicos',
    to: { path: '/resultados' },
    icon: { icon: 'ri-bar-chart-box-line' },
    target: '_blank',
  },
  {
    heading: 'Gestión Electoral',
  },
  {
    title: 'Organizaciones',
    to: { path: '/admin/organizaciones' },
    icon: { icon: 'ri-flag-2-line' },
  },
  {
    title: 'Personeros',
    to: { path: '/admin/personeros' },
    icon: { icon: 'ri-user-shared-line' },
  },
  {
    title: 'Candidatos',
    to: { path: '/admin/candidatos' },
    icon: { icon: 'ri-user-star-line' },
  },
  {
    title: 'Mesas Electorales',
    to: { path: '/admin/mesas' },
    icon: { icon: 'ri-archive-line' },
  },
  {
    title: 'Actas y Auditoría',
    to: { path: '/admin/actas' },
    icon: { icon: 'ri-file-shield-line' },
  },
  {
    heading: 'Administración',
  },
  {
    title: 'Usuarios',
    to: { path: '/admin/usuarios' },
    icon: { icon: 'ri-shield-user-line' },
  },
] as VerticalNavItems
