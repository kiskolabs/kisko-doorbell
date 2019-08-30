require "sucker_punch"
require "flowdock"

module Kisko
  module Doorbell
    class MessageJob
      include SuckerPunch::Job

      MESSAGES = [
        "someone is at the office door",
        "there's someone at the door",
        "the doorbell just rang",
        "someone just rang the doorbell",
        "could someone please go open the office door"
      ]

      attr_reader :line, :doorbell_id, :flowdock_flow, :flowdock_token, :store_path

      def perform(**kwargs)
        kwargs.each do |key, value|
          instance_variable_set("@#{key}", value)
        end

        begin
          json = JSON.parse(line)
          logger.debug "A doorbell just rang", json: json

          if json["id"] == doorbell_id
            logger.success "This is the doorbell we want", id: json["id"]
            notify_flowdock(token: flowdock_token, store_path: store_path)
          else
            logger.debug "This isn't the doorbell we want", id: json["id"]
          end
        rescue JSON::ParserError
          logger.warn "JSON parse error", json: line
        end
      end

      def notify_flowdock(token:, store_path:)
        now = Time.now
        flowdock = Flowdock::Client.new(api_token: token)
        store = YAML::Store.new(store_path, true)

        store.transaction do
          last_thread_id = store["last_thread_id"]
          last_message_sent_at = store["last_message_sent_at"]
          last_message_body = store["last_message_body"]

          body = next_message(last_message_body)

          content = "@team, #{body}"
          message = if last_thread_id && last_message_sent_at && last_message_sent_at.to_date == now.to_date
            flowdock.chat_message(flow: flowdock_flow, content: content, thread_id: last_thread_id)
          else
            flowdock.chat_message(flow: flowdock_flow, content: content)
          end

          if message["thread_id"]
            logger.success "Posted a message on Flowdock"
            logger.debug message.inspect

            store["body"] = body
            store["last_thread_id"] = message["thread_id"]
            store["last_message_sent_at"] = now
          else
            logger.error "Flowdock error", response: message
          end
        end
      end

      private def next_message(last_message)
        new_message = last_message

        while new_message == last_message
          new_message = MESSAGES.sample
        end

        new_message
      end
    end
  end
end
