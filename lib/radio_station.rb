require 'open-uri'

class RadioStation
  AIRWAVES = %w{radio1 radio2 radio3 radio4fm radio5live 6music}

  attr_reader :channel

  def initialize channel
    @channel = channel.to_i
    self
  end

  def freq
    AIRWAVES[@channel - 1]
  end

  def found?
    @channel > 0 && @channel < AIRWAVES.length
  end

  def playlist_url
    "http://bbcmedia.ic.llnwd.net/stream/bbcmedia_#{freq}_mf_p"
  end

  def mpv_command
    "mpv --msg-level=ffmpeg=error #{playlist_url}"
  end

  def stop
    @stopped = true
  end

  def play(redirect_stderr = true)
    @stopped = false
    params = redirect_stderr ? [ :err => [ :child, :out ] ] : []
    IO.popen(mpv_command, *params) do |io|
      # mpv no longer tells us the audio progress
      yield true
      loop do
        sleep 1
        break if @stopped
      end

      Process.kill 'KILL', io.pid
    end
  end

  def last_played_rows
    # https://www.radio1playlist.com is broken
    return []

    return [] if @channel != 1

    require 'nokogiri'

    doc = Nokogiri::HTML(open(last_played_url))

    doc.css('.post-content')[0..20].map do |song|
      artist, track = song.css('a').first[:title].strip.split(' - ', 2)
      time = song.css('.date span').text.strip.match(/\d+:\d+(am|pm)/).to_s
      [ time, artist, track  ].map { |col| col.gsub /\s+/, ' ' }
    end
  end

  def last_played
    require 'tty-table'
    TTY::Table.new([ 'Time', 'Artist', 'Track' ], last_played_rows).render(:unicode)
  end

  private

  def last_played_url
    "https://www.radio1playlist.com/"
  end
end
