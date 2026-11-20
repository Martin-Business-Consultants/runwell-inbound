module Inbound
  # A message in a request's thread, by its Message-ID: one that came in ("in"), or an
  # acknowledgement that went out ("out"). The same message delivered twice (sent to the requests
  # address and to someone on the team who forwards it, or a service retrying) is seen once, and a
  # reply whose In-Reply-To or References names any message here belongs to that message's request.
  class Message < ApplicationRecord
    self.table_name = "inbound_messages"

    belongs_to :task, class_name: "::Task"

    validates :message_id, presence: true, uniqueness: true
    validates :direction, inclusion: { in: %w[in out] }

    def self.seen?(message_id) = message_id.present? && exists?(message_id: message_id)

    # The open request a mail answers, or nil: the newest one any of its In-Reply-To or References
    # ids belongs to, unless that request is done (then a reply starts a new one).
    def self.request_answered_by(mail)
      ids = [ *Array(mail.in_reply_to), *Array(mail.references) ].compact_blank.uniq
      return if ids.empty?

      task = where(message_id: ids).order(created_at: :desc).first&.task
      task unless task.nil? || task.status == "done"
    end

    def self.record!(message_id, task:, direction:)
      return if message_id.blank?

      create_or_find_by!(message_id: message_id) { it.assign_attributes(task: task, direction: direction) }
    end
  end
end
