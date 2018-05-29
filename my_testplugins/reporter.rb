module CommunityExtensions::ScenarioModeller

	def self.reporter

		# Set up vector for face orientation test
		up_vec = Geom::Vector3d.new(0, 0, 1)
		total_gfa = 0

		# Get a handle to the first object in the selection set
		model = Sketchup.active_model
		entities = model.active_entities
		selection = model.selection

		selection.each do |entity|

			if entity.is_a?(Sketchup::Group) && entity.name == 'building'

				building_entities = entity.entities

				building_gfa = 0

				building_entities.each do |building_entity|

					if building_entity.is_a?(Sketchup::Group) && building_entity.name.start_with?('level_')

						level_entities = building_entity.entities

						level_faces = level_entities.grep(Sketchup::Face)

						level_faces.each do |face|

							normal = face.normal

							if normal.parallel?(up_vec) && !normal.samedirection?(up_vec)

								building_gfa += (face.area * 0.00064516)

							end # End Level GFA

						end # Level Faces

					end # Building Entities Test

				end # Building Entities

				total_gfa += building_gfa

				puts entity.name, building_gfa.to_s

			end # Selection Entities Test

		end # Selection Entities

		puts 'total_gfa:', total_gfa.to_s

	end # Defenition

end # module CommunityExtensions::ScenarioModeller