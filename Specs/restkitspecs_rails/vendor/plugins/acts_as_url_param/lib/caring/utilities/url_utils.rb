module Caring
  module Utilities
    module UrlUtils
      # Makes a string safe for urls
      # Options:
      #   :replacements - a Hash of a replacement string to a regex that should match for replacement
      #   :char - when :replacements is not provided, this is the string that will be used to replace unsafe characters. defaults to '-'
      #   :collapse - set to false if multiple, consecutive unsafe characters should not be replaced with only a single instance of :char.
      #               defaults to true. only matters if you don't provide :replacements. If you do, you'll need to write your regex such
      #               that it matches multiple characters.
      #   :strip_endings - remove replacement characters from the beginning and end of the safe string. Defaults to true.
      #   :downcase - make the input string lower case. Defautls to true.
      def url_safe(s, options = {})
        return s if s.blank?
        s = s.downcase if options.fetch(:downcase, true)
        collapse = options.fetch(:collapse, true)
        default_regex = /[^'a-zA-Z0-9]#{"+" if collapse}/
        s.gsub! /(&amp;)|&/, 'and'
        replacements = options[:replacements] || { options.fetch(:char,"-") => default_regex, "" => /'#{"+" if collapse}/}
        replacements.each do |replacement, regex|
          s = s.gsub(regex,replacement)
        end
        if options.fetch(:strip_endings,true)
          replacement_strings = replacements.keys.map{|k| "(#{Regexp.escape(k)})" unless k.blank?}.compact.join("|")
          s = s.gsub(/(^#{replacement_strings})|(#{replacement_strings}$)/,"")
        end
        return s
      end

      # Generate integers
      # Options:
      #   :start => 1, The integer to start with
      #   :end => nil, the last integer to generate, when nil this becomes an infinite sequence
      #   :increment => 1, the amount to add for each iteration
      # def int_generator(options = {})
      #   start = options.fetch(:start,1)
      #   last = options[:end]
      #   increment = options.fetch(:increment, 1)
      #   raise ArgumentError if increment == 0
      #   raise ArgumentError if last && (increment > 0 && start > last) || (increment < 0 && start < last)
      #   unless defined?(::Generator)
      #     puts "requiring generator. again."
      #     rv = require 'generator'
      #     raise "required returned: #{rv.inspect}"
      #   end
      #   ::Generator.new do |g|
      #     i = start
      #     loop do
      #       g.yield i
      #       return if !last.nil? && (increment > 0 && i >= last) || (increment < 0 && i <= last)
      #       i = i + increment
      #     end
      #   end
      # end

      class IntGenerator
        def initialize(options = {})
          @current = options[:start] || 0
          @end = options[:end]
          @increment = options[:increment] || 1
        end
        def next?
          if @end.nil?
            true
          else
            @current <= @end
          end
        end
        def next
          c, @current = @current, @current + @increment
          return c
        end
      end

      def int_generator(options)
        IntGenerator.new(options)
      end

      # accepts a block that will be passed a candidate string and should return true if it is unique.
      # Options:
      # => :separator => "-", a string that will be injected between the base string and the uniqifier
      # => :endings => generator, a Generator that provides endings to be placed at the end of the base.
      #                           defaults to the set of positive integers.
      def uniquify(base, options = {})
        sep = options.fetch(:separator, "-")
        endings = options[:endings] || int_generator(:start => 2)
        return base if yield base
        while endings.next? do
          candidate = base+sep+endings.next.to_s
          return candidate if yield candidate
        end
        raise ArgumentError.new("No unique construction found for \"#{base}\"")
      end
    end
  end
end
