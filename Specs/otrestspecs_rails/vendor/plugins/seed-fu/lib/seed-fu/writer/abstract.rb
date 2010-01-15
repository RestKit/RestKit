module SeedFu
  
  module Writer

    class Abstract
      attr_accessor :seed_handle, :config, :number_of_seeds

      def initialize(options={})
        self.config = options
        self.number_of_seeds = 0

        self.seed_handle = File.new(self.config[:seed_file], 'w')

        write_header
      end
      
      def header
        <<-END
# DO NOT MODIFY THIS FILE, it was auto-generated.
# 
# Date: #{DateTime.now}
# Using #{self.class} to seed #{config[:seed_model]}
# Written with the command:
#
#   #{$0} #{$*.join}
#
        END
      end

      def footer
        <<-END
# End auto-generated file.
        END
      end

      def add_seed(hash)
        $stdout.puts "Added #{hash.inspect}" unless config[:quiet]
        self.number_of_seeds += 1
      end

      def write_header
        seed_handle.syswrite header
      end

      def write_footer
        seed_handle.syswrite footer
      end

      def finish
        write_footer
        seed_handle.close
      end

    end
  
  end

end
