require 'thread'
# FROM https://raw.githubusercontent.com/djberg96/memoize/master/lib/memoize.rb

module Memoize
   # The version of the memoize library
   MEMOIZE_VERSION = '1.3.2'
   @@lock = Mutex.new
   # Memoize the method +name+.  If +file+ is provided, then the method results
   # are stored on disk as well as in memory.
   def memoize(name, file=nil)
      cache = File.open(file, 'rb'){ |io| Marshal.load(io) } rescue {}

      (class<<self; self; end).send(:define_method, name) do |*args|
         unless cache.has_key?(args)
            cache[args] = super(*args)
            if [Enumerator, Enumerable].include? cache[args].class
              cache[args] = cache[args].to_a
            end
            @@lock.synchronize {
               File.open(file, 'wb'){ |f| Marshal.dump(cache, f) } if file
            }
         end
         cache[args]
      end
      cache
   end
end
