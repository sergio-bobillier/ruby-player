# frozen_string_literal: true

# Process command line arguments
class ArgumentProcessor
  def initialize(playlist)
    @playlist = playlist
  end

  def process(argument)
    file = Pathname.new(argument)
    raise FileNotFoundError, "#{file} not found!" unless file.exist?

    file.directory? ? process_directory(file) : process_file(file)
  end

  private

  def process_directory(directory)
    directory.entries.sort.each do |entry|
      entry_name = entry.basename.to_s
      next if ['.', '..'].include?(entry_name)

      entry = directory.join(entry)

      entry.directory? ? process_directory(entry) : process_file(entry)
    end
  end

  def process_file(file)
    extension = file.extname.downcase
    return unless extension == '.mp3'

    @playlist << file
  end
end
