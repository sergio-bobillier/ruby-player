# frozen_string_literal: true

require 'colorize'
require 'forwardable'

require_relative './song'

# Handles the playlist
class Playlist
  extend Forwardable

  attr_reader :songs, :current_song_index
  def_delegators :@songs, :size, :empty?

  def initialize(songs = nil)
    @songs = []
    @pages = 0
    @current_song_index = -1
  end

  def <<(song)
    @songs << (song.is_a?(Song) ? song : Song.new(song))
  end

  def next_song
    return unless @songs.any?

    @current_song_index += 1
    @current_song_index = 0 if @current_song_index >= @songs.size
    @songs[@current_song_index]
  end

  def previous_song
    return unless @songs.any?

    @current_song_index -= 1
    @current_song_index = @songs.size - 1 if @current_song_index < 0
    @songs[@current_song_index]
  end

  def remove_item
    return unless @current_song_index >= 0

    @songs.delete_at(@current_song_index)
    @current_song_index -= 1
  end
end
