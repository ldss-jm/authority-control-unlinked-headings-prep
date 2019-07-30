require 'spec_helper'

module UnlinkedHeadings
  RSpec.describe Heading do

    describe '#clean_heading' do
      it 'returns normalized data from relevant subfields' do
        heading = '+100 1  $6880-01$aZilʹbersdorf, E. A.$q(Evgeniĭ)'
        expect(Heading.new(heading: heading).clean_heading).to eq(
          'Zilbersdorf, E. A. (Evgenii)'
        )
      end
    end

    describe '#status' do
      it 'reports the status of the bib in Sierra' do
        bnum = Sierra::Data::Bib.first.bnum
        expect(Heading.new(bnum: bnum).status).to match(/(un)?suppressed/)
      end

      context 'when the Sierra record is deleted' do
        it 'is "deleted"' do
          rec = Sierra::Data::Metadata.
                where(record_type_code: 'b').
                exclude(deletion_date_gmt: nil).
                first
          bnum = "b#{rec.record_num}"
          expect(Heading.new(bnum: bnum).status).to eq 'deleted'
        end
      end

      context 'when the Sierra record is suppressed' do
        it 'is "suppressed"' do
          bnum = Sierra::Data::Bib.first(is_suppressed: 't').bnum
          expect(Heading.new(bnum: bnum).status).to eq 'suppressed'
        end
      end

      context 'when the Sierra record is unsuppressed' do
        it 'is "unsuppressed"' do
          bnum = Sierra::Data::Bib.first(is_suppressed: 'f').bnum
          expect(Heading.new(bnum: bnum).status).to eq 'unsuppressed'
        end
      end
    end

    describe '#subfield_a_count_problem?' do
      context "when heading has zero $a's" do
        it 'is true' do
          heading = '$bfoo$bbar'
          expect(Heading.new(heading: heading).subfield_a_count_problem?).to be true
        end
      end
      context "when heading has multiple $a's" do
        it 'is true' do
          heading = '$afoo$abar'
          expect(Heading.new(heading: heading).subfield_a_count_problem?).to be true
        end
      end

      context 'when heading has exactly one $a' do
        it 'is false' do
          heading = '$afoo$bbar'
          expect(Heading.new(heading: heading).subfield_a_count_problem?).to be false
        end
      end

    end

    describe '.subfield_extract' do
      let(:line) { '+700 1  $aZoeller, Edward Victor,$d1857-1944,$ehonoree.'}
      it 'extracts subfield data from a vendor report line' do
        expect(Heading.subfield_extract(line)).to eq('Zoeller, Edward Victor, 1857-1944,')
      end

      it 'includes only subfields of interest' do
        expect(Heading.subfield_extract(line, subfields: ['d', 'e'])).to eq(
          '1857-1944, honoree.'
        )
      end

      it 'default subfields of interest are: a, c, d, q' do
        line = '$aa$b_$cc$dd$qq$x_'
        expect(Heading.subfield_extract(line)).to eq('a c d q')
      end
    end

    describe '.normalize' do
      it 'transliterates heading' do
        str = '$aZilʹbersdorf, E. A.$q(Evgeniĭ Aleksandrovich)'
        expect(Heading.normalize(str)).to eq ('$aZilbersdorf, E. A.$q(Evgenii Aleksandrovich)')
      end

      it 'removes trailing commas/periods' do
        str = '$aZilʹbersdorf, E. A.'
        expect(Heading.normalize(str)).to eq ('$aZilbersdorf, E. A')
      end
    end
  end
end
