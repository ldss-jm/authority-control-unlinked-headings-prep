require 'sierra_postgres_utilities'
require 'thor'

$LOAD_PATH.unshift(__dir__) unless $LOAD_PATH.include?(__dir__)

module UnlinkedHeadings
  autoload :VERSION, 'unlinked_headings/version'
  autoload :Heading, 'unlinked_headings/heading'
  autoload :VendorReport, 'unlinked_headings/vendor_report'
  autoload :CLI, 'unlinked_headings/cli'
end
