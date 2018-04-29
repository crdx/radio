require 'open-uri'
require 'nokogiri'
require 'tty-table'

class Station
  AIRWAVES = %w{radio_one radio_two radio_three radio_fourfm radio_five_live 6music}

  def initialize channel
    @channel = channel.to_i
    self
  end

  attr_reader :channel

  def freq
    AIRWAVES[@channel - 1]
  end  

  def found?
    @channel > 0 && @channel < AIRWAVES.length
  end

  def playlist_url 
    "http://a.files.bbci.co.uk/media/live/manifesto/audio/simulcast/hls/uk/sbr_high/ak/bbc_#{freq}.m3u8"
  end

  def mpv_command
    "mpv --msg-level=ffmpeg=error #{playlist_url}"
  end

  def stop
    @stopped = true
  end

  def play redirect_stderr = true
    @stopped = false
    params = redirect_stderr ? [ :err => [ :child, :out ] ] : []
    IO.popen(mpv_command, *params) do |io|
      while line = io.gets
        yield line
        break if @stopped
      end
      Process.kill 'KILL', io.pid
    end
  end

  def last_played_rows
    doc = Nokogiri::HTML(open(last_played_url))

    doc.css('.music-track__middle-box').map do |song|
      artist = song.css('[data-marker=music-track-artist-name]').text.strip
      track  = song.css('[data-marker=music-track-title]').text.strip
      time   = song.css('.music-track__time').text.strip
      [ time, artist, track  ].map { |col| col.gsub /\s+/, ' ' }
    end
  end

  def last_played
    TTY::Table.new([ 'Time', 'Artist', 'Track' ], last_played_rows).render(:unicode)
  end

  private 

  def last_played_url
    "https://www.bbc.co.uk/music/tracks/find/radio#{@channel}"
  end
end
