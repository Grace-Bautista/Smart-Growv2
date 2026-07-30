# Smart Grow RTDB Contract v1.0

## Scope and ownership

Firebase Realtime Database (RTDB) is the only live communication layer
between Flutter and the ESP32. Flutter writes desired commands only. ESP32
reports telemetry and controller output state. A successful command write is
not proof of hardware execution; Flutter renders ESP32-reported state.

| Branch | Flutter | ESP32 |
| --- | --- | --- |
| `liveData/smartGrow01` | read | write |
| `deviceCommands/smartGrow01` | create `pending` command slots | read and write terminal result fields |

## Canonical tree

```text
liveData/smartGrow01
├── sensors
│   ├── environmentTemp: number
│   ├── humidity: number
│   ├── co2: number
│   ├── waterLevel: number
│   └── humidifierTemp: number
├── sensorStatus
│   └── {environmentTemp|humidity|co2|waterLevel|humidifierTemp}
│       ├── valid: boolean
│       └── updatedAt: number
├── components
│   ├── humidifier: boolean
│   ├── ventFan: boolean
│   ├── baseFan: boolean
│   ├── refillPump: boolean
│   ├── loopPump: boolean
│   └── uvLight: boolean
├── automation
│   ├── mode: "automatic" | "manual"
│   └── refillPumpMode: "automatic" | "manual"
└── device
    ├── online: boolean
    ├── lastHeartbeat: number
    └── bootId: string

deviceCommands/smartGrow01
├── humidifier
├── ventFan
├── baseFan
├── refillPump
├── refillPumpMode
├── loopPump
├── uvLight
└── automationMode
```

`sensors/*` retains the last valid numeric reading. RTDB null deletes a node,
so sensor availability is instead represented by the corresponding
`sensorStatus/*` object. Flutter displays a numeric reading only when its
status is valid and fresh; invalid and stale readings must be labelled as
such, never converted to zero.

`components/*` means the output currently applied by the ESP32 controller. It
does not claim feedback-verified physical actuator performance.

`components/refillPump` is the applied pump output. `automation/refillPumpMode`
is its control policy; this deliberately replaces the old mixed string field.

## Command slot contract

Each listed target has exactly one command slot. Flutter writes the complete
object in one RTDB `set()` operation; it must not create the fields through
separate child writes.

```json
{
  "commandId": "550e8400-e29b-41d4-a716-446655440000",
  "desiredValue": true,
  "issuedAt": { ".sv": "timestamp" },
  "ttlMs": 5000,
  "status": "pending"
}
```

| Field | Type / valid values | Initial writer | Terminal writer | Purpose |
| --- | --- | --- | --- | --- |
| `commandId` | globally unique UUID string | Flutter | neither | Duplicate detection |
| `desiredValue` | boolean, or `"automatic"` / `"manual"` | Flutter | neither | Absolute requested state; never toggle |
| `issuedAt` | Firebase server timestamp, then number | Flutter request / Firebase server | neither | Trusted issue time |
| `ttlMs` | integer `5000` | Flutter | neither | Five-second validity window |
| `status` | `pending`, `applied`, `failed` | Flutter (`pending`) | ESP32 | Command lifecycle |
| `processedAt` | server timestamp/number | — | ESP32 | Optional terminal processing time |
| `processedByBootId` | string | — | ESP32 | Optional processing boot identity |
| `errorCode` | `expired`, `invalid_value`, `invalid_target`, `automatic_mode_active`, `hardware_apply_failed`, or `device_not_ready` | — | ESP32 | Optional failure reason |

ESP32 processes only a complete, valid command where `status == pending`,
`issuedAt` has resolved to a numeric timestamp, and trusted current time is no
later than `issuedAt + ttlMs`. Trusted time must come from NTP or Firebase
server-time offset, never solely from `millis()` across restarts.

Commands are idempotent, absolute set operations. ESP32 keeps the most recent
processed `commandId` per target in RAM and does not execute it twice. A reboot
may safely reapply an absolute state if output application happened before the
terminal update; no persistent command history is required.

Flutter may not replace an objectively pending, unexpired slot. It disables
only the affected control. It may replace that slot after `applied`, `failed`,
or five-second TTL plus a two-second grace period. Rapid same-target input is
not queued: ON/OFF/ON accepts the first command and ignores/disables later taps
until safe unlock. Commands for different targets may proceed independently.

ESP32 writes the applied controller state to `liveData` and then marks the
command `applied`. On a rejection or failure it marks the command `failed` and
uses one fixed `errorCode`.

## Automation and availability

Direct component commands are rejected when
`liveData/smartGrow01/automation/mode == "automatic"`. Flutter enables direct
actuator controls only after the ESP32 reports `mode == "manual"`. No exception
exists unless it is explicitly documented in firmware requirements.

ESP32 generates `device/bootId` once per boot, sets `device/online` after it
connects/authenticates, and updates `device/lastHeartbeat` every 15 seconds.
Flutter considers the device operational only when heartbeat age is at most 45
seconds; `online` is a connection hint, not the deciding signal. On reconnect,
ESP32 republishes current state and processes only unexpired commands.

## Security boundary

Authenticated Flutter users may read `liveData` and create complete pending
command slots. They cannot write telemetry, components, automation, device
state, or terminal command fields. The device identity may read only its own
commands and write only its own live data and terminal command fields. Public
writes, database secrets, and administrator credentials in firmware are
prohibited.

RTDB rules must be implemented only after the selected ESP32 Firebase library
can securely authenticate the dedicated device account and expose device
identity claims.
