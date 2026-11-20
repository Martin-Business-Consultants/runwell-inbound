# Where requests are emailed and how the mail gets here. Before Runwell 7.0 the core kept these in
# its settings (requests_email, inbound_ingress, inbound_password); an install that set them gets
# them copied here, read through the core's model so the password stays encrypted the same way.
class CreateInboundSettings < ActiveRecord::Migration[8.1]
  def up
    create_table :inbound_settings do |t|
      t.string :requests_email
      t.string :ingress
      t.text :password
      t.timestamps
    end

    return unless column_exists?(:settings, :requests_email)

    core = ::Setting.current
    address, ingress = core.read_attribute(:requests_email), core.read_attribute(:inbound_ingress)
    return if address.blank? && ingress.blank?

    Inbound::Setting.reset_column_information
    Inbound::Setting.create!(requests_email: address, ingress: ingress, password: core.read_attribute(:inbound_password))
  end

  def down
    drop_table :inbound_settings
  end
end
