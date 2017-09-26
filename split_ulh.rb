# Splits all .ulh files into separate files based
# on index type (author/subject/series) and name type (personal/corporate)
# Discards non-entries and entries for types we don't care about.
#
# Does not otherwise alter records.
#
# Outputs to: [type].ulh.split

workdir = '//ad.unc.edu/lib/common/Authority Control/UnlinkedHeadingsPrep/'

series_ofile = File.open(workdir + 'series.ulh.split', 'w')
pname_ofile = File.open(workdir + 'pname.ulh.split', 'w')
cname_ofile = File.open(workdir + 'cname.ulh.split', 'w')
psubj_ofile = File.open(workdir + 'psubj.ulh.split', 'w')
csubj_ofile = File.open(workdir + 'csubj.ulh.split', 'w')

ofiles = {:series => series_ofile,
          :pname => pname_ofile,
          :cname => cname_ofile,
          :psubj => psubj_ofile,
          :csubj => csubj_ofile
}


puts "splitting files..."
Dir.glob(workdir + '*.ULH') do |ulh_file|
  File.foreach(ulh_file, encoding: 'utf-8') do |line|
    field_code = line[2..4]
    index_type = case field_code
                when /^Y30/ then :series
                when /^X00/ then :pname
                when /^X10/ then :cname
                when /^600/ then :psubj
                when /^610/ then :csubj
                end
    ofiles[index_type] << line if index_type
  end
end

ofiles.values.each { |ofile| ofile.close}

puts "finished successfully. Press [Enter] to exit"
gets
exit