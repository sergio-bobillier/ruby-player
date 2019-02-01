# frozen_string_literal: true

require 'English'

# Represents the player. Fetches songs from the playlist / queue and plays them
class Player
  attr_reader :playlist
  attr_accessor :playback_started_event, :next_song_event

  def initialize(playlist)
    @playlist = playlist

    @waiter = nil
    @song = nil
    @pid = nil
  end

  def play
    return if playing?

    @song ||= playlist.next_song
    puts "\n\nPlaying: #{@song.title}\n\n"
    start_playback
  end

  def play_next
    stop
    play_next!
  end

  def stop
    return unless playing?

    Process.kill 'SIGTERM', @pid
    @waiter.join if @waiter
    @pid = nil
  end

  def playing?
    @pid && @waiter.alive?
  end

  private

  def play_next!
    @song = playlist.next_song
    play
  end

  def start_playback
    @pid = Process.spawn('mpg321', @song.file.to_s, %i[out err] => '/dev/null')
    @stopped = false

    waiter_proc = proc do |pid, song|
      Process.wait pid
      @pid = nil

      if $CHILD_STATUS.exited? && $CHILD_STATUS.exitstatus != 0
        puts "ERROR: Could not play #{song.file}"
      else
        unless $CHILD_STATUS.signaled?
          play_next!

          @next_song_event.call if @next_song_event.is_a?(Proc)
        end
      end
    end

    @waiter = Thread.new(@pid, @song, &waiter_proc)
    @playback_started_event.call if @playback_started_event.is_a?(Proc)
  end
end
