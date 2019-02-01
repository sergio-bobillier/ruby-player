# frozen_string_literal: true

require 'colorize'

require_relative './song'

# Handles the playlist
class Playlist
  attr_reader :pages

  def initialize(songs = nil)
    @songs = []
    @pages = 0
    @index = -1
  end

  def <<(song)
    add! song
  end

  def next_song
    return unless @songs.any?

    @index += 1
    @index = 0 if @index >= @songs.size
    @songs[@index]
  end

  def print(page = nil)
    width = calculate_width
    offset = calculate_offset(page)

    if @songs.empty?
      puts "There are no songs in the playlist!\n\nAdd some!"
    else
      puts "Songs in playlist:\n\n"

      paged_songs = @songs.slice(offset, 10)

      paged_songs.each_with_index do |song, index|
        actual_index = index + offset
        song_number = (actual_index + 1).to_s.rjust(width, ' ')
        song_title = "  #{song_number}. #{song.title}".ljust(70, ' ')

        if actual_index == @index
          puts song_title.colorize(color: :light_white, background: :blue)
        else
          puts song_title
        end
      end

      puts "\nShowing #{offset + 1} - #{offset + paged_songs.size}"\
        " of #{@songs.size}"
    end
  end

  private

  def add(song)
    @songs << (song.is_a?(Song) ? song : Song.new(song))
  end

  def add!(song)
    add song
    calculate_pages
  end

  def calculate_pages
    @pages = (@songs.size / 10.0).ceil
  end

  def calculate_width
    (@songs.size + 1).to_s.size
  end

  def calculate_offset(page)
    return [@index - 5, 0].max unless page

    page = @pages if page > @pages
    offset = page * 10 - 10
    offset.negative? ? 0 : offset
  end
end
