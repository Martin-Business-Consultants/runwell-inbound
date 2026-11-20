module Inbound
  # The plugin's settings pages: the core's layout, for people who may manage settings, and
  # nothing at all while it's switched off.
  class ApplicationController < ::ApplicationController
    layout "application"
    require_permission :manage_settings
    helper Inbound::SettingsHelper

    before_action { head :not_found unless Runwell::Plugins.enabled?(:inbound) }
  end
end
