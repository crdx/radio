require 'minitest/autorun'

require_relative '../lib/radio_station'

class TestRadio < MiniTest::Test
    def test_station_tunes
        assert(RadioStation.new(1).found?)
        assert(RadioStation.new(2).found?)
    end

    def test_station_doesnt_tune
        refute(RadioStation.new(0).found?)
        refute(RadioStation.new(-1).found?)
        refute(RadioStation.new('potato').found?)
    end

    def test_last_played_has_lines
        station = RadioStation.new(1)
        played = station.last_played
        assert(played.lines.length > 0)
    end
end
