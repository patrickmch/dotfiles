Can do without approval: Read files, search code, run tests, build projects, analyze data, create/edit CLAUDE.md and PROGRESS.md, run git status/diff/log, create branches and commits (when asked).

Needs user approval: All Google Calendar modifications. All GitHub writes (comments, issues, PR actions, board moves). Sending emails or SMS. Stripe operations (invoice.py send without --draft). Any destructive git operations (force push, reset --hard). Deploying to production. Deleting files or directories. SSH write operations on turtle.

For multi-step tasks, use Plan > Execute > Review pattern. Write an eval before the plan. Present PAUSE points before external actions.
