require 'json'

module CommunityExtensions::MyTestPlugins

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

		# ------------------------------------------------------
		# Create new feature arrays
		properties = Array.new
		streets = Array.new

		# Loop through features and separate as required
		features.each do |feature|

			attribs = feature["properties"]

			if attribs["TYPE"] == "Property"

				properties.push(feature)

			elsif attribs["TYPE"] == "Street"

				streets.push(feature)

			end

		end

		# ------------------------------------------------------
		# Create Properties

		prop_group = Sketchup.active_model.entities.add_group
		prop_group.entities.add_cpoint(Geom::Point3d.new(0,0,0))
		prop_group.name = "Property Base"

		properties.each do |property|

			type = property["geometry"]["type"]
			parts = property["geometry"]["coordinates"]
			attribs = property["properties"]

			if type == "Polygon"

				points = Array.new

				parts[0].each do |coord|

					pt = coordToPoint(coord)
					points.push(redrawPoint(pt, offset))

				end

				if points.length > 3

					prop = prop_group.entities.add_group

					face = prop.entities.add_face(points)
					face.reverse!
					face.material = 0xaaaaaa

					# Apply attributes to face
					attribs.each_pair do |attrib, value|

						face.set_attribute("attributes", attrib, value)

					end

					prop.explode

				end

			end

		end

		# Remove construction point
		prop_group.entities.grep(Sketchup::ConstructionPoint)[0].erase!

		# ------------------------------------------------------
		# Create Streets

		street_group = Sketchup.active_model.entities.add_group
		street_group.entities.add_cpoint(Geom::Point3d.new(0,0,0))
		street_group.name = "Street Segments"

		streets.each do |segment|

			type = segment["geometry"]["type"]
			parts = segment["geometry"]["coordinates"]
			attribs = segment["properties"]

			if type == "Polygon"

				points = Array.new

				parts[0].each do |coord|

					pt = coordToPoint(coord)
					points.push(redrawPoint(pt, offset))

				end

				if points.length > 3

					seg = street_group.entities.add_group

					face = seg.entities.add_face(points)
					face.reverse!

					if attribs["DETAILS"] == "River"
						
						face.material = 0xb5e3f4

					else

						face.material = 0xffffff

					end

					# Apply attributes to face
					attribs.each_pair do |attrib, value|

						face.set_attribute("attributes", attrib, value)

					end

					seg.explode

				end

			end

		end

		# Remove construction point
		street_group.entities.grep(Sketchup::ConstructionPoint)[0].erase!

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

end # module CommunityExtensions::MyTestPlugins