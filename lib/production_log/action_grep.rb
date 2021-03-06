module ActionGrep; end

class << ActionGrep

  def grep(action_name, file_name)
    unless action_name =~ /\A([A-Z][A-Za-z\d]*)(?:#([A-Za-z]\w*))?\Z/ then
      raise ArgumentError, "Invalid action name #{action_name} expected something like SomeController#action"
    end

    unless File.file? file_name and File.readable? file_name then
      raise ArgumentError, "Unable to read #{file_name}"
    end

    buckets = Hash.new { |h,k| h[k] = [] }
    comp_count = Hash.new 0

    File.open file_name do |fp|
      LogParser.detect_mode(fp)
      fp.each_line do |line|
        bucket, data = LogParser.extract_bucket_and_data(line)
        next if !bucket

        buckets[bucket] << line

        case data
        when /^Start rendering component / then
          comp_count[bucket] += 1
        when /^End of component rendering$/ then
          comp_count[bucket] -= 1
        when /^Completed/ then
          next unless comp_count[bucket] == 0
          action = buckets.delete bucket
          next unless action.any? { |l| l =~ /Processing #{action_name}/ }
          puts action.join
        end
      end
    end
  end

end

