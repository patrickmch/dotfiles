---
name: google-workspace
description: Use for tasks involving Gmail, Google Calendar, Google Drive, Google Docs, Google Contacts, or Google Tasks through whatever Google Workspace tools the current agent runtime exposes. Use when the user asks to triage email, draft a Gmail reply, search Drive, inspect calendar events, manage contacts, manage tasks, or run workspace-hub workflows.
---

# Google Workspace

Use this skill when the task is about Google Workspace data or actions.

## Preconditions

1. Check whether Google Workspace tools are available in the current runtime before using them.
2. Prefer native app/MCP tools when present. Examples include Gmail search/read/thread tools, Calendar event tools, Drive/Docs read tools, Contacts tools, and Tasks tools.
3. If no Workspace tools are available, say so briefly and fall back only to local project/workflow docs that are available on disk.
4. Treat external writes as approval-gated even when a tool exists.

## Safety Rules

- Read-only actions are fine: search Gmail, read messages, read threads, list calendars, get events, search Drive, read docs, list contacts, and list tasks.
- Ask before any external or mutating action: sending Gmail, changing labels, creating or editing events, changing Drive sharing, creating comments, creating or editing contacts, or completing/creating tasks unless the user clearly asked for that exact action.
- Surface the exact draft, event change, contact edit, sharing change, or task mutation before executing it when the action affects someone else or changes remote state.

## Workflow

1. Identify the Workspace surface: Gmail, Calendar, Drive, Docs, Contacts, or Tasks.
2. Verify the matching tool family exists in this runtime.
3. If the task matches an existing local workflow, read the relevant file in `~/code/workspace-hub/workflows/` if available.
4. Use structured tool results over ad hoc text parsing where possible.
5. Summarize findings clearly, including message subjects, event dates, file names, or contact names as appropriate.
6. Pause for approval before any write action.

## Workflow References

Read these only when relevant and only if the files exist:

- Email triage or inbox work: `~/code/workspace-hub/workflows/email-triage.md`
- Email autopilot or project filing: `~/code/workspace-hub/workflows/email-autopilot.md`
- Calendar work: `~/code/workspace-hub/workflows/calendar-management.md`
- Transcript or Drive filing: `~/code/workspace-hub/workflows/transcript-filing.md`
- Contacts: `~/code/workspace-hub/workflows/contacts.md`
- Tax document search: `~/code/workspace-hub/workflows/tax-documents.md`
- Invoicing with calendar context: `~/code/workspace-hub/workflows/invoicing.md`

## Tool Families To Look For

Tool names vary by agent, connector, and MCP server. Look for equivalent capabilities rather than a specific prefix:

- Gmail: search messages, read message content, read thread content, read attachments, draft message, send message
- Calendar: list calendars, get events, query free/busy, manage event
- Drive/Docs: search files, read Docs as markdown/text, inspect permissions, manage sharing
- Contacts: list/search/get contacts and contact groups, manage contacts
- Tasks: list task lists, list/get/manage tasks
