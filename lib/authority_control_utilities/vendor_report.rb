module AuthorityControl
  module UnlinkedHeadings
    # The report contains some misc header lines and blank lines which are
    # ignored. Substantive lines consist of a line containing a bib record number
    # followed by a line representing the marc field / heading.
    # For example:
    #   .b14181587
    #   +100 1  $6880-01$aZilʹbersdorf, E. A.$q(Evgeniĭ)$etranslator
    class VendorReport
      def initialize(report)
        if report.respond_to?(:read)
          @report = report
        else
          @report = File.open(report, encoding: 'utf-8')
        end
      end

      # Iterates through the Headings included in the report.
      def each
        unless block_given?
          return self.enum_for(:each)
        else
          awaiting_heading = false
          h = nil
          @report.each do |line|
            next unless line[0..1] == '.b' || awaiting_heading
            if awaiting_heading
              h.heading = line.rstrip
              awaiting_heading = false
              yield h
            else
              h = Heading.new(bnum: line.rstrip[1..-2])
              awaiting_heading = true
            end
          end
        end
      end

      # For each heading, reports bnum, status, and processed field content.
      def report_for_openrefine(outfile = STDOUT)
        out = if outfile.respond_to?(:write)
                outfile
              else
                File.open(outfile, 'w:utf-8')
              end

        # openrefine script needs heading written to "Name" field
        out.write("#{%w[Bnum Status Name].join("\t")}\n")
        each do |heading|
          out.write(
            "#{["#{heading.bnum}a", heading.status, heading.clean_heading].join("\t")}\n"
          )
        end

        nil
      end

      # For headings with zero $a or multiple $a, reports bnum and unprocessed
      # field content.
      def subfield_a_count_report(outfile = STDOUT)
        out = if outfile.respond_to?(:write)
                outfile
              else
                File.open(outfile, 'w:utf-8')
              end

        out.write("#{%w[Bnum Heading].join("\t")}\n")
        each do |heading|
          next unless heading.subfield_a_count_problem?
          out.write(
            "#{["#{heading.bnum}a", heading.heading].join("\t")}\n"
          )
        end

        nil
      end
    end
  end
end
