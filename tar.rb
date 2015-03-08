require 'rubygems/package'

class TarStream

  extend Forwardable
  def_delegators :@writer, :close, :flush

  def initialize out_stream
    @writer = Gem::Package::TarWriter.new out_stream
  end

  def add data, tar_path
    mode = 33204
    @writer.add_file_simple tar_path, mode, data.length do |fh|
      fh.write data
    end
  end
end
