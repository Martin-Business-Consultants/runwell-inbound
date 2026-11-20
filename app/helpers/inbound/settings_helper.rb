module Inbound
  module SettingsHelper
    def inbound_ingress_name(ingress) = Setting::INGRESSES.fetch(ingress.to_sym, ingress.to_s)

    # The URL the service posts mail to. Postmark, SendGrid and a relay sign in with the password
    # as the actionmailbox user; Mailgun and Mandrill sign each delivery with their own key.
    def inbound_ingress_url(ingress)
      case ingress.to_sym
      when :postmark then main_app.rails_postmark_inbound_emails_url.sub("://", "://actionmailbox:PASSWORD@")
      when :sendgrid then main_app.rails_sendgrid_inbound_emails_url.sub("://", "://actionmailbox:PASSWORD@")
      when :relay then main_app.rails_relay_inbound_emails_url.sub("://", "://actionmailbox:PASSWORD@")
      when :mailgun then main_app.rails_mailgun_inbound_emails_mime_url
      when :mandrill then main_app.rails_mandrill_inbound_emails_url
      else ""
      end
    end

    def inbound_ingress_secret_hint(ingress)
      case ingress.to_sym
      when :mailgun then "Mailgun signs each delivery: set MAILGUN_INGRESS_SIGNING_KEY to its webhook signing key."
      when :mandrill then "Mandrill signs each delivery: set MANDRILL_INGRESS_API_KEY to its API key."
      else Setting.password_from_environment? ? "PASSWORD is RAILS_INBOUND_EMAIL_PASSWORD from the server’s environment." : "PASSWORD is the password below."
      end
    end
  end
end
