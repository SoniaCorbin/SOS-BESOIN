'use client'
import { useState, useEffect } from 'react'
import { ActiveRole, getActiveRole, onActiveRoleChange } from './activeRole'

export function useActiveRole(): ActiveRole {
  const [role, setRole] = useState<ActiveRole>('client')

  useEffect(() => {
    setRole(getActiveRole())
    return onActiveRoleChange(setRole)
  }, [])

  return role
}
