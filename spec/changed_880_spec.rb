#encoding: utf-8

require 'spec_helper'

module AuthorityControl
  RSpec.describe Changed880 do
    let (:c880) { Changed880.new(".b20857445, 38447\n") }

    context 'when containing an 880' do
      let (:c880) do
        c = Changed880.new(".b20857445, 38447\r\n")
        c.lines << "-880\r\n".rstrip
        c
      end

      describe '#m880?' do
        it 'is true' do
          expect(c880.m880?).to be true
        end
      end

      describe '#write' do
        it "writes entry's lines and a blank line to output file for #script" do
          i = StringIO.new
          Changed880.outfiles[:other] = i
          c880.write
          expect(i.string).to eq(".b20857445, 38447\n-880\n\n")
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

    describe 'script' do
      it ' = :cjk when containing Han, Hangul characters' do
        c880.lines << "-880  0 $6830-06/$1$a華崗叢書"
      end

      it ' = :cjk when containing Katakana characters' do
        c880.lines << "-880  0 $6830-06/$1$aグ"
      end

      it ' else, = :cyrillic when containing Cyrillic characters' do
        c880.lines << "-880  0 $6830-06/$1$aСовременная"
      end

      it ' else, = :arabic when containing Arabic characters' do
        c880.lines << "-880  0 $6830-06/$1$aلة قض"
      end

      it 'else, = :other' do
        c880.lines << "-880  0 $6830-06/$1$afoo"
      end
    end
  end
end
