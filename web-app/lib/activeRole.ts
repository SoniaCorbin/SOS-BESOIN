export type ActiveRole = 'client' | 'provider'

const KEY = 'sos_besoin_active_role'
const EVENT = 'active-role-change'

export function getActiveRole(): ActiveRole {
  if (typeof window === 'undefined') return 'client'
  return localStorage.getItem(KEY) === 'provider' ? 'provider' : 'client'
}

export function setActiveRole(role: ActiveRole) {
  localStorage.setItem(KEY, role)
  window.dispatchEvent(new CustomEvent<ActiveRole>(EVENT, { detail: role }))
}

export function onActiveRoleChange(callback: (role: ActiveRole) => void) {
  function handler(e: Event) {
    callback((e as CustomEvent<ActiveRole>).detail)
  }
  window.addEventListener(EVENT, handler)
  return () => window.removeEventListener(EVENT, handler)
}
