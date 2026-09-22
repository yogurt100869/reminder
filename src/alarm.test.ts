import { describe, expect, it } from 'vitest'
import { dueAlarms, isFutureAlarm, sortAlarms, type Alarm } from './alarm'

const alarm = (id: string, fireAt: string, notified = false): Alarm => ({
  id,
  title: id,
  fireAt,
  notified,
})

describe('alarm scheduling', () => {
  const now = new Date('2026-09-22T14:00:00+08:00')

  it('accepts only future dates', () => {
    expect(isFutureAlarm('2026-09-29T14:00:00+08:00', now)).toBe(true)
    expect(isFutureAlarm('2026-09-22T14:00:00+08:00', now)).toBe(false)
    expect(isFutureAlarm('invalid', now)).toBe(false)
  })

  it('returns unnotified alarms that are due', () => {
    const alarms = [
      alarm('past', '2026-09-22T13:00:00+08:00'),
      alarm('sent', '2026-09-22T13:30:00+08:00', true),
      alarm('future', '2026-09-22T15:00:00+08:00'),
    ]

    expect(dueAlarms(alarms, now).map(({ id }) => id)).toEqual(['past'])
  })

  it('sorts alarms chronologically without mutating input', () => {
    const alarms = [
      alarm('later', '2026-09-29T14:00:00+08:00'),
      alarm('earlier', '2026-09-22T14:00:00+08:00'),
    ]

    expect(sortAlarms(alarms).map(({ id }) => id)).toEqual(['earlier', 'later'])
    expect(alarms[0].id).toBe('later')
  })
})
