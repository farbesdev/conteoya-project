<script setup lang="ts">
import { PerfectScrollbar } from 'vue3-perfect-scrollbar'
import { useAuthStore } from '@/stores/useAuthStore'

const router = useRouter()
const authStore = useAuthStore()

const userData = computed(() => authStore.user || useCookie<any>('userData').value)

const logout = async () => {
  await authStore.logout()
  await router.replace('/login')
}

const userProfileList = computed(() => [
  { type: 'divider' },
  {
    type: 'navItem',
    icon: 'ri-dashboard-line',
    title: 'Panel de Control',
    to: { path: '/admin/dashboard' },
  },
  {
    type: 'navItem',
    icon: 'ri-bar-chart-box-line',
    title: 'Resultados Públicos',
    to: { path: '/resultados' },
  },
  ...(authStore.isAdmin ? [
    {
      type: 'navItem',
      icon: 'ri-shield-user-line',
      title: 'Gestión de Usuarios',
      to: { path: '/admin/usuarios' },
    },
  ] : []),
])
</script>

<template>
  <div class="d-flex align-center cursor-pointer" v-if="userData">
    <div class="d-none d-sm-flex flex-column align-end me-3">
      <span class="text-body-2 font-weight-medium">{{ userData.name || userData.fullName || userData.email }}</span>
      <span v-if="userData.personero?.political_organization_name" class="text-xs text-primary font-weight-bold">{{ userData.personero.political_organization_name }}</span>
      <span v-else class="text-xs text-disabled text-capitalize">{{ userData.role || 'Usuario' }}</span>
    </div>

    <VBadge
      dot
      bordered
      location="bottom right"
      offset-x="2"
      offset-y="2"
      color="success"
      class="user-profile-badge"
    >
      <VAvatar
        size="38"
        :color="!(userData && userData.avatar) ? 'primary' : undefined"
        :variant="!(userData && userData.avatar) ? 'tonal' : undefined"
      >
        <VImg
          v-if="userData && userData.avatar"
          :src="userData.avatar"
        />
        <VIcon
          v-else
          icon="ri-user-line"
        />
      </VAvatar>
    </VBadge>

    <!-- SECTION Menu -->
    <VMenu
      activator="parent"
      width="240"
      location="bottom end"
      offset="15px"
    >
      <VList>
        <VListItem class="px-4">
          <div class="d-flex gap-x-2 align-center">
            <VAvatar
              :color="!(userData && userData.avatar) ? 'primary' : undefined"
              :variant="!(userData && userData.avatar) ? 'tonal' : undefined"
            >
              <VImg
                v-if="userData && userData.avatar"
                :src="userData.avatar"
              />
              <VIcon
                v-else
                icon="ri-user-line"
              />
            </VAvatar>

            <div>
              <div class="text-body-2 font-weight-medium text-high-emphasis">
                {{ userData.name || userData.fullName || userData.email }}
              </div>
              <div class="text-capitalize text-caption text-disabled">
                {{ userData.role || 'Usuario' }}
                <span v-if="userData.personero?.political_organization_name" class="d-block text-xs mt-1 text-primary font-weight-medium">{{ userData.personero.political_organization_name }}</span>
              </div>
            </div>
          </div>
        </VListItem>

        <PerfectScrollbar :options="{ wheelPropagation: false }">
          <template
            v-for="(item, idx) in userProfileList"
            :key="idx"
          >
            <VListItem
              v-if="item.type === 'navItem'"
              :to="item.to"
              class="px-4"
            >
              <template #prepend>
                <VIcon
                  :icon="item.icon"
                  size="22"
                />
              </template>

              <VListItemTitle>{{ item.title }}</VListItemTitle>
            </VListItem>

            <VDivider
              v-else
              class="my-1"
            />
          </template>

          <VDivider class="my-1" />

          <VListItem class="px-4">
            <VBtn
              block
              color="error"
              size="small"
              append-icon="ri-logout-box-r-line"
              @click="logout"
            >
              Cerrar Sesión
            </VBtn>
          </VListItem>
        </PerfectScrollbar>
      </VList>
    </VMenu>
    <!-- !SECTION -->
  </div>
</template>

<style lang="scss">
.user-profile-badge {
  &.v-badge--bordered.v-badge--dot .v-badge__badge::after {
    color: rgb(var(--v-theme-background));
  }
}
</style>
