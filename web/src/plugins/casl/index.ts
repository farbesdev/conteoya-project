import type { App } from 'vue'
import { abilitiesPlugin } from '@casl/vue'
import { ability, type Rule } from './ability'

export default function (app: App) {
  const userAbilityRules = useCookie<Rule[]>('userAbilityRules')
  if (userAbilityRules.value && userAbilityRules.value.length) {
    ability.update(userAbilityRules.value)
  } else {
    ability.update([{ action: 'manage', subject: 'all' }])
  }

  app.use(abilitiesPlugin, ability, {
    useGlobalProperties: true,
  })
}
