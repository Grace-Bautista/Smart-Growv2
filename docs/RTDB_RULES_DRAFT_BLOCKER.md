# RTDB rules draft status

`database.rules.json` intentionally denies all access. It is a safe placeholder,
not the final Smart Grow rule set.

Final RTDB rules require a confirmed device identity that can be represented in
RTDB Auth tokens. The repository does not currently issue the required device
custom claims and the available ESP32 demo firmware has no authenticated
Firebase library configuration. Rules cannot safely distinguish Flutter command
creation from ESP32 live-data and terminal-command writes until that is solved.

Do not deploy permissive rules as a workaround. Once the device authentication
method is confirmed, replace the deny-all draft with rules that validate command
targets and desired value types, permit authenticated Flutter users to create
only `pending` command slots, and restrict live-data/terminal writes to the
matching device identity.
