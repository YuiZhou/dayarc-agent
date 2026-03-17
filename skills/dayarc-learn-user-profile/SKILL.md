---
name: Learn User Profile
description: Update the user's daily profile by learning from outgoing signals.
---

## Input
Outgoing signals (sent emails, Teams messages sent, commits, PRs authored), previous daily profile (or empty on bootstrap).

## Output
Updated DailyProfile JSON — see memory-schemas.md for exact schema.

## Instructions
1. Read previous profile (if exists).
2. For each outgoing signal, extract topics, contacts, threads.
3. Update focus_areas: bump confidence + last_seen for matches, add new at 0.5, decay unseen by -0.1 (remove if <0.1).
4. Update learning_interests: detect topics from content (blog links, docs, exploratory code), set trajectory.
5. Update key_contacts: increment interaction_count for people in today's signals.
6. Update active_threads: add new, update status, increment days_open.
7. Set priorities_today from infer_priorities output.
8. Set unfinished from items lacking completion signal. Each must have source_breadcrumb.
9. Bootstrap: if no previous profile, build fresh from today's signals.
10. VALIDATE output against memory-schemas.md before returning.
