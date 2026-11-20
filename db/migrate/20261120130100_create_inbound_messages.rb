# Every message in a request's thread, by its Message-ID: those that came in, so the same message
# delivered twice makes one request, and the acknowledgements that went out, so a reply to either
# finds its request.
class CreateInboundMessages < ActiveRecord::Migration[8.1]
  def change
    create_table :inbound_messages do |t|
      t.string :message_id, null: false
      t.integer :task_id, null: false
      t.string :direction, null: false
      t.datetime :created_at, null: false
    end
    add_index :inbound_messages, :message_id, unique: true
    add_index :inbound_messages, :task_id
  end
end
