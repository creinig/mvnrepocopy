module Mvnrepocopy
  class Progress
    def initialize(total_steps, print_interval=50)
      @total_steps = total_steps
      @print_interval = print_interval
      @current = 0
    end

    def inc
      @current += 1

      puts "Progress: #{@current} of #{@total_steps}" if (@current % @print_interval == 0)
    end

  end
end
