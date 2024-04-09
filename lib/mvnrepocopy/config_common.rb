module Mvnrepocopy
  def self.add_common_opts(options, opts) 
    opts.separator ""
    opts.separator "Common Options:"

    opts.on("-v", "--[no-]verbose", "Print verbose output") do |v|
      options.verbose = v
    end

    opts.on("-h", "--help", "Print this heip") do
      puts opts
      exit
    end

    opts.on_tail("--version", "Show Version") do
      puts VERSION
      exit
    end

    opts
  end
end
