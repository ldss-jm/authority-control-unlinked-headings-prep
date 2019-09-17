#encoding: utf-8

require 'spec_helper'

module AuthorityControl
  RSpec.describe Changed880 do
    let(:c880) { Changed880.new(".b20857445, 38447\n") }

    context 'when containing an 880' do
      let(:c880) do
        c = Changed880.new(".b20857445, 38447\r\n")
        c.lines << '+830  0 $6880-04$aSilsilat al-ʻAnqāʼ ;$v10-11.'
        c.lines << '-830  0 $6880-04$aSilsilat al-ʻAnqāʼ ;'\
                   '$0http://id.loc.gov/authorities/names/no2002019550$v10-11.'
        c.lines << "-880\r\n".rstrip
        c
      end

      describe '#m880?' do
        it 'is true' do
          expect(c880.m880?).to be true
        end
      end

      describe '#write' do
        context 'when substantive changes exist' do
          it "writes entry's lines and a blank line to output file for #script" do
            c880 = Changed880.new(".b20857445, 38447\r\n")
            c880.lines << '+830  0 $6880-04$afoo'
            c880.lines << '-830  0 $6880-04$abar'
            c880.lines << "-880\r\n".rstrip

            i = StringIO.new
            Changed880.outfiles[:other] = i
            c880.write
            expect(c880.ignorable_changes?).to be false
            expect(i.string).to eq(
              ".b20857445, 38447\n+830  0 $6880-04$afoo\n"\
              "-830  0 $6880-04$abar\n-880\n\n"
            )
          end
        end

        context 'when changes are ignorable' do
          it 'writes nothing' do
            c880 = Changed880.new(".b20857445, 38447\r\n")
            c880.lines << '+830  0 $6880-04$aSilsilat al-ʻAnqāʼ ;$v10-11.'
            c880.lines << '-830  0 $6880-04$aSilsilat al-ʻAnqāʼ ;'\
                       '$0http://id.loc.gov/authorities/names/no2002019550$v10-11.'
            c880.lines << "-880\r\n".rstrip

            i = StringIO.new
            Changed880.outfiles[:other] = i
            c880.write
            expect(c880.ignorable_changes?).to be true
            expect(i.string).to be_empty
          end
        end
      end
    end

    context 'when NOT containing an 880' do
      describe '#m880?' do
        it 'is false' do
          expect(c880.m880?).to be_falsy
        end
      end

      describe '#write' do
        it 'writes nothing' do
          i = StringIO.new
          Changed880.outfiles[:other] = i
          c880.write
          expect(i.string).to be_empty
        end
      end
    end

    describe '#original_field' do
      it 'returns the original non-vernacular field' do
        c880.lines += ["+830  0 $afoo\n", "+830  0 $abar\n"]
        expect(c880.original_field).to eq("+830  0 $afoo\n")
      end
    end

    describe '#changed_field' do
      it 'returns the changed non-vernacular field (post-changes)' do
        c880.lines += ["+830  0 $afoo\n", "+830  0 $abar\n"]
        expect(c880.changed_field).to eq("+830  0 $abar\n")
      end
    end

    describe '#ignorable_changes?'  do
      context 'when changes are only marcive adding a $0' do
        it 'is true' do
          c880.lines << '+830  0 $6880-04$aSilsilat al-ʻAnqāʼ ;$v10-11.'
          c880.lines << '-830  0 $6880-04$aSilsilat al-ʻAnqāʼ ;'\
                     '$0http://id.loc.gov/authorities/names/no2002019550$v10-11.'
          c880.lines << "-880\r\n".rstrip
          expect(c880.ignorable_changes?).to be true
        end
      end

      context 'when changes are NOT only marcive adding a $0' do
        it "is false" do
          c880.lines << '+830  0 $6880-04$afoo'
          c880.lines << '-830  0 $6880-04$abar'
          c880.lines << "-880\r\n".rstrip
          expect(c880.ignorable_changes?).to be false
        end
      end
    end

    describe 'script' do
      it ' = :cjk when containing Han, Hangul characters' do
        c880.lines << "-880  0 $6830-06/$1$a華崗叢書"
        expect(c880.script).to eq :cjk
      end

      it ' = :cjk when containing Katakana characters' do
        c880.lines << "-880  0 $6830-06/$1$aグ"
        expect(c880.script).to eq :cjk
      end

      it ' else, = :cyrillic when containing Cyrillic characters' do
        c880.lines << "-880  0 $6830-06/$1$aСовременная"
        expect(c880.script).to eq :cyrillic
      end

      it ' else, = :arabic when containing Arabic characters' do
        c880.lines << "-880  0 $6830-06/$1$aلة قض"
        expect(c880.script).to eq :arabic
      end

      it 'else, = :other' do
        c880.lines << "-880  0 $6830-06/$1$afoo"
        expect(c880.script).to eq :other
      end
    end
  end
end
