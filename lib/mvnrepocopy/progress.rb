module Mvnrepocopy
  class Progress
    def initialize(total_steps = nil, print_interval = 50)
      @total_steps = total_steps
      @print_interval = print_interval
      @current = 0
      @segment_start = Time.now
      @segment_bytes = 0
    end

    def inc(bytes: 0)
      @current += 1
      inc_bytes(bytes)

      if (@current % @print_interval == 0) || (@current == @total_steps)
        log_segment
      end
    end

    def inc_bytes(bytes)
      @segment_bytes += bytes
    end

    def log_segment
      if @segment_bytes > 0
        duration = (Time.now - @segment_start).to_f
        mb = @segment_bytes.to_f / 1024 / 1024
        speed = (duration != 0) ? ("%8.4f" % [mb / duration]) : "--"
        puts("Progress: %5d of %s: %9.4f MB in %6.2f s (%s MB/s)" % [@current, @total_steps || "unknown", mb, duration, speed])
      else
        puts("Progress: %5d of %s" % [@current, @total_steps || "unknown"])
      end

      @segment_bytes = 0
      @segment_start = Time.now
    end
  end
end