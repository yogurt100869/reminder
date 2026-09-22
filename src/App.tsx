import { useEffect, useMemo, useState } from 'react'
import { dueAlarms, isFutureAlarm, sortAlarms, type Alarm } from './alarm'
import './App.css'

type InstallPrompt = Event & {
  prompt: () => Promise<void>
  userChoice: Promise<{ outcome: 'accepted' | 'dismissed' }>
}

const storageKey = 'reminder:alarms:v1'

function loadAlarms(): Alarm[] {
  const saved = localStorage.getItem(storageKey)
  if (!saved) return []

  try {
    const value: unknown = JSON.parse(saved)
    if (!Array.isArray(value)) throw new Error('闹钟数据格式不正确')
    return value.filter((item): item is Alarm =>
      typeof item === 'object' &&
      item !== null &&
      typeof item.id === 'string' &&
      typeof item.title === 'string' &&
      typeof item.fireAt === 'string' &&
      typeof item.notified === 'boolean',
    )
  } catch (cause) {
    throw new Error(`无法读取本地闹钟：${messageFrom(cause)}`)
  }
}

function messageFrom(cause: unknown): string {
  return cause instanceof Error ? cause.message : String(cause)
}

function formatDate(date: string): string {
  return new Intl.DateTimeFormat('zh-CN', {
    month: 'long',
    day: 'numeric',
    weekday: 'short',
    hour: '2-digit',
    minute: '2-digit',
  }).format(new Date(date))
}

function defaultDateTime(): string {
  const date = new Date(Date.now() + 60 * 60 * 1000)
  date.setSeconds(0, 0)
  const local = new Date(date.getTime() - date.getTimezoneOffset() * 60_000)
  return local.toISOString().slice(0, 16)
}

