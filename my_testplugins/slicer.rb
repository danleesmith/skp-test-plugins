module CommunityExtensions::ScenarioModeller

	def self.slicer

		# Define user inputs
		prompts = ["Ground Floor Height", "Upper Level Height"]
		defaults = [4.m, 3.5.m]
		input = UI.inputbox(prompts, defaults, "Slicer Parameters")

		# Set level height
		levelHeightGround = input[0]
		levelHeightUpper = input[1]

		# Get a handle to the first object in the selection set
		model = Sketchup.active_model
		entities = model.active_entities
		selection = model.selection

		# Loop through all entities in the selection
		selection.each do |entity|

			# Test is the entity is both a Group and has the name 'mass'
			if entity.is_a?(Sketchup::Group) && entity.name == 'mass'

				# Explicity name the entity as mass
				mass = entity

				# Create a building group that will contain the level slices
				building = Sketchup.active_model.entities.add_group(mass)
				building.name = "building"

				# Grab the mass proxy object for the slicing operation
				proxy_mass = building.entities[-1]

				# Grab the bounding box of the proxy mass and store its
				# minimum point position
				bbx = proxy_mass.bounds
				min_pos = bbx.min

				# Set the total building height to be the depth of the
				# bounding box
				building_height = bbx.depth

				# Compute the number of levels
				levels = ((building_height - levelHeightGround)  / (levelHeightUpper - 1)).floor + 1

				# Increment the floor level each iteration by the level height
				floor_level = 0

				# For each level number perfrom the slicing operation
				(0..levels).each do |i|

					if i == 0

						# Set Level Height by Index
						levelHeight = levelHeightGround

						# Set floor level translation parameters
						floor_vector = Geom::Vector3d.new(0, 0, 0)
						trans = Geom::Transformation.translation(floor_vector)

					else

						# Set Level height by Index
						levelHeight = levelHeightUpper

						# Set floor level translation parameters
						floor_vector = Geom::Vector3d.new(0, 0, floor_level)
						trans = Geom::Transformation.translation(floor_vector)

					end

					# Create a new level group within the building group
					level_slice = building.entities.add_group

					# Set the corners of the slicing object to the bounding box
					corners = [bbx.corner(0), bbx.corner(2), bbx.corner(3), bbx.corner(1)]

					# Add the new face to the level group and create level geometry
					face = level_slice.entities.add_face(corners)
					face.pushpull(-levelHeight)

					# Move the level group up to the correct height
					level_slice.move!(trans)

					# Slice the level group from the building mass proxy and
					# keep the intersection as the final level geometry
					level = proxy_mass.copy.intersect(level_slice)
					level.name = "level_" + i.to_s

					# Increment the floor level height through each step
					floor_level += levelHeight

				end # End Level Creation

				mass.erase!

			end # Selection Entities

		end # Selection

	end # Slicing Defenition

end # module CommunityExtensions::ScenarioModeller