require 'sierra_postgres_utilities'
require 'thor'

$LOAD_PATH.unshift(__dir__) unless $LOAD_PATH.include?(__dir__)

module AuthorityControl
  autoload :VERSION, 'authority_control_utilities/version'
  autoload :Changed880, 'authority_control_utilities/changed_880'
  autoload :CLI, 'authority_control_utilities/cli'

  module UnlinkedHeadings
    autoload :Heading, 'authority_control_utilities/heading'
    autoload :VendorReport, 'authority_control_utilities/vendor_report'
  end
end
