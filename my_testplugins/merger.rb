module CommunityExtensions::MyTestPlugins

	def self.merger

		# Get a handle to the first object in the selection set
		model = Sketchup.active_model
		entities = model.active_entities
		selection = model.selection

		blast = []

		selection.each do |entity|

			if entity.is_a?(Sketchup::Group) && entity.name == 'building'

				building_entities = entity.entities
				levels = []

				building_entities.each do |building_entity|

					if building_entity.is_a?(Sketchup::Group) && building_entity.name.start_with?('level_')

						# Insert each level into the levels array in order
						levels.push(building_entity.copy)

					end

				end
				

				a = levels[0]
				levels.shift

				# Perform the merge operation until all levels are merged
				until levels.length == 1 || levels.empty? || levels.nil?

					# Perform merge (solid union operation)
					b = levels[0]
					levels.shift

					a = a.copy.union(b)

				end

				mass = model.entities.add_group(a.copy.entities.to_a)

			end

			blast.push(entity)

		end

		selection.clear

		model.active_entities.erase_entities(blast)

	end # def Merger

end # module CCommunityExtensions::MyTestPlugins