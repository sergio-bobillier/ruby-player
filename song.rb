# frozen_string_literal: true

# Represents a song in the playlist
class Song
  attr_reader :file, :title

  def initialize(file)
    unless file.is_a?(Pathname) || file.is_a?(String)
      raise ArgumentError, '`song` should be a Pathname or a String'
    end

    @file = file.is_a?(Pathname) ? file : Pathname.new(file)
    @title = @file.basename.to_s.sub(@file.extname, '')
  end
end
