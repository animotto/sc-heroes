# frozen_string_literal: true

module SCHeroes
  ##
  # Titles
  class Titles
    TITLES = {  
      71087 => 'Pioneer',
      72950 => 'Piligrim',
      73478 => 'Seeker',
      73566 => 'Assassin',
      75131 => 'Charming',
      76154 => 'Trasher',
      76911 => 'Power broker',
      76502 => 'Sinister',
      76813 => 'Dark Overlord',
      77405 => 'Champion',
      77578 => 'Corsair',
      78971 => 'Rear admiral',
      79547 => 'Strategist',
      79945 => 'Veteran',
      79955 => 'Cosmonaut',
      4294967295 => 'NONE'
    }.freeze

    UNKNOWN_TITLE = 'UNKNOWN'

    def self.get_name(id)
      # TITLES.fetch(id, UNKNOWN_TITLE)
      TITLES.fetch(id, id)
    end
  end
end
