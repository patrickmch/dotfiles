---
name: schedule-task
description: Use when you need to fire a one-shot task (send email, post, API call, scrape) at a specific future datetime — minutes to a few days out — on an always-on host. Covers the self-contained Python + nohup + disown pattern, launch/verify/cancel commands, timezone discipline, and when to graduate to a launchd/cron job. Use when no native scheduling tool is available in the current runtime, or when you want the schedule under version control.
---

# schedule-task

Schedule a one-shot future task on an always-on host using a self-contained Python script + `nohup` + `disown`. Model-agnostic. The script sleeps until a target datetime, does the work, exits.

## When to use

- One-shot, bounded task (no daemon)
- Target time is minutes to a few days away
- Always-on host available (e.g. an always-on Mac/Linux server)
- Examples: scheduled email blast, day-of nudge, time-boxed API call, deferred post, future scrape

## When NOT to use

- Recurring task → use cron or launchd
- Multi-day delay where host might reboot → use launchd one-shot plist
- Sub-minute precision required → `time.sleep()` drifts under load
- Long-running daemon or task that needs supervision → launchd
- A native scheduling/queue tool exists in your runtime and is durable → prefer it

## Runtime check first

Before reaching for the Python fallback, check whether your runtime exposes a native scheduler:

- Cron-style tool (e.g. `CronCreate`)
- Queue/send-at tool (e.g. a Telegram scheduled-message tool, a project queue)
- Workflow scheduler in the project (e.g. a launchd one-shot helper)

If a durable native tool exists, use it. The Python pattern below is the fallback when no such tool exists, when you want the schedule under version control, or when the work is a one-off that does not deserve a recurring job.

## The pattern

A self-contained Python script:

1. Defines `TARGET` as a timezone-aware datetime
2. On start, computes delay and logs target + delay
3. Supports `--dry-run` (verify and exit) and `--run-now` (skip the sleep)
4. Sleeps until target, then runs `do_work()`, then exits

Launch detached so it survives terminal close.

## Reference script

```python
#!/usr/bin/env python3
"""One-shot: <what this does> at <target datetime>."""
import sys
import time
from datetime import datetime, timezone, timedelta

# Target time with explicit timezone — naive datetimes + DST is a footgun.
# Example: 4:03 PM MDT (UTC-6) on 2026-05-21
TARGET = datetime(2026, 5, 21, 16, 3, 0, tzinfo=timezone(timedelta(hours=-6)))


def do_work():
    """Replace with the actual one-shot work.

    Common shapes:
      - SMTP send (load credentials from a config file, smtplib.SMTP_SSL)
      - HTTPS POST (requests.post with bearer token from env)
      - Subprocess invocation (subprocess.run with a project CLI)
    Log progress with print(..., flush=True) so nohup logs are useful.
    """
    print("did the thing", flush=True)


def main():
    now = datetime.now(timezone.utc)
    delay = (TARGET - now).total_seconds()
    print(
        f"[{datetime.now().isoformat()}] target={TARGET.isoformat()} "
        f"delay={delay:.0f}s ({delay/60:.1f} min)",
        flush=True,
    )

    if "--dry-run" in sys.argv:
        print("DRY RUN — would fire at target", flush=True)
        return

    if "--run-now" not in sys.argv and delay > 0:
        time.sleep(delay)

    print(f"[{datetime.now().isoformat()}] firing", flush=True)
    do_work()
    print(f"[{datetime.now().isoformat()}] done", flush=True)


if __name__ == "__main__":
    main()
```

## Launch (detached)

```bash
# Optional dry-run to verify target + delay before committing
python3 /path/to/your-script.py --dry-run

# Launch the real scheduled run
nohup python3 /path/to/your-script.py > /tmp/your-job.log 2>&1 &
disown $!
echo "PID=$!"   # capture immediately — it scrolls fast
```

If you are launching on a remote host via SSH, wrap the `nohup ...` line in `ssh host "..."`. Do NOT skip `disown` — without it, hanging up the SSH connection can kill the child on some systems.

## Verify

```bash
# Is the process alive?
ps -p <PID> -o pid,etime,command

# Has it logged anything yet?
tail -5 /tmp/your-job.log
```

The first log line shows the target time and delay at launch. After fire, the script logs the result (e.g. SMTP refused recipients, HTTP status, etc.) — read it after fire time.

## Cancel before fire

```bash
kill <PID>
```

## Fire now (bypass the sleep)

If you scheduled too far in advance or a session restart killed the original process, relaunch with `--run-now`:

```bash
nohup python3 /path/to/your-script.py --run-now > /tmp/your-job.log 2>&1 &
disown $!
```

## Gotchas

- **Host reboot kills the process.** Acceptable for "always-on" hosts on hour/day scales; for multi-day delays prefer a launchd one-shot plist (macOS) or systemd timer one-shot (Linux).
- **Timezones.** Always pass `tzinfo` on `TARGET`. Naive datetimes silently shift across DST boundaries.
- **PID capture.** `$!` is only set right after the background launch. Capture it on the same line; do not assume you can recover it later from `ps`.
- **Logs are your only audit trail.** Print at start (target/delay), at fire, and at completion (with per-recipient/per-request results).
- **External-content review.** If the work sends user-visible text (email, DM, post), run the body through your text-review process BEFORE launch, not after the sleep starts.
- **Recipient/payload data drift.** If the task reads from a CRM or sheet, re-pull right before launch — stale data is the most common post-mortem cause.
- **Credentials.** Read from a config file or env at fire time, not at launch — if creds rotate during the delay, the script picks up the new ones.

## When to graduate

If you write 2-3 of these per week with the same shape, build a proper recurring scheduler:

- macOS: launchd `StartCalendarInterval` plist
- Linux: systemd timer or cron
- Project-internal: a queue/worker that handles retry + observability

The one-shot Python pattern is good for ad-hoc and rare events. It is not the right home for a weekly digest.

## Worked example: scheduled email broadcast

Project mtropro (`~/projects/clients/mtropro/`) has a worked email-broadcast variant of this pattern at `docs/runbook-scheduled-email-broadcast.md`, including loading SMTP credentials from the email config file and handling BCC privacy. Use it as a reference if the one-shot task is "send email at time X".

## Red flags

- "Just sleep, no logging" → you will not know what happened. Always log target, fire, result.
- "I'll capture the PID later" → no, capture on the launch line.
- "Naive datetime, it'll be fine" → it will not be fine across DST.
- "No dry-run, just launch it" → dry-run takes 2 seconds and catches timezone errors and delay-sign bugs.
