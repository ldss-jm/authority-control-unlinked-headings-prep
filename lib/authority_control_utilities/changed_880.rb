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

  # The marcive report indicates original fields with a leading "+" and
  # changed fields with a leading "-", but we expect and rely on a sequence of:
  #   initial/bnum line, original field, changed field, [vernacular field/880]

  # the original non-vernacular existing/changed field
  def original_field
    lines[1]
  end

  # the new/changed non-vernacular field
  def changed_field
    lines[2]
  end

  def ignorable_changes?
    # - discard leading -/+ indicating original/changed fields
    # - ignore $0 contents
    #     per RDM/DMS, we ignore cases where marcive adds an $0, and marcive
    #     will never remove/edit an existing $0. So we do not need to remove
    #     the $0 from the original field; we know all of these fields changed
    #     and that changes cannot happen inside existing $0's.
    original_field[1..-1] == changed_field[1..-1].gsub(/\$0[^$]*/, '')
  end

  def write
    return unless m880?
    return if ignorable_changes?

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
