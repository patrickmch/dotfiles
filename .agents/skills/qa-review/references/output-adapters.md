# Output Adapters

Local markdown is the default and requires only filesystem access.

## Local Markdown

- Write to `<artifact-root>/.reviews/` when possible.
- Create the directory if the artifact root is writable.
- If not writable, use project `.reviews/`.

## Google Docs Optional Adapter

Use only when all are true:

1. The user asks for Google Docs output or the project explicitly requires it.
2. Google Docs/Drive tools are available in the current runtime.
3. The user has approved any external creation, sharing, or comment action.

When using Google Docs, still keep or create the local markdown review first. The Google Doc is a publication adapter, not the canonical artifact.

## Other External Adapters

For tickets, comments, Slack, email, or project boards, draft the exact content and ask before posting unless the user explicitly requested that exact external action in the current turn.
