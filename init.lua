minetest.set_mapgen_params({mgname="singlenode"})
minetest.register_on_mapgen_init(function(mapgen_params)
	math.randomseed(mapgen_params.seed)
end)
minetest.register_node("math_mapgen_rewrite:stone", {
	description = "Stone",
	tiles = {"default_stone.png"},
	groups = {cracky = 3, stone = 1},
	drop = "default:cobble",
	legacy_mineral = true,
	sounds = default.node_sound_stone_defaults(),
	drop = "default:stone",
	--paramtype = "light",
	--light_source = 14,
	sunlight_propagates = true,
})

minetest.register_node("math_mapgen_rewrite:ice", {
	description = "Ice",
	tiles = {"default_ice.png"},
	is_ground_content = false,
	paramtype = "light",
	groups = {cracky = 3, cools_lava = 1, slippery = 3},
	sounds = default.node_sound_ice_defaults(),
	drop = "default:ice",
	--light_source = 14,
	sunlight_propagates = true,
})


function mandelbox(x,y,z,d,nn)
	local s = 7
	x = x * s
	y = y * s
	z = z * s
	d = d * s
	local posX = x
	local posY = y
	local posZ = z
	local dr = 1.0
	local r = 0.0
	local scale = 2
	local minRadius2 = 0.25
	local fixedRadius2 = 1
	for n=0, nn do
		--Reflect
		if x > 1.0 then
			x = 2.0 - x
		elseif x < -1.0 then
			x = -2.0 - x
		end
		if y > 1.0 then
			y = 2.0 - y
		elseif y < -1.0 then
			y = -2.0 - y
		end
		if z > 1.0 then
			z = 2.0 - z
		elseif z < -1.0 then
			z = -2.0 - z
		end
		--Sphere Inversion
		local r2 = (x * x) + (y * y) + (z * z)
		if r2 < minRadius2 then
			x = x * (fixedRadius2 / minRadius2)
			y = y * (fixedRadius2 / minRadius2)
			z = z * (fixedRadius2 / minRadius2)
			dr = dr * (fixedRadius2 / minRadius2)
		elseif r2 < fixedRadius2 then
			x = x * (fixedRadius2 / r2)
			y = y * (fixedRadius2 / r2)
			z = z * (fixedRadius2 / r2)
			fixedRadius2 = fixedRadius2 * (fixedRadius2 / r2)
		end
		x = (x * scale) + posX
		y = (y * scale) + posY
		z = (z * scale) + posZ
		dr = dr * scale
	end
	r = math.sqrt((x*x)+(y*y)+(z*z))
	return ((r / math.abs(dr)) < d)
end

---orly
minetest.register_on_generated(function(minp, maxp, seed)
	local vm, emin, emax = minetest.get_mapgen_object("voxelmanip")
	local data = vm:get_data()
	local a = VoxelArea:new({MinEdge = emin, MaxEdge = emax})
	local csize = vector.add(vector.subtract(maxp, minp), 1)
	local write = false
	for z = minp.z, maxp.z do
	for y = minp.y, maxp.y do
	for x = minp.x, maxp.x do
		local ivm = a:index(x, y, z)
		local size = minetest.settings:get("math_mapgen_rewrite.size") or 1000
		local distance = minetest.settings:get("math_mapgen_rewrite.distance") or 0.01
		local invert = minetest.settings:get("math_mapgen_rewrite.invert") or 0
		local center = vector.new(size*0.3, -size*0.6, size*0.5)
		local iterations = minetest.settings:get("math_mapgen_rewrite.iterations") or 10
		local scale = minetest.settings:get("math_mapgen_rewrite.scale") or 1/size
		local vec = vector.multiply(vector.subtract(vector.new(x,y,z),center),scale)
		local d = mandelbox(vec.x,vec.y,vec.z,distance,iterations)
		if d then
			data[ivm] = minetest.get_content_id("math_mapgen_rewrite:stone") -- or ice my favorite version of the old math mapgen mandelbox
			if minetest.settings:get("math_mapgen_rewrite.ores") or true then
				if math.random(0,10000) <= 59 then data[ivm] = minetest.get_content_id("default:stone_with_coal") end
		 		if math.random(0,10000) <= 41 then data[ivm] = minetest.get_content_id("default:stone_with_iron") end
				if math.random(0,10000) <= 11 then data[ivm] = minetest.get_content_id("default:stone_with_mese") end
		 		if math.random(0,10000) <= 3 then data[ivm] = minetest.get_content_id("default:stone_with_diamond") end
		 	end
		elseif y <= 0 then
			data[ivm] = minetest.get_content_id("default:water_source")
		else
			data[ivm] = minetest.get_content_id("air")
		end
		write = true
	end
	end
	end

	if write then
		vm:set_data(data)
		vm:set_lighting({day = 0, night = 0})
		vm:calc_lighting()
		vm:update_liquids()
		vm:write_to_map()
	end

end)
