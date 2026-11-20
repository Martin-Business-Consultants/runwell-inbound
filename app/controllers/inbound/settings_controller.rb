module Inbound
  # Settings › Requests by email: the address clients email requests to.
  class SettingsController < ApplicationController
    agent_tool :show_email_requests, on: :show, title: "Show how requests by email come in",
      description: "The address clients email requests to, the service that forwards it here, and whether Runwell is receiving."
    agent_tool :update_email_requests, on: :update, title: "Set the address clients email requests to",
      description: "requests_email: the address clients email requests to, forwarded here by the service in these settings; acknowledgements go out with it as their reply address, so replies come back to the same request. Blank stops offering it.",
      params: { setting: { requests_email: "string" } }

    def show
      @setting = Setting.current
    end

    def update
      @setting = Setting.current
      if @setting.update(params.expect(setting: %i[requests_email]))
        redirect_to inbound_email_requests_path, notice: "Requests by email go to #{@setting.requests_email || "nowhere yet"}."
      else
        redirect_to inbound_email_requests_path, alert: @setting.errors.full_messages.to_sentence
      end
    end
  end
end
