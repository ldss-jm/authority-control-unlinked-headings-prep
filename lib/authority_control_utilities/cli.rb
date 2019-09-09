module AuthorityControl
  class CLI < Thor
    desc 'ulh_process <input> <output>', 'format marcive report for openrefine'
    long_desc <<-LONGDESC
    <input>is the filename of an unlinked headings report from Marcive
    \x5<output> is the output filename.

    Marcive ULH entries will be output as single rows containing bnum,
    sierra suppression/deletion status, and normalized/cleaned heading
    contents.
    LONGDESC
    def ulh_process(marcive_report, output)
      UnlinkedHeadings::VendorReport.new(marcive_report).report_for_openrefine(output)
    end

    desc 'subfield_a <input> <output>', 'list entries with zero or multiple $a'
    long_desc <<-LONGDESC
    <input> is the filename of an unlinked headings report from Marcive
    \x5<output> is the output filename.

    ULH entries containing no $a or multiple $a will be listed with their bnum.
    LONGDESC
    def subfield_a_count_report(marcive_report, output)
      UnlinkedHeadings::VendorReport.new(marcive_report).subfield_a_count_report(output)
    end

    desc 'extract_880s <input>', 'write changed 880s by character script'
    long_desc <<-LONGDESC
    <input> is a filename (wildcards/globbing allowed) for marcive changed
    headings reports.

    Entries pertaining to 880s are written to separate arabic/cjk/cyrillic/other
    files, e.g. changed_880s_arabic.txt

    Example usage:
    \x5  exe/acu extract_880s NCHIOBSO01.TXT
    \x5  exe/acu extract_880s NCHIOBSO*
    LONGDESC
    def extract_880s(*infiles)
      Changed880.process(infiles)
    end
  end
end
