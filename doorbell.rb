#!/usr/bin/env ruby

require "bundler/inline"

trap "SIGINT" do
  exit 130
end

gemfile do
  source "https://rubygems.org"
  gem "flowdock"
  gem "tty-logger", git: "https://github.com/piotrmurach/tty-logger.git", ref: "a70e8cc0d1931c956d23005f0cb26dc8226ed994"
  gem "tty-which"
  gem "concurrent-ruby", require: "concurrent"
end

require "json"
require "yaml/store"
require "open3"

logger = TTY::Logger.new do |config|
  config.level = :debug
end

RTL_433_PATH = TTY::Which.which("rtl_433")

unless RTL_433_PATH
  logger.fatal "rtl_433 not found, make sure it's in PATH"
  exit 1
end

RTL_433_VERSION_REGEXP = /rtl_433 version ([\d\w\.-]+)/i

logger.info "Testing rtl_433", path: RTL_433_PATH
begin
  Open3.popen2e(RTL_433_PATH, "-V") do |stdin, stdout_and_stderr, wait_thr|
    version_output = stdout_and_stderr.read

    stdin.close
    stdout_and_stderr.close

    exit_status = wait_thr.value.exitstatus

    if exit_status == 0
      matches = RTL_433_VERSION_REGEXP.match(version_output)
      logger.success "rtl_433 works", version: matches[1]
    else
      logger.fatal "rtl_433 failed", exit_status: exit_status

      version_output.each_line do |line|
        logger.fatal line
      end

      exit exit_status
    end
  end
rescue Errno::ENOENT
  logger.fatal "rtl_433 binary not found"
  exit 1
end

DOORBELL_ID = ENV.fetch("DOORBELL_ID").to_i
logger.info "Doorbell configured", id: DOORBELL_ID, hex: DOORBELL_ID.to_s(16)

FLOWDOCK_FLOW = "kisko:war-room"

FLOWDOCK_API_TOKEN = ENV.fetch("FLOWDOCK_API_TOKEN")
obfuscated_token = "#{FLOWDOCK_API_TOKEN[0..10]}..."
logger.info "Flowdock configured", token: obfuscated_token, flow: FLOWDOCK_FLOW

class BackgroundMessageHandler
  include Concurrent::Async

  MESSAGES = [
    "someone is at the office door",
    "there's someone at the door",
    "the doorbell just rang",
    "someone just rang the doorbell",
    "could someone please go open the office door"
  ]

  def initialize(logger: TTY::Logger.new)
    super()
    @logger = logger
    @store = YAML::Store.new("./doorbell.yml", true)
    @flowdock = Flowdock::Client.new(api_token: FLOWDOCK_API_TOKEN)
  end

  def process(line)
    begin
      json = JSON.parse(line)
      @logger.debug "A doorbell just rang", json

      if json["id"] == DOORBELL_ID
        @logger.success "This is the doorbell we want", id: json["id"]
        notify_flowdock(json)
      else
        @logger.debug "This isn't the doorbell we want", id: json["id"]
      end
    rescue JSON::ParserError
      @logger.debug line.rstrip unless line.strip.length == 0
    end
  end

  def notify_flowdock(json)
    now = Time.now
    @store.transaction do
      last_thread_id = @store["last_thread_id"]
      last_message_sent_at = @store["last_message_sent_at"]
      last_message_body = @store["last_message_body"]

      body = next_message(last_message_body)

      content = "@team, #{body}"
      message = if last_thread_id && last_message_sent_at && last_message_sent_at.to_date == now.to_date
        @flowdock.chat_message(flow: FLOWDOCK_FLOW, content: content, thread_id: last_thread_id)
      else
        @flowdock.chat_message(flow: FLOWDOCK_FLOW, content: content)
      end

      if message["thread_id"]
        @logger.success "Posted a message on Flowdock"
        @logger.debug message.inspect

        @store["body"] = body
        @store["last_thread_id"] = message["thread_id"]
        @store["last_message_sent_at"] = now
      else
        @logger.error "Something went wrong with the Flowdock message"
        @logger.error message.inspect
      end
    end
  end

  def next_message(last_message)
    new_message = last_message

    while body == last_message_body
      new_message = MESSAGES.sample
    end

    body
  end
end

logger.info "Starting rtl_433..."

message_handler = BackgroundMessageHandler.new(logger: logger.copy({}))

Open3.popen2e(RTL_433_PATH, "-R", "115", "-R", "116", "-M", "newmodel", "-F", "json", "-f", "868300000") do |_stdin, io, wait_thr|
  logger.success "rtl_433 running (PID: #{wait_thr.pid})"
  while (line = io.gets) do
    message_handler.async.process(line)
  end
end
