# frozen_string_literal: true

require 'English'

# Represents the player. Fetches songs from the playlist / queue and plays them
class Player
  attr_reader :playlist, :song
  attr_accessor :playback_started_event, :next_song_event, :playback_error_event

  def initialize(playlist)
    @playlist = playlist

    @waiter = nil
    @paused = false
    @song = nil
    @pid = nil
  end

  def play
    return toggle_pause if paused?
    return if playing?

    @song ||= playlist.next_song
    start_playback
  end

  def play_next
    stop
    play_next!
  end

  def play_previous
    stop
    play_previous!
  end

  def stop
    return unless playing?

    toggle_pause if paused?

    Process.kill 'SIGTERM', @pid
    @waiter.join if @waiter
    @pid = nil
  end

  def pause
    return unless playing?

    toggle_pause
  end

  def playing?
    @pid && @waiter.alive?
  end

  def paused?
    @paused
  end

  private

  def play_next!
    @song = playlist.next_song
    play
  end

  def play_previous!
    @song = playlist.previous_song
    play
  end

  def start_playback
    @pid = Process.spawn('mpg321', @song.file.to_s, %i[out err] => '/dev/null')

    waiter_proc = proc do |pid, song|
      Process.wait pid
      @paused = false
      @pid = nil

      if $CHILD_STATUS.exited? && $CHILD_STATUS.exitstatus != 0
        if @playback_error_event.is_a?(Proc)
          @playback_error_event.call "ERROR: Could not play #{song.file.basename}"
        end
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

  def toggle_pause
    if paused?
      Process.kill('SIGCONT', @pid)
      @paused = false
    else
      Process.kill('SIGSTOP', @pid)
      @paused = true
    end
  end
end
