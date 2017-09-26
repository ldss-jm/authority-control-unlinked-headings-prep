# Takes all *.ulh.split files provided,
# preps/normalizes records and searches against Sierra postgres
# writes matches to ouput based on index/type, formatted for openrefine lookup
# writes additional info to files in debug folder

#potential (non-essential) enhancements
# todo unsure
  #todo, 10,1000 should normalize to 10000 rather than 10      1000
  # can we at least make sure YYYY-YYYY is done correctly?


require 'csv'
load '../postgres_connect/connect.rb'
require 'i18n'
I18n.available_locales = [:en]
c = Connect.new

workdir = '//ad.unc.edu/lib/common/Authority Control/UnlinkedHeadingsPrep/'

# toggles query and output to provide info on whether recs are supp/notauthor
# or not. seems like too few recs for this to matter, and increases
# query overhead, so suggest this is left disabled
#
detect_suppress = false

if !detect_suppress
  base_query = <<-SQL
  select phe.record_id from sierra_view.phrase_entry phe
  inner join sierra_view.bib_record b on b.id = phe.record_id
  where
  (phe.index_tag || phe.index_entry) like '{INDEXTAG}{FIELDSTRING}' || '%'
  limit 1
  SQL
else
  base_query = <<-SQL
  (
    (select 'unsupp/autho' as status
    from sierra_view.phrase_entry phe
    inner join sierra_view.bib_record b on b.id = phe.record_id
    and b.bcode3 not in ('d', 'n', 'c', 'x')
    where
    (phe.index_tag || phe.index_entry) like '{INDEXTAG}{FIELDSTRING}' || '%'
    limit 1)

    UNION

    (select 'supp/notautho' as status
    from sierra_view.phrase_entry phe
    inner join sierra_view.bib_record b on b.id = phe.record_id
    and b.bcode3 in ('d', 'n', 'c', 'x')
    where
    (phe.index_tag || phe.index_entry) like '{INDEXTAG}{FIELDSTRING}' || '%'
    limit 1)
  )
  ORDER BY status DESC
  limit 1
  SQL
end




# Create a mapping for ANSEL/Marc-8 bytes to unicode.
# Where we don't like how the unicode will be transliterated, we directly
# map it to the desired transliteration
#
mp = {
                   # char : transliteration
  161 => "\u0141", # Ł L
  162 => "\u00D8", # Ø O
  163 => "\u0110", # Đ D
  164 => "\u00DE", # Þ Th
  165 => "\u00C6", # Æ AE
  166 => "\u0152", # Œ OE
  169 => '', # "\u266D", # ♭ ?
  170 => '', # "\u00AE", # ® ?
  171 => '', # "\u00B1", # ± ?
  172 => "O",      # Ơ ? [manually map to O]
  173 => "U",      # Ư ? [manually map to U]
  177 => "\u0142", # ł l
  178 => "\u00F8", # ø o
  179 => "\u0111", # đ d
  180 => "\u00FE", # þ th
  181 => "\u00E6", # æ ae
  182 => "\u0153", # œ oe
  184 => "\u0131", # ı i
  185 => "\u00A3", # £ ? # sierra drops see b6951652
  186 => "\u00F0", # ð d
  188 => "o",      # ơ ? [manually map to o]
  189 => "u",      # ư ? [manually map to u]
  193 => "\u2113", # ℓ ? # l?
  194 => '', # "\u2117", # ℗ ?
  195 => '', # "\u00A9", # © ?
  196 => "\u266F", # ♯ ? drop or use #? b2977774
  199 => "\u00DF"
}


