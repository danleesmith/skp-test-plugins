require 'sketchup.rb'
require File.join(File.dirname(__FILE__), "importer.rb")
require File.join(File.dirname(__FILE__), "slicer.rb")
require File.join(File.dirname(__FILE__), "reporter.rb")
# require File.join(File.dirname(__FILE__), "merger.rb")

# Show the ruby console for display and debug
SKETCHUP_CONSOLE.show

module CommunityExtensions::MyTestPlugins

	# Establish UI Protocol
	unless file_loaded?(__FILE__)

		menu = UI.menu("Extensions")
		menu.add_item("Import") { self.importer }
		menu.add_item("Slice") { self.slicer }
		menu.add_item("Report") { self.reporter }
		# menu.add_item("Merge") { self.merger }
		
		file_loaded(__FILE__)

	end # file_loaded

end # module CommunityExtensions::MyTestPlugins