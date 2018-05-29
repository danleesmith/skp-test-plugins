require 'json'

module CommunityExtensions::ScenarioModeller

	# ------------------------------------------------------

	def self.coordToPoint(coord)

		if coord.size == 2

			return Geom::Point3d.new(coord[0], coord[1], 0)

		elsif coord.size == 3

			return Geom::Point3d.new(coord[0], coord[1], coord[2])

		else

			return Geom::Point3d.new(0, 0, 0)

		end

	end # Coordinate to Vector 3 Definition

	# ------------------------------------------------------

	def self.getGeoCentroid(features)

		all_coords = Array.new

		features.each do |feature|

			type = feature["geometry"]["type"]
			parts = feature["geometry"]["coordinates"]

			# ------------------------------------------------------

			if type == "Point"

				coord = parts
				pos = self.coordToPoint(coord)
				all_coords.push(pos)

			# ------------------------------------------------------

			elsif type == "MultiPoint"

				parts.each do |coord|

					pos = self.coordToPoint(coord)
					all_coords.push(pos)

				end

			# ------------------------------------------------------

			elsif type == "LineString"

				parts.each do |coord|

					pos = self.coordToPoint(coord)
					all_coords.push(pos)

				end

			# ------------------------------------------------------

			elsif type == "MultiLineString"

				parts.each do |part|

					part.each do |coord|

						pos = self.coordToPoint(coord)
						all_coords.push(pos)

					end

				end

			# ------------------------------------------------------

			elsif type == "Polygon"

				parts[0].each do |coord|

					pos = self.coordToPoint(coord)
					all_coords.push(pos)

				end

			# ------------------------------------------------------

			elsif type == "MultiLineString"

				parts.each do |part|

					part[0].each do |coord|

						pos = self.coordToPoint(coord)
						all_coords.push(pos)

					end

				end

			end

		end

		# ------------------------------------------------------
		# Split Coordinations into component lists

		xs = all_coords.map{|coord| coord[0]}.compact
		ys = all_coords.map{|coord| coord[1]}.compact
		zs = all_coords.map{|coord| coord[2]}.compact

		# ------------------------------------------------------
		# Compute and return centroid of all coordinates

		return Geom::Point3d.new((xs.min + xs.max) / 2, (ys.min + ys.max) / 2, (zs.min + zs.max) / 2)

	end # Get Geographic Centroid Definition

	# ------------------------------------------------------

	def self.redrawPoint(pt1, pt2)

		# Offset point one by negating point two
		x = pt1.x - pt2.x
		y = pt1.y - pt2.y
		z = pt1.z - pt2.z

		return Geom::Point3d.new(x.m, y.m, z.m)

	end # Redraw Point Defenition

	# ------------------------------------------------------

	def self.createPropbase(features, offset)

		properties = Sketchup.active_model.entities.add_group
		properties.entities.add_cpoint(Geom::Point3d.new(0,0,0))

		streets = Sketchup.active_model.entities.add_group
		streets.entities.add_cpoint(Geom::Point3d.new(0,0,0))

		features.each do |feature|

			type = feature["geometry"]["type"]
			parts = feature["geometry"]["coordinates"]
			attribs = feature["properties"]

			# ------------------------------------------------------

			if type == "Polygon"

				points = Array.new

				parts[0].each do |coord|

					pt = coordToPoint(coord)
					points.push(redrawPoint(pt, offset))

				end

				if points.length > 3

					
					if attribs["TYPE"] == "Property"

						prop = properties.entities.add_face(points)
						if prop
							prop.reverse!
							prop.material = 0xaaaaaa
						end

					elsif attribs["TYPE"] == "Street"

						seg = streets.entities.add_face(points)
						if seg
							seg.reverse!
							seg.material = 0xffffff
						end

					end

				end

			end

		end

		properties.entities.grep(Sketchup::ContructionPoint)[0].erase!
		streets.entities.grep(Sketchup::ConstructionPoint)[0].erase!

	end # Create Propbase Defenition

	# ------------------------------------------------------

	def self.createBuildings(features, offset)

		features.each do |feature|

			type = feature["geometry"]["type"]
			parts = feature["geometry"]["coordinates"]
			attribs = feature["properties"]

			# ------------------------------------------------------

			if type == "Polygon"

				points = Array.new

				parts[0].each do |coord|

					pt = coordToPoint(coord)
					points.push(redrawPoint(pt, offset))

				end

				if points.length > 3

					feature = Sketchup.active_model.entities.add_group
					poly = feature.entities.add_face(points)
					poly.reverse!
					poly.pushpull(attribs["HEIGHT"].to_f.m)

					attribs.each_pair do |attrib, value|

						feature.set_attribute("buildings", attrib, value)

					end

					feature.name = "BLDG_" + attribs["STRUCT_INT"].to_s
				
				end

			end

		end

	end # Create Propbase Defenition

	# ------------------------------------------------------

	def self.importer

		# Read Propbase JSON
		propbase_file = open(File.join(File.dirname(__FILE__), "unified_propbase.json"))
		propbase_parsed = JSON.parse(propbase_file.read)

		# Read Bulding Footprints JSON
		buildings_file = open(File.join(File.dirname(__FILE__), "building_footprints.json"))
		buildings_parsed = JSON.parse(buildings_file.read)

		# Define Geographic Offset
		geo_offset = Geom::Point3d.new(320697.451, 5812845.076, 0)

		# Create Features
		self.createPropbase(propbase_parsed["features"], geo_offset)
		self.createBuildings(buildings_parsed["features"], geo_offset)
	
	end # Importer Defenition

end # module CommunityExtensions::ScenarioModeller