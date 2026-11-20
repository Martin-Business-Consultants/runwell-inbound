module Inbound
  # Requests by email (README.md): mail to an address of yours becomes a request in Intake, a
  # reply lands on the request it answers, and the same message never makes two. It owns its tables
  # (inbound_settings, inbound_messages), points at core records by id, and reaches the core only
  # through the plugin contract (docs/plugin-contract.md in Runwell, 7.0: receive_mail). Remove it
  # and Runwell runs as before, receiving no mail.
  class Engine < ::Rails::Engine
    initializer "inbound.routes" do |app|
      app.routes.append do
        scope "settings", module: "inbound", as: "inbound" do
          resource :email_requests, only: %i[show update], controller: "settings" do
            resource :service, only: :update, controller: "services"
          end
        end
      end
    end

    initializer "inbound.models" do
      ActiveSupport.on_load(:runwell_task) { has_many :inbound_messages, class_name: "Inbound::Message", dependent: :delete_all }
    end

    config.to_prepare do
      Runwell::Plugins.register :inbound, name: "Requests by email", version: Inbound::VERSION, author: "Martin Business Consultants",
        enabled_by_default: false, requires: ">= 7.0.0", homepage: "https://github.com/Martin-Business-Consultants/runwell-inbound",
        description: "Mail to an address of yours becomes a request in Intake: the subject its title, the message its description, attachments its documents. A reply lands on the request it answers, the same message never makes two, and a known contact hears it came in."
      Runwell::Plugins.receive_mail :inbound, mailbox: "Inbound::RequestsMailbox",
        ingress: -> { Inbound::Setting.ingress }, password: -> { Inbound::Setting.password }
      Runwell::Plugins.settings :inbound, "Requests by email", -> { inbound_email_requests_path }
      Runwell::Plugins.slot :portal_footer, :inbound, "inbound/slots/portal_footer"
    end
  end
end
