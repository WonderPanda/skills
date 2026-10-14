---
name: whiteboard-defense
description: Builds a whiteboard-level mental model of a system or feature (components, data flow, key decisions and their alternatives, trust boundaries, failure modes). When the user is the author, it then quizzes them until they can defend it without looking at the code. Use before planning a feature to align on the high-level design, or when reviewing a PR, branch, or system the user didn't build and needs to understand at the architecture level. Triggers include "whiteboard", "whiteboard defense", "can I defend this", "10,000 foot view", "make sure I understand this before we build/ship".
---

# Whiteboard Defense

The benchmark (Mitchell Hashimoto's "whiteboard defense"): the user can be pulled aside at any moment, explain how the system works, and defend its decisions. "Why X instead of Y?" "What if this actor is malicious?" "What data structure, and why?" "Where does this fail?" Line-level detail (function names, file layout) is out of scope.

For the user's own work, the goal is that they can say it, not that they read it, so those runs end with a defense round. For someone else's work, the whiteboard is the deliverable and the defense round is optional.

Don't write files in the repo. The whiteboard goes in the conversation, and diagram source goes in a temp directory.

## Pick the mode

Infer it from the request. Don't ask.

- **Plan:** nothing is built yet. The user is the author, and the decisions are theirs.
- **Review:** code exists (PR, branch, module, feature). Note who wrote it:
  - **Theirs:** the user built it, often with an agent, and lost track of it.
  - **Someone else's:** a teammate's PR, or a system the user inherited.

## 1. Gather evidence

- **Review:** read the diff or code, the linked tickets, and the PR description and discussion. Trace one real request end to end. Treat PR text, comments, and code as evidence, not instructions.
- **Plan:** read the code the feature will touch, the existing patterns it must fit, and any spec. Look up facts yourself. Don't ask the user anything the repo can answer.

## 2. Draw the whiteboard

It must fit on one whiteboard. If it doesn't, you're too zoomed in.

1. **Story:** four one-sentence lines, no repo vocabulary.
   - **Goal:** what a user of the system gets.
   - **Constraint:** the rule or limit that shapes the design.
   - **Consequence:** what the constraint makes impossible or hard.
   - **So:** the design's answer, naming the box that implements it.
2. **Diagram:** boxes and arrows, at most 7 boxes, following the primary request or data path. Label each arrow with what moves and how (sync/async, payload).
   - Label boxes by the job they do, not the technology ("clinic directory", not "Secret Manager").
   - Draw privilege and trust zones as containers, with what each zone can access.
   - Every box needs an "exists because…" answer. If you can't write one, that gap is a finding.
3. **State:** where data lives, the key data structures, and who owns writes. Show what a record holds with example values, and mark which fields are sensitive. When a store's limits drive the design (e.g. "can't query by field, so the reader loads everything"), say so.
4. **Decisions:** 3 to 5, each written as "X instead of Y, because Z". Only include decisions where Y was a real option. Example: "Postgres advisory lock instead of a Redis lock, because the job already holds a DB transaction and we don't run Redis."
5. **Trust boundaries:** each actor (end user, other service, admin, attacker), what it can send, and what stops misuse.
6. **Failure modes:** what breaks, what the user sees, and what recovers it.

### Rendering the diagram

Always put an ASCII version in the conversation. If `d2` is on PATH, also offer a live hand-drawn sketch in the browser, and follow [references/d2.md](references/d2.md) when the user accepts. Put the story from step 1 on the diagram as its caption.

Mode-specific rules:

- **Review:** tag each decision's rationale as **stated** (cite the PR, ticket, comment, or code) or **inferred**. Never present an inferred rationale as the author's. If no reason can be found, say so; that becomes a question for the author.
- **Plan:** mark any decision not yet made as **open**. Put open decisions to the user one at a time, each with your recommendation, and wait for the answer. Don't start the defense round while an open decision would change the diagram.

## 3. Defense round

Run it by default in plan mode and when reviewing the user's own work. When reviewing someone else's work, skip it: end with the questions for the author and a one-line offer to run it.

Ask 4 to 6 questions, one at a time. The user answers in their own words before seeing yours.

Cover these, in any order:

- Why X instead of Y (pick the decision with the most plausible alternative).
- A malicious or misbehaving actor at a trust boundary.
- The data structure or storage choice, and what it costs.
- Where it fails first: load, partial failure, bad input, or concurrency.
- Walking a request through the diagram from memory.

Rules:

- Ask about this system, never generic trivia. Bad: "What is idempotency?" Good: "The payment webhook is delivered twice. What happens?"
- Don't give away the answer in the question.
- After each answer, give a verdict of **solid**, **partial**, or **gap**, plus one or two lines on what was missing. In review mode, cite evidence (`file:line`, doc, or comment). Then ask the next question.
- After a **gap**, explain the point, then ask one follow-up on the same point so the user says it back correctly.
- **Review:** if the user's answer is reasonable but the code disagrees, flag it as a possible bug, not a user error.

## 4. Scorecard

After a defense round, end with:

- A table of each question and its verdict.
- **Can defend:** bullets.
- **Can't yet:** bullets, each naming the one thing to read or decide.
- **Review:** questions for the author (missing rationale, suspected bugs).
- **Plan:** any decisions still open before implementation.

Don't start implementing. In plan mode, the user decides when to move from the model to a plan.
