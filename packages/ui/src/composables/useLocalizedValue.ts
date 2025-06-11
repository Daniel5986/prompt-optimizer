import type { LocalizedString } from '@prompt-optimizer/core'
import { useI18n } from 'vue-i18n'

export function useLocalizedValue() {
  const { locale } = useI18n<{ message: any }, 'zh-CN' | 'en-US'>({ useScope: 'global' })

  const getLocalizedValue = (value?: LocalizedString): string => {
    if (!value) return '';
    return value[locale.value] || value['zh-CN'] || Object.values(value)[0] || ''
  }

  return { getLocalizedValue }
}
