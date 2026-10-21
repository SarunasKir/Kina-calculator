# Wi-Fi sync

The PC app is the hub. Phones pair with it once and then exchange changes over
the local network. Nothing goes through the internet and no server is hosted.

## Pairing

1. On the PC, More → switch on "Let phones sync with this PC" → "Add a phone".
   The hub makes a pairing code (shown as a QR code and as text) holding its id,
   its local addresses, its port and a one-time secret. The code works once and
   expires after 10 minutes.
2. On the phone, More → paste the code → "Pair with PC".
3. The phone sends a message encrypted with the one-time secret. The hub checks
   it, creates a new random 256-bit key for that phone, sends it back encrypted
   with the same secret, and forgets the secret. Both sides keep the key; the
   hub also keeps the phone's id and name. Removing the phone on the PC deletes
   its key, so it can no longer sync.

## Syncing

A sync is one request. The phone sends the records that changed since its last
sync and the hub's time of its last answer; the hub stores the ones that are
newer than its own copy and answers with the records that changed since then.

- **Encryption and authentication:** every message is AES-256-GCM sealed with
  the phone's key, bound to the phone's id and to the kind of message, with a
  timestamp that the hub rejects when it is more than 10 minutes from its own
  clock. The transport is plain HTTP on the local network; the payload is what
  is protected. A device on the same Wi-Fi sees only ciphertext and cannot
  forge a message without the key.
- **Records:** every synced table has `id`, `updated_at` and `deleted`. The
  synced tables are settings, profiles, snapshots and journal entries.
  Pairing keys live in a separate table that is never synced.
- **Merge:** last write wins by `updated_at`. Equal or older incoming records
  are ignored, so applying the same records twice changes nothing. Deletions
  are records with `deleted = 1`, so they sync too. Snapshots and journal
  entries are only ever added or deleted, so they do not conflict.
- **Safety:** incoming records must name known tables and exactly the columns
  of the table, and are applied in one transaction: a bad record rejects the
  whole message.
- **Clocks:** last-write-wins trusts both devices' clocks. If they differ by
  more than 10 minutes the sync is refused with a message telling the user so.

## Finding the hub again

The pairing code carries the hub's addresses. If the hub's address changes
(the router hands out a new one), the phone broadcasts a UDP question on port
47822 and the hub answers with its id and port. The phone remembers the new
address.

## Ports

| Port | Protocol | Used for |
| --- | --- | --- |
| 47821 | TCP | Sync server on the PC |
| 47822 | UDP | "Where are you" discovery on the PC |

Windows asks to allow the app through its firewall the first time the hub
starts.

## Not yet

- Scanning the QR code with the phone camera; for now the phone pastes the
  code text.
- Sync away from home (for example through a cloud folder).
