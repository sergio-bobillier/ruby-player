# frozen_string_literal: true

require 'io/console'

class Interface
  def initialize(player)
    @player = player
    @page = 1
    @quit = false
    @auto_scroll = true

    init_player_events
  end

  def loop
    process_command prompt while @quit == false

    @player.stop
  end

  private

  def menu
    page = @auto_scroll ? nil : @page
    @player.playlist.print page

    puts "\nCommands:\n"
    puts ' Z: Previous | X: Play   | C: Pause         | V: Stop      | B: Next'
    puts ' A: Add      | R: Remove | N: Previous Page | M: Next Page | Q: Quit'
  end

  def prompt
    menu
    STDIN.getch
  end

  def process_command(command)
    unless %w[z x c v b a r n m q ll].include?(command)
      puts "\nERROR: Unknown command: #{command.upcase}\n\n"
    end

    @auto_scroll = true

    case command
    when 'q'
      @quit = true
    when 'n'
      @page -= 1
      @page = [1, @page].max
      @auto_scroll = false
    when 'm'
      @page += 1
      @page = [@player.playlist.pages, @page].min
      @auto_scroll = false
    when 'x'
      @player.play
    when 'v'
      @player.stop
    when 'b'
      @player.play_next
    when 'll'
      puts Thread.list.inspect
    end
  end

  def init_player_events
    @player.next_song_event = lambda do
      menu
    end
  end
end
