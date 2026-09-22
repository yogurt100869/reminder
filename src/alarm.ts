export type Alarm = {
  id: string
  title: string
  fireAt: string
  notified: boolean
}

export function isFutureAlarm(fireAt: string, now = new Date()): boolean {
  const timestamp = new Date(fireAt).getTime()
  return Number.isFinite(timestamp) && timestamp > now.getTime()
}

export function dueAlarms(alarms: Alarm[], now = new Date()): Alarm[] {
  const timestamp = now.getTime()
  return alarms.filter((alarm) => !alarm.notified && new Date(alarm.fireAt).getTime() <= timestamp)
}

export function sortAlarms(alarms: Alarm[]): Alarm[] {
  return [...alarms].sort(
    (left, right) => new Date(left.fireAt).getTime() - new Date(right.fireAt).getTime(),
  )
}
