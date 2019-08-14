module UnlinkedHeadings
  class CLI < Thor
    desc 'process <input> <output>', 'format marcive report for openrefine'
    long_desc <<-LONGDESC
    <input>is the filename of an unlinked headings report from Marcive
    \x5<output> is the output filename.

    Marcive ULH entries will be output as single rows containing bnum,
    sierra suppression/deletion status, and normalized/cleaned heading
    contents.
    LONGDESC
    def process(marcive_report, output)
      VendorReport.new(marcive_report).report_for_openrefine(output)
    end

    desc 'subfield_a <input> <output>', 'list entries with zero or multiple $a'
    long_desc <<-LONGDESC
    <input> is the filename of an unlinked headings report from Marcive
    \x5<output> is the output filename.

    ULH entries containing no $a or multiple $a will be listed with their bnum.
    LONGDESC
    def subfield_a_count_report(marcive_report, output)
      VendorReport.new(marcive_report).subfield_a_count_report(output)
    end
  end
end
