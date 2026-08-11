# Smart Grow RTDB Contract v1.0

## Ownership

RTDB is the live communication layer. Flutter reads reported state and creates
commands. The ESP32 applies hardware changes, publishes actual controller
state, and advances command status. Firestore remains history/analytics only.

Canonical device ID: `smartGrow01`.

## Live state

`liveData/smartGrow01` contains:

- `sensors/{environmentTemp,humidity,co2,waterLevel,humidifierTemp}`: numbers
- `components/{humidifier,uvLight,ventFan,baseFan,loopPump}`: booleans
- `components/refillPump`: `{mode,running,reason,startedAt,lastChangedAt,fault}`
- `componentStatus/{humidifier,uvLight,ventFan,baseFan,loopPump}`:
  `{updatedAt,fault}`
- `device`: `{online,lastHeartbeat,bootId,firmwareVersion}`

Refill `mode` is `auto`, `on`, or `off`. `running` is independent of mode.
Reason is an extensible non-empty string and fault is nullable.

Flutter considers the ESP32 connected only when `online == true` and
`lastHeartbeat` is no more than 45 seconds old. The UI re-evaluates this even
when no new RTDB event arrives.

## Commands

The only command slots are:

`deviceCommands/smartGrow01/components/{humidifier|uvLight|ventFan|refillPump}`

Boolean desired values are used for humidifier, UV light, and vent fan. Refill
uses `{ "mode": "auto|on|off" }`.

```json
{
  "commandId": "uuid",
  "requestedBy": "firebase-auth-uid",
  "issuedAt": 0,
  "ttlMs": 30000,
  "status": "pending",
  "desired": true,
  "lastError": null
}
```

ESP32 advances `pending` to `ack`, then `applied`, `rejected`, or `expired`.
`ack` remains in progress. Flutter locks only that command slot and never uses
the command payload as displayed hardware state. ESP32 must publish live state
and then mark a successful command `applied`.

Base fan and loop pump are status-only. Flutter never commands them and never
synthesizes their values from humidifier state. ESP32 owns the humidifier,
loop-pump, and base-fan dependency behavior.

## Security deployment note

The checked-in rules permit authenticated app users to read live data and
create strictly validated pending commands for the four targets. They keep
live-data writes denied to app users. The ESP32/controller must use the
project's dedicated trusted identity or an Admin-SDK bridge that can publish
live state and terminal command updates. Do not grant arbitrary authenticated
users those controller permissions. If the selected ESP32 library does not
support a securely distinguishable device claim, add a trusted bridge before
hardware deployment rather than weakening these rules.
