module Travis
  class Decorator
    # Fold state
    class State
      def initialize(threshold = 4)
        @lines = [];
        @name  = '';
        @threshold = threshold;
      end
      def add_line!(line) 
	@lines.push(line);
	puts "travis_fold:start:#{@name}" if (@lines.length == @threshold);
	puts @lines.shift if (@lines.length > @threshold);
      end
      def end_fold!
        @lines[0...-1].each { |line| puts line };
	puts "travis_fold:end:#{@name}" if (@lines.length == @threshold);
        puts @lines[-1];
        @lines = [];
      end
      def inner_state(line)
        nil
      end
      def correct_line?(line)
        false
      end
    end
    # base implementation of folding logic
    class Base
      def initialize(no_color = true) 
        @states = [];
        @count = 0;
        @NO_COLOR = no_color
      end
      def decorate!(command)
        pipe = IO.popen(command)
        while (line = pipe.gets)
          no_color = @NO_COLOR ? Base.remove_color(line) : line;
          state = @states[0];
	  if (state)
            new_state = state.inner_state(no_color);
            if (new_state) 
              @state.unshift(new_state)
              next
            elsif (state.correct_line?(no_color))
              state.add_line!(line)
              next
            else
              state.end_fold!
              @states.pop
            end 
	  end
          first_state = default_state(no_color);
          if (first_state)
            first_state.add_line!(line);
            @states.push(first_state);
          else
            puts line;
          end  
        end
        cleanup!();
      end
      def self.remove_color(line) 
        line.gsub(/\e(\[[0-9]*[mK]|M)/, '').gsub(/^\s+/, '');
      end
      def end_fold!
        state = @states.pop;
        state.end_fold! if state;
      end
      def cleanup!
        end_fold!;
        initialize;
      end
    end
    # default implementation based on prefix 
    class Default < Base
      # default folding state (with prefix)
      class DefaultState < State
        LENGTH = 6;
        def initialize(line, count)
          super(6)
          @prefix = extract_prefix(line);
          @name = @prefix.gsub(/\W+/, '') + ".#{count}";
        end
        def correct_line?(line)
          @prefix == extract_prefix(line)
        end
        def extract_prefix(line)
          line[0 .. LENGTH];
        end
      end
      def default_state(line)
        @count += 1;
        DefaultState.new(line, @count);
      end
    end
    # JVM-based
    module JVM
      # JUnit state
      class JUnitState < State
        @@REGEX = /^T E S T S/;
        def self.regex
          @@REGEX
        end
        def initialize(count)
          super(6)
          @name = "junit.#{count}"
        end
        def correct_line?(line)
          line =~ @@REGEX or
          line =~ /^(Running |-{20}|\s*$)/ or
          line =~ /Failures: 0, Errors: 0,/
        end
      end
      class Maven < Base
        class MavenState < State
          def initialize(count)
            super(6)
            @name = "building.#{count}"
          end
          def correct_line?(line)
            line =~ /^(\[INFO\](?! (Reactor Summary:|Building))|Download(ing|ed):|\d+\/\d+|\s*$)/
          end
          def inner_state(line)
            JUnitState.new(@count) if line =~ JUnitState.regex
          end
        end 
        def default_state(line)
          if line =~ /^\[INFO\] Building/
            @count += 1;
            return MavenState.new(@count)
          end
          if line =~ JUnitState.regex
            @count += 1;
            return JUnitState.new(@count); 
          end
        end
      end
    end
    default = Default.new;
    types = { 'mvn' => JVM::Maven.new };
    (types[ARGV[0]] || default).decorate!(ARGV.join(' '));
  end
end  
