require 'sketchup.rb'
require 'extensions.rb'

module CommunityExtensions

	module MyTestPlugins

		unless file_loaded?(__FILE__)

			# Establish the extension path
			ex_path = File.join(File.dirname(__FILE__), "my_testplugins", "main.rb")

			# Create the extension
			ex = SketchupExtension.new("Test Plugins", ex_path)
			ex.description = "Suite of Test Plugins"
			ex.version = "0.0.1"
			ex.copyright = "Dan Smith © 2018"
			ex.creator = "Dan Smith"

			# Register to extension with Sketchup so it is discoverable
			# in the Preferences panel
			Sketchup.register_extension(ex, true)

			file_loaded(__FILE__)

		end

	end # module MyTestPlugoins

end # module CommunityExtensions