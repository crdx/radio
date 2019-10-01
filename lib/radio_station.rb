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
      while line = io.gets
        yield line if block_given?
        break if @stopped
      end
      Process.kill 'KILL', io.pid
    end
  end

  def last_played_rows
    return []

    require 'nokogiri'

    doc = Nokogiri::HTML(open(last_played_url))

    doc.css('.music-track__middle-box').map do |song|
      artist = song.css('[data-marker=music-track-artist-name]').text.strip
      track  = song.css('[data-marker=music-track-title]').text.strip
      time   = song.css('.music-track__time').text.strip
      [ time, artist, track  ].map { |col| col.gsub /\s+/, ' ' }
    end
  end

  def last_played
    require 'tty-table'
    TTY::Table.new([ 'Time', 'Artist', 'Track' ], last_played_rows).render(:unicode)
  end

  private

  def last_played_url
    "https://www.bbc.co.uk/music/tracks/find/radio#{@channel}"
  end
end
