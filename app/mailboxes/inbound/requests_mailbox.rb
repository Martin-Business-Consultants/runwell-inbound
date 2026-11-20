module Inbound
  # Every email to the requests address (Runwell hands this plugin all its mail, Runwell::Plugins.receive_mail).
  #
  # - A message already seen (by its Message-ID) is dropped: delivered twice, it still makes one request.
  # - A reply in the thread of an open request (In-Reply-To or References naming a message in it,
  #   Inbound::Message) becomes a note on that request, not a new one.
  # - Anything else is a new request: work nobody has taken on yet, in Intake, on the sender's client
  #   when their address matches a contact (else none until someone picks one). The subject is its
  #   title, the body its description, cleaned of quoted mail and signatures (EmailBody), and
  #   attachments its documents. A known contact gets a short acknowledgement, threaded under
  #   their message, whose replies come back here too.
  #
  # Automatic replies and our own mail are dropped.
  class RequestsMailbox < ::ApplicationMailbox
    def process
      return if automatic? || from_ourselves? || Message.seen?(mail.message_id)

      Current.set(source: "email") do
        if (request = Message.request_answered_by(mail))
          add_reply(request)
        else
          receive_request
        end
      end
    end

    private
      def sender_email = mail.from_address&.address.to_s.downcase
      def sender_name = mail.from_address&.display_name.presence || mail[:from]&.display_names&.first.presence
      def body = @body ||= EmailBody.new(mail)

      def receive_request
        request = ::Task.create!(title: title, description: body.to_html, sender_name: sender_name, sender_email: sender_email,
                                 source: "email", created_at: mail.date || Time.current, requested: true)
        Message.record!(mail.message_id, task: request, direction: "in")
        attach_files(request)

        if request.contact && Setting.requests_email.present?
          RequestMailer.with(task: request, in_reply_to: mail.message_id).received.deliver_later
        end
      end

      # A reply on the request's notes, from the contact when we know them, with its files.
      def add_reply(request)
        contact = ::Contact.find_by(email: sender_email)
        text = body.to_html.presence || "<p>(No message, only attachments.)</p>"
        request.notes.create!(body: text, kind: "email", source: "email", author: contact, occurred_at: mail.date || Time.current)
        Message.record!(mail.message_id, task: request, direction: "in")
        attach_files(request)
      end

      # Files the sender attached, as the request's documents (internal until someone shares them).
      # Pictures inline in the message (signature logos) are skipped, and so is a file over the limit.
      def attach_files(request)
        mail.attachments.reject(&:inline?).filter_map do |attachment|
          document = request.documents.new(file: { io: StringIO.new(attachment.decoded), filename: attachment.filename, content_type: attachment.mime_type })
          document if document.save
        end
      end

      def title
        subject = mail.subject.to_s.sub(/\A(\s*(re|fwd?|aw|sv)\s*:\s*)+/i, "").squish
        (subject.presence || "Email from #{sender_name || sender_email}").truncate(200)
      end

      # Out-of-office and other machine replies say so in their headers (RFC 3834 and the usual
      # vendor ones); bounces come from the mail system.
      def automatic?
        submitted = mail["Auto-Submitted"]&.value.to_s.downcase
        precedence = mail["Precedence"]&.value.to_s.downcase

        (submitted.present? && submitted != "no") || mail["X-Autoreply"].present? || mail["X-Autorespond"].present? ||
          %w[bulk junk list auto_reply].include?(precedence) || mail["X-Auto-Response-Suppress"]&.value.to_s.match?(/\b(all|oof|autoreply)\b/i) ||
          sender_email.blank? || sender_email.match?(/\A(mailer-daemon|postmaster)@/)
      end

      # Our own mail, looping back through the requests address.
      def from_ourselves?
        ours = [ ::Mail::Address.new(::Setting.current.mail_sender).address, Setting.requests_email ].compact.map(&:downcase)
        ours.include?(sender_email)
      end
  end
end
