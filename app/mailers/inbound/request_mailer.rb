module Inbound
  # Tells a contact who emailed a request that it came in, threaded under their message. It goes
  # out with a Message-ID of its own, kept on the request (Inbound::Message), so a reply to it lands
  # on the same request as a note. Reply-To is the requests address when there is one.
  class RequestMailer < ::ApplicationMailer
    def received
      @request = params[:task]
      headers["Auto-Submitted"] = "auto-replied"
      if params[:in_reply_to].present?
        headers["In-Reply-To"] = "<#{params[:in_reply_to]}>"
        headers["References"] = "<#{params[:in_reply_to]}>"
      end
      message_id = "inbound-#{@request.id}-#{SecureRandom.hex(8)}@#{Runwell.host.split(":").first}"
      headers["Message-ID"] = "<#{message_id}>"
      Message.record!(message_id, task: @request, direction: "out")

      mail to: email_address_with_name(@request.sender_email, @request.requester_name),
           reply_to: Setting.requests_email.presence,
           subject: "Re: #{@request.title}"
    end
  end
end
