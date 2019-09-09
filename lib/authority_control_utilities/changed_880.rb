#encoding: utf-8

class Changed880
  attr_accessor :lines
  def initialize(line)
    @lines = [line.rstrip]
    @bnum = line.match(/^\.(b[0-9x]*)/).captures.first
  end

  def m880?
    true if lines.find { |line| line.match(/^[-+]880/) }
  end

  def write
    return unless m880?

    ofile.write("#{@lines.join("\n")}\n\n")
  end

  def ofile
    Changed880.outfiles[script] ||= File.open("changed_880s_#{script}.txt", 'w')
  end

  def script
    return unless m880?

    if lines.find { |line| line.match(/\p{Han}|\p{Hangul}|\p{Katakana}/) }
      :cjk
    elsif lines.find { |line| line.match(/\p{Cyrillic}/) }
      :cyrillic
    elsif lines.find { |line| line.match(/\p{Arabic}/) }
      :arabic
    else
      :other
    end
  end

  def self.outfiles
    @outfiles ||= {}
  end

  def self.process(infiles)
    Changed880.delete_reports
    infiles.each do |infile|
      Changed880.extract(infile)
    end
    Changed880.outfiles.each_value { |file| file.close }
  end

  def self.extract(infile)
    io = if infile.respond_to? :readlines
           infile
         else
           File.open(infile)
         end

    entry = nil
    File.readlines(io).each do |line|
      if line.start_with?('.b')
        entry&.write
        entry = Changed880.new(line)
      elsif line.match(/^$/)
        entry&.write
        entry = nil
      elsif entry
        entry.lines << line.rstrip
      else
        next
      end
    end

    io.close
  end

  def self.delete_reports
    Dir.glob('changed_880s_*.txt') { |file| File.delete(file) }
  end
end
