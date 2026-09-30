# frozen_string_literal: true

module RuboCop
  module Cop
    module Kisko
      class FileLengthWarning < Base
        MSG = "Source file is in the LOC warning zone (%<current>d lines; prefer %<max>d or fewer)."

        def on_new_investigation
          current = processed_source.raw_source.lines.count
          maximum = cop_config.fetch("Max")
          hard_maximum = cop_config.fetch("HardMax")
          return unless current.between?(maximum + 1, hard_maximum)

          warn format(MSG, current: current, max: maximum)
        end
      end

      class FileLengthLimit < Base
        MSG = "Source file exceeds the LOC limit (%<current>d/%<max>d)."

        def on_new_investigation
          current = processed_source.raw_source.lines.count
          maximum = cop_config.fetch("Max")
          return if current <= maximum

          add_global_offense(format(MSG, current: current, max: maximum))
        end
      end
    end
  end
end
