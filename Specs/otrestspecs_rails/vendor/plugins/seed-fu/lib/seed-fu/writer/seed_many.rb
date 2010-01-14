module SeedFu
  
  module Writer

    class SeedMany < Abstract

      def seed_many_header
        "#{config[:seed_model]}.seed_many(#{config[:seed_by].collect{|s| ":#{s}"}.join(',')},["
      end
      
      def seed_many_footer
        "\n])\n"
      end

      # Chunk in groups of 100 for performance
      #
      def chunk_this_seed?
        0 == (self.number_of_seeds % (config[:chunk_size] || 100))
      end

      def add_seed(hash)
        seed_handle.syswrite( (<<-END
#{',' unless self.number_of_seeds == 0 or chunk_this_seed?}
  { #{hash.collect{|k,v| ":#{k} => '#{v.to_s.gsub("'", "\'")}'"}.join(', ')} }
        END
        ).chomp )
        super(hash)

        if chunk_this_seed?
          seed_handle.syswrite(
            self.seed_many_footer +
            "# BREAK EVAL\n" +
            self.seed_many_header
          )
        end
      end

      def write_header
        super
        seed_handle.syswrite self.seed_many_header
      end

      def write_footer
        seed_handle.syswrite self.seed_many_footer
        super
      end

    end

  end

end
