require 'minitest/autorun'

require_relative '../lib/station'

class TestStation < MiniTest::Test
    def test_station_tunes
        assert(Station.new(1).found?)
        assert(Station.new(2).found?)
    end

    def test_station_doesnt_tune
        refute(Station.new(0).found?)
        refute(Station.new(-1).found?)
        refute(Station.new('potato').found?)
    end

    def test_last_played_has_lines
        station = Station.new(1)
        played = station.last_played
        assert(played.lines.length > 0)
    end
end