def remove_punct(str)
  str = str.gsub('&', ' and ') # we need the spaces around and; dupe spaces will be removed
  # manually define punctuation to be removed, since some needs to be kept
  # keep:
  #   +%$#@
  # remove:
  str = str.gsub(/["']/, '')
  # replace with spaces:
  str = str.gsub(/[!\&'()*,\-.\/:;<=>?\[\\\]^_`{|}~]/, ' ').rstrip
  str.gsub(/  +/, ' ').lstrip
end



def pad_numbers(str)
  regexp = /
    (?<![\+#$])             # not when preceded by these chars
    \b
    ([0-9]+)                # main number block, which gets justified
    ([^ [:digit:]][^ ]*)?   # subsequent attached chars, which we dont justify
  /x
  str.gsub(regexp) do |match|
    $2 ? $1.rjust(8, ' ') + $2 : $1.rjust(8, ' ')
  end
end



def trunc_str(str)
  # truncate str so it's less than 124 chars, and don't let it break any
  #   words (i.e. drop any resulting word fragments)
  # strings with many multibyte chars get more heavily truncated
  #   elsewhere. 123 seems fine for general records. e.g. where 123
  #   doesn't work 4954879 (but elsewhere-truncation does)
  return str if str.length < 124
  str = str[0..123].
    split(/\b/)[0..-2].
    join('').
    rstrip
end

def normalize(str)
  str = str.downcase.
    gsub(/\u02B9|\u02BB|\uFE20|\uFE21/, '') # remove select punct
  str = I18n.transliterate(str)
  str = pad_numbers(remove_punct(str.downcase))
  trunc_str(str)
end

def to_openrefine(str)
  # takes tab delimited marc string and yields output ready for openrefine
  #   process
  str = "\t#{str}"
  str = I18n.transliterate(str.
    gsub(/[,-](?=\t[et4])/, '.'). # change comma/hyphen before e/t/4 to period
    gsub(/\t[et4].*/, '').        # remove anything after first subfield e/t/4
    gsub(/\t[6].*/, '').          # remove any |6 (may only matter for genre)
    gsub(/[\. ]+$/, '')           # remove trailing spaces/periods
  )
  str.gsub(/\t./, ' ').lstrip # remove subfield delimiters and intial tab
end


#
# DEFINE/OPEN OUTPUT FILES
#
series_ofile = CSV.open(workdir + 'or_series.txt', 'w', col_sep: "\t")
pname_ofile = CSV.open(workdir + 'or_pname.txt', 'w', col_sep: "\t")
cname_ofile = CSV.open(workdir + 'or_cname.txt', 'w', col_sep: "\t")
psubj_ofile = CSV.open(workdir + 'or_psubj.txt', 'w', col_sep: "\t")
csubj_ofile = CSV.open(workdir + 'or_csubj.txt', 'w', col_sep: "\t")
no_matches_ofile = CSV.open(workdir + 'debug/no_matches.debug', 'w', col_sep: "\t")
no_matches_orig = File.open(workdir + 'debug/no_matches_orig.debug', 'w')
discard_ofile = CSV.open(workdir + 'debug/discards.debug', 'w', col_sep: "\t")
unsure_ofile = CSV.open(workdir + 'debug/unsure.debug', 'w', col_sep: "\t")
fail_ofile = File.open(workdir + 'debug/fail.debug', 'w')

ofiles = {
  :series => series_ofile,
  :pname => pname_ofile,
  :cname => cname_ofile,
  :psubj => psubj_ofile,
  :csubj => csubj_ofile,
  :nokey1 => no_matches_ofile,
  :nokey3 => no_matches_orig,
  :nokey2 => discard_ofile,
  :unsure => unsure_ofile,
  :fail => fail_ofile
}

series_debug = CSV.open(workdir + 'debug/series.debug', 'w', col_sep: "\t")
pname_debug = CSV.open(workdir + 'debug/pname.debug', 'w', col_sep: "\t")
cname_debug = CSV.open(workdir + 'debug/cname.debug', 'w', col_sep: "\t")
psubj_debug = CSV.open(workdir + 'debug/psubj.debug', 'w', col_sep: "\t")
csubj_debug = CSV.open(workdir + 'debug/csubj.debug', 'w', col_sep: "\t")
#no_matches_debug = CSV.open('no_matches.debug', 'w', col_sep: "\t")
#discard_debug = CSV.open('discards.debug', 'w', col_sep: "\t")
#unsure_debug = CSV.open('unsure.debug', 'w', col_sep: "\t")
#fail_debug = File.open('fail.debug', 'a')

debug = {
  :series => series_debug,
  :pname => pname_debug,
  :cname => cname_debug,
  :psubj => psubj_debug,
  :csubj => csubj_debug,
# :nokey1 => no_matches_debug,
# :nokey2 => discard_debug,
# :unsure => unsure_debug,
# :fail => fail_debug
}




collect = {}
ofiles.each_key do |index_type|
  collect[index_type] = []
end

blah = []
blah2 = []
puts "running queries..."
Dir.glob(workdir + '*.ulh.split').each do |file|
  File.foreach(file, encoding: 'utf-8') do |line|
    #blah << line
    next if line == "\n"
    orig = line.rstrip
    sierra = line.scrub { |bytes| bytes.bytes.map {|x| mp[x].to_s}.join('') }
    # In some cases a series of invalid encoded characters form a single,
    #   valid, multibyte utf8 character. In which case they won't be scrubbed.
    #   This finds those multibyte chracters (presumably this text should 
    #   generally be ascii-level characters) and splits them up into
    #   constituent bytes e.g. [224, 189, 188]
    sierra.gsub!(/([\u0080-\uFFFF])/) {
      str = ''
      if !mp.values.include?($1) # don't break chars we just mapped to
        $1.bytes.each do |byte|
          str += mp[byte].to_s
        end
      else
        str = $1
      end
      str
    }
    sierra.gsub!("\u001F", "\t")
    sierra.rstrip!
    field_code, *field_contents = sierra.split("\t")
    openrefine = to_openrefine(field_contents.join("\t"))
    field_code = field_code[2..4]
    index_tag = case field_code
                when /^Y/ then 's'
                when /^X/ then 'a'
                when /^6/ then 'd'
                end
    index_type = case field_code
                when /^Y30/ then :series
                when /^X00/ then :pname
                when /^X10/ then :cname
                when /^600/ then :psubj
                when /^610/ then :csubj
                end
    field_content = field_contents.select { |x| x[0] == 'a' }.
                                   map { |x| x[1..-1]}

    if field_content.length != 1
      problem = 'skip_multi_subfield_a'
      status = c.results.values.empty? ? 'na' : c.results.values[0][0]
      debug[index_type] << [
        field_code, field_contents.join("|"), index_tag, '', '', problem,
        openrefine, sierra
      ]
      if detect_suppress
        collect[index_type] << [status, openrefine]
      else
        collect[index_type] << [openrefine]
      end
      ofiles[:unsure] <<
        [field_code, field_contents.join("|"), index_tag, '', '', problem]
      ofiles[:fail] << orig  + "\n"
      next
    end

    field_content = field_content[0]
    norm_field_content = normalize(field_content)
    myquery = base_query.
      gsub('{INDEXTAG}', index_tag).
      gsub('{FIELDSTRING}', norm_field_content)
    c.make_query(myquery)

    problem = ''
    if c.results.values.empty?
      #check for problematic field_content, write to include if found
      if field_content =~ /[0-9][,-][0-9]/
        problem = 'skip_comma_dash_number'
      elsif field_content =~ /\e..\e./
        problem = 'contains_literal'
        openrefine.gsub!(/\e.(.)\e./, '\1') # strip the literal-demarking chars 
      else
        #try with length = 60
        trunc_norm_field_content = norm_field_content[0..60]
        myquery = base_query.
          gsub('{INDEXTAG}', index_tag).
          gsub('{FIELDSTRING}', trunc_norm_field_content)
        c.make_query(myquery)
        if c.results.values.empty?
          # write no_results values to not found report
          no_matches_ofile << [index_tag, norm_field_content, field_content]
          no_matches_orig << orig + "\n"
          ofiles[:fail] << orig + "\n"
          next
        end
        problem = 'heavily_truncated'
      end
      ofiles[:unsure] << [
        field_code, field_content, index_tag, norm_field_content, '', problem,
        openrefine, sierra
      ]
      ofiles[:fail] << orig  + "\n"
    end # c.results.values.empty?

    # write entries with matches to reports; separate reports per index_type
    # write problem entries with no matches to same reports (err on side
    #   of inclusion)
    status = c.results.values.empty? ? 'na' : c.results.values[0][0]
    debug[index_type] << [
      field_code, field_content, index_tag, norm_field_content, status,
      problem, openrefine, sierra
    ]
    if detect_suppress
      collect[index_type] << [status, openrefine]
    else
      collect[index_type] << [openrefine]
    end
  end
end

puts "writing files"
collect.each_key do |index_type|
  seen = false
  if detect_suppress
    headers = ['Status', 'Name']
  else
    headers = ['Name']
  end
  # uniq, but don't sort. retain order of ULH file.
  collect[index_type].uniq.each do |entry|
    ofiles[index_type] << headers if !seen
    ofiles[index_type] << entry if !entry.empty?
    seen = true
  end
end
(ofiles.values + debug.values).each { |ofile| ofile.close }
sleep 5

puts "cleaning up..."
(ofiles.values + debug.values).each do |ofile|
  begin
    File.delete(ofile.path) if File.zero?(ofile.path)
  rescue NoMethodError
  end
end

puts "finished successfully. Press [Enter] to exit"
gets
exit







# This is just testing junk
#
=begin
# '1st4sport (Firm)' => '       1st4sport firm'
#20th Century Fox Home Entertainment España => '      20th century fox home entertainment espana'
#2159-5011 Practising Law Institute. => '    2159     5011 practising law institute'
#2.19 Skiffle Group. '       2       19 skiffle group'
# '       5x5 band'
#1+1 (Don & Marion) (Musical group) '       1+1 don and marion musical group'
'      1+1 don and marion musical group' || '%'\n'
      1+1"
      '       1000 legged worm musical group''
      '+21' > '+21'
=end

# This is just testing junk
#
=begin
if false
  ac = [
    'Ł', 'Ø', 'Đ', 'Þ', 'Æ', 'Œ', 'ʹ', '·', '♭', '®', '±', 'Ơ', 'Ư', 'ʼ', 'ʻ',
'ł', 'ø', 'đ', 'þ', 'æ', 'œ', 'ʺ', 'ı', '£', 'ð', 'ơ', 'ư', '°', 'ℓ', '℗',
'©', '♯', '¿', '¡'
  ]
  acu.each do |char|
    puts char + ' ' + I18n.transliterate(char)
  end
end

acu = [
  "\u0141", "\u00D8", "\u0110", "\u00DE", "\u00C6", "\u0152", "\u02B9",
  "\u00B7", "\u266D", "\u00AE", "\u00B1", "\u01A0", "\u01AF", "\u02BC",
  "\u02BB", "\u0142", "\u00F8", "\u0111", "\u00FE", "\u00E6", "\u0153",
  "\u02BA", "\u0131", "\u00A3", "\u00F0", "\u01A1", "\u01B0", "\u00B0",
  "\u2113", "\u2117", "\u00A9", "\u266F", "\u00BF", "\u00A1"
]
=end