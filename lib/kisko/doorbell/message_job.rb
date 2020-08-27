require "sucker_punch"
require "slack"

module Kisko
  module Doorbell
    class MessageJob
      include SuckerPunch::Job

      MESSAGES = [
        "Someone is at the office door",
        "There's someone at the door",
        "The doorbell just rang",
        "Someone just rang the doorbell",
        "Could someone please go open the office door",
        "🛎 ding dong, someone wants in 🛎",
        "🔔 bing bong, the doorbell rang 🔔",
        "Hello 👋, please open the door"
      ]

      URGENT_MESSAGES = [
        "someone is still at the door",
        "please answer the door ASAP!",
        "seriously. Open the door.",
        "open the 🚪, please",
        "someone seems to be waiting❗️"
      ]

      attr_reader :line, :doorbell_id, :store_path, :slack_token, :slack_channel

      def perform(**kwargs)
        kwargs.each do |key, value|
          instance_variable_set("@#{key}", value)
        end

        begin
          json = JSON.parse(line)
          logger.debug "A doorbell just rang", json: json

          if json["id"] == doorbell_id
            logger.success "This is the doorbell we want", id: json["id"]
            notify_slack
          else
            logger.debug "This isn't the doorbell we want", id: json["id"]
          end
        rescue JSON::ParserError
          logger.warn "JSON parse error", json: line
        end
      end

      def notify_slack
        now = Time.now
        slack = Slack::Web::Client.new(token: slack_token)

        store.transaction do
          last_message_sent_at = store["last_message_sent_at"]
          last_message_body = store["last_message_body"]

          unless last_message_sent_at.nil? || (Time.now - last_message_sent_at) > 5 # seconds
            return # If it's too soon after the last message, skip sending a new one
          end

          content = next_message(last_message_body, last_message_sent_at, slack: true)

          response = slack.chat_postMessage(channel: slack_channel, text: content, icon_emoji: ":bellhop_bell:")

          logger.success "Posted a Slack message", content: content, channel: response["channel"]
          logger.debug response.to_h.inspect

          store["body"] = content
          store["last_message_sent_at"] = now
        end
      end

      private def store
        @yaml_store ||= YAML::Store.new(store_path, true)
      end

      private def next_message(last_message, last_message_sent_at, slack: false)
        new_message = last_message

        while new_message == last_message
          if last_message_sent_at.nil? || (Time.now - last_message_sent_at) > 120 # seconds
            new_message = MESSAGES.sample
          else
            new_message = URGENT_MESSAGES.sample
            new_message = slack ? "<!here>, #{new_message}" : "@team, #{new_message}"
          end
        end

        new_message
      end
    end
  end
end
