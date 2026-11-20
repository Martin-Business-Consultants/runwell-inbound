module Inbound
  # How requests' mail comes in, when the server's environment doesn't say: the service forwarding
  # it, with a password made for it the first time.
  class ServicesController < ApplicationController
    browser_only :update, reason: "it makes the password a mail service signs in with, shown to a person in the browser"

    def update
      ingress = params.dig(:service, :ingress).presence_in(Setting::INGRESSES.keys.map(&:to_s))
      if ingress
        Setting.receive_through!(ingress)
        redirect_to inbound_email_requests_path, notice: "Requests’ mail comes in through #{helpers.inbound_ingress_name(ingress)}. Give it the address and password shown."
      else
        Setting.stop_receiving!
        redirect_to inbound_email_requests_path, notice: "Runwell isn’t receiving requests by email."
      end
    end
  end
end
