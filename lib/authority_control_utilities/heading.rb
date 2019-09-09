require 'i18n'
I18n.available_locales = [:en]

module AuthorityControl
  module UnlinkedHeadings
    # Raw unlinked heading data from the marcive report:
    #   .b14181587
    #   +100 1  $6880-01$aZilʹbersdorf, E. A.$q(Evgeniĭ)$etranslator
    class Heading
      attr_reader :bnum
      attr_accessor :heading

      def initialize(bnum: nil, heading: nil)
        @bnum = bnum
        @heading = heading
      end

      # Returns normalized contents of selected subfields
      def clean_heading
        Heading.clean_heading(@heading)
      end

      # Returns current status of bib in Sierra
      def status
        if bib.deleted?
          'deleted'
        elsif bib.suppressed?
          'suppressed'
        else
          'unsuppressed'
        end
      end

      def bib
        @bib ||= Sierra::Record.get(@bnum)
      end

      # Fields should only have one $a
      def subfield_a_count_problem?
        return true if @heading =~ /\$a.*\$a/
        return true unless @heading =~ /\$a/

        false
      end

      def self.clean_heading(heading)
        normalize(subfield_extract(heading))
      end

      # Retain only the subfield contents (i.e. exclude subfield delimiters)
      # of specified subfields. Other subfields are ignored.
      def self.subfield_extract(heading, subfields: %w[a c d q])
        sf_regex = subfields.join('|')
        heading.scan(/(?<=\$(?:#{sf_regex}))([^$]*)/).join(' ')
      end

      def self.normalize(heading)
        I18n.transliterate(heading).gsub(/[,.]$/, '')
      end
    end
  end
end
