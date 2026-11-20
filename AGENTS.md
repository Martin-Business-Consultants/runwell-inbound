# Requests by email — guide for AI agents

The inbound plugin for Runwell (a Rails 8.1 engine, key `inbound`, module `Inbound`): mail to the
requests address becomes a request in Intake. Not an app on its own: run it from a Runwell checkout
with `bin/rails "plugins:link[../runwell-inbound]"`, `bin/rails db:migrate`, restart, and switch it
on in Settings › Plugins.

Read first, in Runwell's repository: `docs/plugin-contract.md` (Email: `Runwell::Plugins.receive_mail`
and requests from outside, 7.0) and `AGENTS.md` (the core's conventions, which this code follows).

## How it works

- The engine registers `receive_mail :inbound, mailbox: "Inbound::RequestsMailbox"`, with the service
  and password read per request from `Inbound::Setting` (the environment wins), so a change needs no restart.
- `Inbound::RequestsMailbox#process`: drops automatic replies, our own mail and any Message-ID already
  seen (`Inbound::Message.seen?`); a reply in an open request's thread (`Message.request_answered_by`)
  becomes a note (`kind: "email"`, authored by the contact when known); anything else is
  `Task.create!(…, source: "email", requested: true)`, which the core puts in Intake.
- `Inbound::Message` keeps every Message-ID in a request's thread: what came in, and the
  acknowledgement `Inbound::RequestMailer#received` sends (with a Message-ID of its own and the
  requests address as Reply-To), so replies to it find the request.
- `Inbound::EmailBody` cuts quoted mail and signatures (it was the core's `Task::EmailBody`).
- Settings › Requests by email (`Inbound::SettingsController`, `ServicesController`; tools
  `show_email_requests`, `update_email_requests`; choosing the service is browser-only since it shows
  a password). It draws the `:email_inbound` slot for plugins that set a service up.
- The portal footer's `:portal_footer` slot adds ", or email <address>".

## Rules

- Tables `inbound_*`; the first migration copies the core's pre-7.0 settings (`requests_email`,
  `inbound_ingress`, `inbound_password`) through `::Setting` so the password decrypts.
- Controllers declare an agent tool or `browser_only` per action, and 404 while the plugin is off.
- Only gems Runwell bundles. Write for anyone running something, never one industry's jargon.

## Release

Bump `lib/inbound/version.rb`, commit, then `git tag v0.1.0 && git push origin main v0.1.0`; the
workflow publishes the release, which installs see in Settings › Plugins.
