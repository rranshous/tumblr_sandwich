require 'daybreak'

module DiskMap
  def disk_map
    # goal: be able to restart after hard stop
    #       this means we'll need to persist to disk each input
    #       and it's output so that if we get re-run we'll skip
    #       work we've already done
  end
  def disk_flat_map
  end
end
