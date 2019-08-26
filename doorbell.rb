#!/usr/bin/env ruby

require "bundler/inline"

trap "SIGINT" do
  exit 130
end

gemfile do
  source "https://rubygems.org"
  gem "flowdock"
  gem "tty-logger"
  gem "pry"
end

require "json"
require "yaml/store"

logger = TTY::Logger.new do |config|
  config.level = :debug
end

DOORBELL_ID = ENV.fetch("DOORBELL_ID").to_i
logger.info "Listening for doorbell ID: #{DOORBELL_ID}"

FLOWDOCK_API_TOKEN = ENV.fetch("FLOWDOCK_API_TOKEN")
logger.info "Got Flowdock API token: #{FLOWDOCK_API_TOKEN[0..10] + ("_" * (FLOWDOCK_API_TOKEN.length - 5))}"

MESSAGES = [
  "someone is at the office door",
  "there's someone at the door",
  "the doorbell just rang",
  "someone just rang the doorbell",
  "could someone please go open the office door"
]

flowdock = Flowdock::Client.new(api_token: FLOWDOCK_API_TOKEN)

logger.success "Created Flowdock client"

store = YAML::Store.new("./doorbell.yml", true)

logger.info "Starting rtl_433..."

IO.popen("/Users/matt/Code/rtl_433/build/src/rtl_433 -R 115 -R 116 -M newmodel -F json -f 868300000", err: [:child, :out]) do |io|
  while (line = io.gets) do
    begin
      json = JSON.parse(line)
      logger.debug json.inspect

      if json["id"] == DOORBELL_ID
        logger.success "Our doorbell just rang!"

        now = Time.now
        store.transaction do
          last_thread_id = store["last_thread_id"]
          last_message_sent_at = store["last_message_sent_at"]
          last_message_body = store["last_message_body"]

          body = nil

          while body.nil? || body == last_message_body
            body = MESSAGES.sample
          end

          content = "@team, #{body}"
          message = if last_thread_id && last_message_sent_at && last_message_sent_at.to_date == now.to_date
            flowdock.chat_message(flow: "kisko:war-room", content: content, thread_id: last_thread_id)
          else
            flowdock.chat_message(flow: "kisko:war-room", content: content)
          end

          if message["thread_id"]
            logger.success "Posted a message on Flowdock"
            logger.debug message.inspect

            store["body"] = body
            store["last_thread_id"] = message["thread_id"]
            store["last_message_sent_at"] = now
          else
            logger.error "Something went wrong with the Flowdock message"
            logger.error message.inspect
          end
        end
      else
        logger.debug "A doorbell rang, but it wasn't ours"
      end
    rescue JSON::ParserError
      logger.debug line.rstrip unless line.strip.length == 0
    end
  end
end
