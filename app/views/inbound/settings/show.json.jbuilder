json.summary(Inbound::Setting.ingress ? "Receiving requests at #{@setting.requests_email || "(no address set)"} through #{Inbound::Setting.ingress}" : "Not receiving requests by email")
json.requests_email @setting.requests_email
json.ingress Inbound::Setting.ingress
json.ingress_from_environment Inbound::Setting.ingress_from_environment?
json.receiving Runwell::Plugins.mail_ingress.present?
