module Inbound
  # Where requests are emailed (requests_email) and how mail reaches Runwell: the service forwarding
  # that address here (ingress) and the password it signs in with. One row. The server's environment
  # wins over what's saved, as it did in the core: INBOUND_EMAIL_INGRESS, and the password from
  # credentials (action_mailbox.ingress_password) or RAILS_INBOUND_EMAIL_PASSWORD.
  class Setting < ApplicationRecord
    self.table_name = "inbound_settings"

    INGRESSES = { relay: "a relay (Cloudflare Email Routing or your own mail server)", postmark: "Postmark",
                  sendgrid: "SendGrid", mailgun: "Mailgun", mandrill: "Mandrill" }.freeze

    encrypts :password

    normalizes :requests_email, with: ->(value) { value.to_s.strip.downcase.presence }
    normalizes :ingress, with: ->(value) { value.to_s.strip.presence }
    validates :requests_email, format: { with: URI::MailTo::EMAIL_REGEXP, message: "should be an email address" }, allow_nil: true
    validates :ingress, inclusion: { in: INGRESSES.keys.map(&:to_s) }, allow_nil: true

    def self.current = first_or_create!

    def self.requests_email = current.requests_email

    def self.ingress = environment_ingress || current.ingress&.to_sym
    def self.ingress_from_environment? = environment_ingress.present?
    def self.environment_ingress = ENV["INBOUND_EMAIL_INGRESS"].presence&.to_sym

    def self.password
      Rails.application.credentials.dig(:action_mailbox, :ingress_password).presence ||
        ENV["RAILS_INBOUND_EMAIL_PASSWORD"].presence || current.password.presence
    end

    def self.password_from_environment?
      Rails.application.credentials.dig(:action_mailbox, :ingress_password).present? || ENV["RAILS_INBOUND_EMAIL_PASSWORD"].present?
    end

    # Receive through a service (unless the environment names one), with a password made for it the
    # first time. Answers the password, for whatever forwards the mail. Plugins that set a service up
    # (Cloudflare) call this.
    def self.receive_through!(ingress)
      current.update!(ingress: ingress.to_s, password: current.password.presence || SecureRandom.hex(32))
      password
    end

    def self.stop_receiving! = current.update!(ingress: nil)
  end
end
