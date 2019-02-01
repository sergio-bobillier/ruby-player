require 'pathname'

require 'byebug'

require_relative './errors/file_not_found_error'
require_relative './argument_processor'
require_relative './command_processor'
require_relative './player'
require_relative './playlist'

playlist = Playlist.new
playlist << '/home/sergio/Trash/Fatal Frame OST - Little Ghost Helping.mp3'

if ARGV.any?
  begin
    ArgumentProcessor.new(playlist).process(ARGV.first)
  rescue FileNotFoundError => fnf_error
    puts "ERROR: #{fnf_error.message}"
    exit 1
  end
end

Thread.abort_on_exception = true

player = Player.new(playlist)

command_processor = CommandProcessor.new(player)
command_processor.loop

puts "\n -- Bye! --"
