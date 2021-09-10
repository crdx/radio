require 'open-uri'
require 'net/http'

class RadioStation
  AIRWAVES = %w{
    bbc_radio_one
    bbc_radio_two
    bbc_radio_three
    bbc_radio_fourfm
    bbc_radio_five_live
    bbc_6music
  }

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
    "http://stream.live.vc.bbcmedia.co.uk/#{freq}"
  end

  def stop
    @stopped = true
  end

  def play(redirect_stderr = true)
    @stopped = false
    uri = URI(playlist_url)
    Net::HTTP.start(uri.host, uri.port) do |http|
      req = Net::HTTP::Get.new(uri)
      http.request(req) do |response|
        IO.popen('mpv -', 'w+') do |mpv|
          response.read_body do |chunk|
            if @stopped
              Process.kill 'KILL', mpv.pid
              http.finish
              return
            end
            mpv.write chunk
            yield chunk.length
          end
        end
      end
    end
  end

  def last_played_rows
    return [] if @channel != 1

    require 'nokogiri'

    doc = Nokogiri::HTML(URI.open(last_played_url))

    doc.css('.post-content')[0..20].map do |song|
      artist, track = song.css('a').first[:title].strip.split(' - ', 2)
      time = song.css('.date span').text.strip.match(/\d+:\d+(am|pm)/).to_s
      [ time, artist, track  ].map { |col| col.gsub /\s+/, ' ' }
    end
  rescue
    []
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
