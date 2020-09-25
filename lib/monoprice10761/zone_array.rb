module Monoprice10761
  class ZoneArray < Array
    def by_id(id)
      self[(id / 10 - 1) * 6 + id % 10 - 1]
    end
  end
end
