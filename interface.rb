# frozen_string_literal: true

require 'colorize'
require 'forwardable'
require 'io/console'

class Interface
  extend Forwardable

  CRLF = "\033[1B\033[80D"

  def_delegator :@player, :playlist

  def initialize(player)
    @player = player
    @quit = false
    @current_page = 1
    @lock_scroll = false

    init_player_events
  end

  def loop
    clear_screen

    draw
    process_command STDIN.getch while @quit == false
    @player.stop
  end

  private

  def clear_screen
    print "\033[2J\033[0;0H"
  end

  def redraw
    print "\033[80D\033[21A"
    draw
  end

  def draw
    draw_title
    draw_playlist
    draw_menu
    draw_status
  end

  def draw_title
    print 'Ruby Player 0.1'.center(80).colorize(color: :light_white, background: :red)
    print CRLF * 2
  end

  def draw_playlist
    draw_playlist_title

    if playlist.empty?
      print '-- Empty --'.center(80).colorize(:gray)
      print CRLF
      11.times { print CRLF }
    else
      draw_playlist_items
    end
  end

  def draw_playlist_title
    band = ('=' * 34).colorize(:yellow)
    print " #{band} PLAYLIST #{band}"
    print CRLF * 2
  end

  def draw_playlist_items
    pages = calculate_pages
    offset = calculate_offset(pages)
    paged_songs = playlist.songs.slice(offset, 10)

    width = calculate_width

    paged_songs.each_with_index do |song, index|
      actual_index = index + offset
      song_number = (actual_index + 1).to_s.rjust(width, ' ')

      song_title = "  #{song_number}. #{song.title}".ljust(80, ' ')

      if actual_index == playlist.current_song_index
        print song_title.colorize(color: :light_white, background: :blue)
        print CRLF
      else
        print song_title.colorize(color: :green)
        print CRLF
      end
    end

    (10 - paged_songs.size).times { print "\033[K\033[1B" } if paged_songs.size < 10

    print CRLF
    print "Showing #{offset + 1} - #{offset + paged_songs.size}"\
      " of #{playlist.songs.size}".rjust(80)
    print CRLF
  end

  def draw_menu
    band = ('=' * 36).colorize(:yellow)
    print " #{band} MENU #{band} "
    print CRLF * 2

    print " Z: Previous | X: Play   | C: Pause         | V: Stop      | B: Next#{CRLF}"
    print " A: Add      | R: Remove | N: Previous Page | M: Next Page | Q: Quit#{CRLF}"
    print CRLF
  end

  def draw_status(error = nil)
    print "\033[80D\033[K"

    if error
      print error.colorize(color: :light_white, background: :red)
    elsif @player.playing?
      if @player.paused?
        print ' -- PAUSED --'.colorize(color: :light_yellow, background: :yellow)
      else
        print "Playing: #{@player.song.title} ♪♫ ".colorize(color: :light_green, background: :green)
      end
    else
      print 'Ready'.colorize(color: :light_white, background: :blue)
    end
  end

  def process_command(command)
    @lock_scroll = false

    case command
    when 'q'
      @quit = true
    when 'n'
      @current_page -= 1
      @lock_scroll = true
      redraw
    when 'm'
      @current_page += 1
      @lock_scroll = true
      redraw
    when 'z'
      @player.play_previous
    when 'x'
      @player.play
    when 'c'
      @player.pause
    when 'v'
      @player.stop
    when 'b'
      @player.play_next
    else
      draw_status "ERROR: Unknown command: #{command.upcase}"
    end
  end

  def init_player_events
    redraw_status = lambda do
      draw_status
    end

    @player.playback_started_event = lambda do
      redraw
    end

    @player.playback_stoped_event = redraw_status
    @player.playback_paused_event = redraw_status
    @player.playback_resumed_event = redraw_status

    @player.playback_error_event = lambda do |error|
      draw_status error
    end
  end

  def calculate_pages
    (playlist.size / 10.0).ceil
  end

  def calculate_offset(pages)
    return [playlist.current_song_index - 5, 0].max unless @lock_scroll

    @current_page = pages if @current_page > pages
    @current_page = 1 if @current_page < 1

    offset = @current_page * 10 - 10
    offset.negative? ? 0 : offset
  end

  def calculate_width
    (playlist.size + 1).to_s.size
  end
end
