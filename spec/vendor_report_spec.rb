require 'spec_helper'

module AuthorityControl
  module UnlinkedHeadings
    RSpec.describe VendorReport do
      let (:file) { 'spec/data/nchipers.txt.sample'}
      let (:report) { VendorReport.new(file) }

      describe '#each' do
        it 'yields Heading objects' do
          expect(report.each.first).to be_a(Heading)
        end

        it 'yields an object for each heading reported' do
          expect(report.each.to_a.length).to eq(3)
        end
      end

      describe '#report_for_openrefine' do
        it 'writes a report suitable for openrefine lc reconciliation' do
          output = <<~OUT
            Bnum\tStatus\tName
            b2101490a\tunsuppressed\tA. C. y V
            b4943680a\tunsuppressed\tAdams, Flick (Fictitious character)
            b1418158a\tunsuppressed\tZvegintsova, Ekaterina
          OUT
          io = StringIO.new('')
          report.report_for_openrefine(io)
          expect(io.string).to eq(output)
        end
      end

      describe '#subfield_a_count_report' do
        it 'reports headings with not-exactly-one $a' do
          input = <<~IN
            .b2101490x
            $a problem $a problem
            .b3101490x
            $b problem $b problem
            .b4101490x
            $a fine $b fine
          IN
          output = <<~OUT
            Bnum\tHeading
            b2101490a\t$a problem $a problem
            b3101490a\t$b problem $b problem
          OUT
          io = StringIO.new('')
          VendorReport.new(StringIO.new(input)).subfield_a_count_report(io)
          expect(io.string).to eq(output)
        end
      end
    end
  end
end
