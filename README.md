# Requests by email, for Runwell

A [Runwell](https://github.com/Martin-Business-Consultants/runwellv2) plugin: mail to an address of
yours (say `support@yourcompany.com`) becomes a request in Intake.

- **A new email is a new request**: the subject its title, the message its description (without the
  quoted mail and signature), attachments its documents, on the sender's client when their address
  matches a contact. It comes into Intake like any request, and whoever's on Intake hears of it.
- **A reply lands on the request it answers**, as a note, when it's in the thread of an open request
  (its In-Reply-To or References name a message there). A reply to a request that's done starts a new one.
- **The same message never makes two requests**: one delivered twice (to the address and to someone
  who forwards it, or a service retrying) is seen once, by its Message-ID.
- **A known contact hears it came in**: a short acknowledgement, threaded under their message, whose
  reply comes back to the same request.
- Out-of-office and other automatic replies, bounces and Runwell's own mail are ignored.

Runwell can't receive mail on its own: a service forwards the address to it. Cloudflare Email
Routing (free; the Cloudflare plugin sets it up in one step), Postmark, Mailgun, SendGrid, Mandrill,
or your own mail server (Postfix or Exim piping into `bin/rails action_mailbox:ingress:postfix`).

## Install

Needs Runwell 7.0 or later (before 7.0 this was part of the core; an install that used it gets
this plugin, with its address and service, as it updates).

Settings › Plugins › Add a plugin: `Martin-Business-Consultants/runwell-inbound`. Switch it on, then
in **Settings › Requests by email**:

1. Set the requests address.
2. Choose the service that forwards it here. Runwell shows the URL to give the service, and makes a
   password for Postmark, SendGrid or a relay.
3. Send an email to the address to try it.

The server's environment wins over the settings page when set: `INBOUND_EMAIL_INGRESS` (`relay`,
`postmark`, `sendgrid`, `mailgun`, `mandrill`), `RAILS_INBOUND_EMAIL_PASSWORD`, and Mailgun's
`MAILGUN_INGRESS_SIGNING_KEY` or Mandrill's `MANDRILL_INGRESS_API_KEY`.

Received mail is kept 30 days, then deleted (Action Mailbox); the requests and notes made from it stay.

## For other plugins

- `Inbound::Setting.requests_email`, `Inbound::Setting.ingress`, and
  `Inbound::Setting.receive_through!(:relay)` (answers the password) for a plugin that sets a service
  up, as Cloudflare's does. Check `defined?(::Inbound::Setting)` first.
- The settings page draws the `:email_inbound` slot (no locals) under the service, for such a
  plugin's note or button.

## Develop

From a Runwell checkout beside this one: `bin/rails "plugins:link[../runwell-inbound]"`,
`bin/rails db:migrate`, `bin/dev`. `AGENTS.md` is the guide to the code.

## License

[FSL-1.1-MIT](LICENSE.md), like Runwell.
