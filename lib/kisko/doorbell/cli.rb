require "json"
require "open3"
require "tmpdir"
require "tty-logger"
require "tty-which"
require "yaml/store"
require "sucker_punch"
require "honeybadger"

require_relative "message_job"

module Kisko
  module Doorbell
    class CLI
      RTL_433_VERSION_REGEXP = /rtl_433 version ([\d\w\.-]+)/i

      attr_reader :flowdock_token, :flowdock_flow, :doorbell_id, :logger, :test_mode

      def initialize(flowdock_token:, flowdock_flow:, doorbell_id:, logger:, test_mode: false)
        @flowdock_token = flowdock_token
        @flowdock_flow = flowdock_flow
        @doorbell_id = doorbell_id ? Integer(doorbell_id) : nil
        @logger = logger
        @test_mode = test_mode

        SuckerPunch.logger = logger
        SuckerPunch.exception_handler = -> (ex, _klass, _args) { Honeybadger.notify(ex) }
      end

      def check_prerequisites
        logger.info "Checking prerequisites..."
        return false unless check_rtl_433_path
        return false unless check_rtl_433
        return false unless check_flowdock
        return false unless check_doorbell_id
        return false unless check_yaml_store_path
        true
      end

      def run!
        logger.info "Starting rtl_433", arguments: rtl_433_arguments

        Open3.popen2e(rtl_433_path, *rtl_433_arguments) do |_stdin, io, wait_thr|
          logger.success "rtl_433 running (PID: #{wait_thr.pid})"
          while (line = io.gets) do
            if line.include?("No supported devices found")
              logger.fatal line.rstrip
              return false
            elsif line.start_with?("{")
              MessageJob.perform_async(
                line: line,
                doorbell_id: doorbell_id,
                flowdock_flow: flowdock_flow,
                flowdock_token: flowdock_token,
                store: yaml_store
              )
            else
              logger.debug line.rstrip
            end
          end
        end

        return true
      rescue => exception
        Honeybadger.notify(exception)
        return false
      end

      def check_rtl_433_path
        if rtl_433_path
          logger.success "rtl_433 found", path: rtl_433_path
          true
        else
          logger.fatal "rtl_433 not found"
          false
        end
      end

      def check_flowdock
        if flowdock_token && flowdock_flow
          obfuscated_token = "#{flowdock_token[0..10]}..."
          logger.success "Flowdock configured", token: obfuscated_token, flow: flowdock_flow
          true
        else
          logger.fatal "Flowdock token and flow ID missing"
          false
        end
      end

      def check_doorbell_id
        if doorbell_id
          logger.success "Doorbell configured", dec: doorbell_id, hex: doorbell_id.to_s(16)
          true
        else
          logger.fatal "No doorbell"
          false
        end
      end

      def check_rtl_433
        begin
          Open3.popen2e(rtl_433_path, "-V") do |stdin, stdout_and_stderr, wait_thr|
            version_output = stdout_and_stderr.read

            stdin.close
            stdout_and_stderr.close

            exit_status = wait_thr.value.exitstatus

            if exit_status == 0
              matches = RTL_433_VERSION_REGEXP.match(version_output)
              logger.success "rtl_433 works", version: matches[1]
              return true
            else
              logger.fatal "rtl_433 failed", exit_status: exit_status

              version_output.each_line do |line|
                logger.fatal line
              end

              return false
            end
          end
        rescue Errno::ENOENT
          logger.fatal "rtl_433 binary not found"
          false
        end
      end

      def check_yaml_store_path
        logger.success "YAML store configured", path: yaml_store_path
      end

      def rtl_433_path
        @rtl_433_path ||= TTY::Which.which("rtl_433")
      end

      def rtl_433_arguments
        common = ["-R", "115", "-R", "116", "-M", "newmodel", "-F", "json", "-f", "868300000"]

        if test_mode
          test_path = File.expand_path("../../../signals/g001_868.3M_250k.cu8", __dir__)
          logger.info "Using test signal", path: test_path
          common + ["-r", test_path]
        else
          common
        end
      end

      def yaml_store_path
        @yaml_store_path ||= Dir::Tmpname.create(["kisko-doorbell", ".yml"]) do |tmpname, _, _|
          tmpname
        end
      end

      def yaml_store
        @yaml_store ||= YAML::Store.new(store_path, true)
      end
    end
  end
end