function App() {
  const [initialState] = useState(() => {
    try {
      return { alarms: loadAlarms(), error: undefined }
    } catch (cause) {
      return { alarms: [] as Alarm[], error: messageFrom(cause) }
    }
  })
  const [alarms, setAlarms] = useState<Alarm[]>(initialState.alarms)
  const [title, setTitle] = useState('')
  const [fireAt, setFireAt] = useState(defaultDateTime)
  const [showForm, setShowForm] = useState(false)
  const [showInstallGuide, setShowInstallGuide] = useState(false)
  const [installPrompt, setInstallPrompt] = useState<InstallPrompt>()
  const [error, setError] = useState<string | undefined>(initialState.error)
  const [notice, setNotice] = useState<string>()

  useEffect(() => {
    const listener = (event: Event) => {
      event.preventDefault()
      setInstallPrompt(event as InstallPrompt)
    }
    window.addEventListener('beforeinstallprompt', listener)
    return () => window.removeEventListener('beforeinstallprompt', listener)
  }, [])

  useEffect(() => {
    const check = async () => {
      const due = dueAlarms(alarms)
      if (!due.length) return

      if ('Notification' in window && Notification.permission === 'granted') {
        try {
          const registration = await navigator.serviceWorker.ready
          for (const alarm of due) {
            await registration.showNotification('闹钟', {
              body: alarm.title,
              icon: `${import.meta.env.BASE_URL}app-icon-512.png`,
              tag: `reminder-${alarm.id}`,
            })
          }
        } catch (cause) {
          setError(`无法发送通知：${messageFrom(cause)}`)
          return
        }
      } else {
        setNotice(due.length === 1 ? due[0].title : `${due.length} 个闹钟已到时间`)
      }

      setAlarms((current) =>
        current.map((alarm) =>
          due.some(({ id }) => id === alarm.id) ? { ...alarm, notified: true } : alarm,
        ),
      )
    }

    void check()
    const timer = window.setInterval(() => void check(), 15_000)
    return () => window.clearInterval(timer)
  }, [alarms])

  useEffect(() => {
    try {
      localStorage.setItem(storageKey, JSON.stringify(alarms))
    } catch (cause) {
      setError(`无法保存闹钟：${messageFrom(cause)}`)
    }
  }, [alarms])

  const orderedAlarms = useMemo(() => sortAlarms(alarms), [alarms])

  const saveAlarm = async (event: React.FormEvent) => {
    event.preventDefault()
    if (!isFutureAlarm(fireAt)) {
      setError('闹钟时间必须晚于当前时间。')
      return
    }

    if ('Notification' in window && Notification.permission === 'default') {
      try {
        const permission = await Notification.requestPermission()
        if (permission === 'denied') {
          setNotice('通知权限未开启；保持应用打开仍会显示到期提示。')
        }
      } catch (cause) {
        setNotice(`当前浏览器无法开启通知：${messageFrom(cause)}`)
      }
    }

    setAlarms((current) => [
      ...current,
      {
        id: crypto.randomUUID(),
        title: title.trim() || '提醒',
        fireAt: new Date(fireAt).toISOString(),
        notified: false,
      },
    ])
    setTitle('')
    setFireAt(defaultDateTime())
    setShowForm(false)
  }

  const install = async () => {
    if (!installPrompt) {
      setShowInstallGuide(true)
      return
    }
    await installPrompt.prompt()
    await installPrompt.userChoice
    setInstallPrompt(undefined)
  }

  return (
    <main className="app-shell">
      <section className="page">
        <header className="page-header">
          <div>
            <p className="eyebrow">任意日期 · 任意时间</p>
            <h1>闹钟</h1>
          </div>
          <button className="add-button" onClick={() => setShowForm(true)} aria-label="新建闹钟">＋</button>
        </header>

        <button className="install-card" onClick={() => void install()}>
          <span>安装到 iPhone 主屏幕</span>
          <b>{installPrompt ? '安装' : '查看方法'} ›</b>
        </button>

        <aside className="limitation">
          网页版仅在打开或驻留时检查到期提醒；需要关闭 App 后仍可靠响铃，请使用仓库中的原生 iOS 版。
        </aside>

        {orderedAlarms.length === 0 ? (
          <div className="empty">
            <span>⏰</span>
            <h2>还没有闹钟</h2>
            <p>点击右上角加号，例如设置下周 14:00。</p>
          </div>
        ) : (
          <div className="alarm-list">
            {orderedAlarms.map((alarm) => {
              const elapsed = new Date(alarm.fireAt) <= new Date()
              return (
                <article className={elapsed ? 'alarm-row elapsed' : 'alarm-row'} key={alarm.id}>
                  <div>
                    <time>{formatDate(alarm.fireAt)}</time>
                    <strong>{alarm.title}</strong>
                  </div>
                  <div className="row-end">
                    {elapsed && <small>已结束</small>}
                    <button
                      onClick={() => setAlarms((current) => current.filter(({ id }) => id !== alarm.id))}
                      aria-label={`删除 ${alarm.title}`}
                    >
                      删除
                    </button>
                  </div>
                </article>
              )
            })}
          </div>
        )}
      </section>

      {showForm && (
        <div className="backdrop" role="presentation" onMouseDown={() => setShowForm(false)}>
          <form className="sheet" onSubmit={(event) => void saveAlarm(event)} onMouseDown={(event) => event.stopPropagation()}>
            <header><button type="button" onClick={() => setShowForm(false)}>取消</button><b>新建闹钟</b><button type="submit">保存</button></header>
            <label>标签<input value={title} onChange={(event) => setTitle(event.target.value)} placeholder="例如：开会" /></label>
            <label>日期和时间<input type="datetime-local" value={fireAt} min={defaultDateTime()} onChange={(event) => setFireAt(event.target.value)} required /></label>
          </form>
        </div>
      )}

      {showInstallGuide && (
        <div className="backdrop" role="presentation" onMouseDown={() => setShowInstallGuide(false)}>
          <section className="sheet guide" onMouseDown={(event) => event.stopPropagation()}>
            <header><span /><b>安装到 iPhone</b><button onClick={() => setShowInstallGuide(false)}>完成</button></header>
            <ol>
              <li>使用 Safari 打开本页面</li>
              <li>点击 Safari 底部的“分享”按钮</li>
              <li>选择“添加到主屏幕”</li>
              <li>点击右上角“添加”</li>
            </ol>
          </section>
        </div>
      )}

      {error && <div className="toast error" onClick={() => setError(undefined)}>{error}</div>}
      {notice && <div className="toast" onClick={() => setNotice(undefined)}>{notice}</div>}
    </main>
  )
}

export default App
