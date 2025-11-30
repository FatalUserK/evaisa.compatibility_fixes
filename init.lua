local queued_prints = {}

local queue_print = function(msg)
	table.insert(queued_prints, msg)
end

local escaped_replace = function(path, find, replace)
	if(not ModDoesFileExist(path)) then return end
	local input = ModTextFileGetContent(path)

	local find_escaped = find:gsub("[%(%)%.%%%+%-%*%?%[%]%^%$]", "%%%0")
	input = input:gsub(find_escaped, replace)

	queue_print("Applied escaped_replace in "..path..": "..find.." -> "..replace)
	queue_print("New Content: \n" ..input)
ModTextFileSetContent(path, input)


end


escaped_replace("mods/monsters_drop_your_guns/files/original_files_modifier.lua", "function AddDropScript(file_path)", [[function AddDropScript(file_path)
if(not ModDoesFileExist(file_path)) then return end]])

escaped_replace("mods/copis_things/init/compat_frostbite.lua", "local content = add_tag(ModTextFileGetContent(file.path))", [[ModTextFileSetContent(file.path, add_tag(ModTextFileGetContent(file.path))) 
local content = file.path
]])

escaped_replace("mods/copis_things/init/compat_frostbite.lua", "ModTextFileSetContent(file.path, content)", "")

escaped_replace("mods/elements_of_surprise/files/materials.lua", "local function add_xml(path)", [[local function add_xml(path)
	if(not ModDoesFileExist(path)) then return end
]])

escaped_replace("mods/elements_of_surprise/files/materials.lua", "local graphics = el_looks_like:first_of('Graphics')", [[
			local inherited_tags = el_acts_like.attr.tags or ''
			inherited_tags = string.gsub(inherited_tags, '%[evaporable_custom%],?', '')
			inherited_tags = string.gsub(inherited_tags, '%[meltable_metal%],?', '')
			inherited_tags = string.gsub(inherited_tags, '%[condensable%],?', '')
			inherited_tags = string.gsub(inherited_tags, '%[hydratable%],?', '')
			if inherited_tags ~= '' then
				el.attr.tags = inherited_tags
			end
local graphics = el_looks_like:first_of('Graphics')]])

escaped_replace("mods/new_enemies/files/materials/materials.xml", [[ui_name="$mat_magic_liquid_random_polymorph"]], [[ui_name="$mat_magic_liquid_random_polymorph"
	tags="[liquid],[water],[magic_liquid],[magic_polymorph],[impure]"]])

escaped_replace("mods/cool_spell/files/appends/gun_actions.lua", [[print("OVERCAST spells loaded! spell count: " .. tostring(spells_count) .. " (" .. tostring(disabled_count) .. " disabled)")]], "")

if(ModIsEnabled("alchemical_reactions_expansion")) then
	print("Applying Alchemical Reactions Expansion compatibility fixes")
	ModTextFileSetContent("mods/alchemical_reactions_expansion/files/materials_append.xml", ModTextFileGetContent("mods/evaisa.compatibility_fixes/files/alchemical_reactions_expansion.xml"))
	if ModIsEnabled("Hydroxide") then
		ModMaterialsFileAdd("mods/evaisa.compatibility_fixes/files/alchemical_reactions_expansion_cc_compat.xml")
	end
	if ModIsEnabled("fluid_dynamics") then
		ModMaterialsFileAdd("mods/evaisa.compatibility_fixes/files/alchemical_reactions_expansion_fluid_dynamics.xml")
	end

	if ModIsEnabled("Hydroxide") and ModIsEnabled("fluid_dynamics") then
		ModMaterialsFileAdd("mods/evaisa.compatibility_fixes/files/alchemical_reactions_expansion_cc_and_fd.xml")
	end
end

local cc_update_map = {
	AA_MAT_NEUTRAL_POTION = "aa_base_potion",
	alchemyPowder = "cc_alchemy_powder",
	AA_LIQUID_SPELL = "aa_pandorium",
	AA_UNSTABLE_LIQUID_SPELL = "aa_unstable_pandorium",
}

for old_id, new_id in pairs(cc_update_map) do
	escaped_replace("mods/cool_spell/files/materials/reactions_chemical_curiosities.xml", old_id, new_id)
end

escaped_replace("mods/material_randomizer/files/randomizer.lua", "if not table.contains(exclude_materials, name) then\n          local inherited_element = get_inherited_element(get_tree_node(tree, parents, name))", [[local inherited_element = get_inherited_element(get_tree_node(tree, parents, name))
        local tags = parse_tags(inherited_element._attr.tags)
        if not table.contains(exclude_materials, name) and not tags.dont_kill_this then]])

escaped_replace("mods/material_randomizer/files/randomizer.lua", "if not table.contains(exclude_materials, element._attr.name) then\n        local inherited_element = get_inherited_element(get_tree_node(tree, parents, element._attr.name))\n        local material_type = material_get_type(inherited_element)", [[local inherited_element = get_inherited_element(get_tree_node(tree, parents, element._attr.name))
      local tags = parse_tags(inherited_element._attr.tags)
      if not table.contains(exclude_materials, element._attr.name) and not tags.dont_kill_this then
        local material_type = material_get_type(inherited_element)]])

escaped_replace("mods/Hydroxide/files/chemical_curiosities/materials/uranium/radiation_decrease.lua", [[print("ATTEMPTING TO REMOVE " .. leggyentity)]], "")

local DEBUG = false

function OnPlayerSpawned()
	if not DEBUG then return end
	for _, msg in ipairs(queued_prints) do
		print(msg)
	end
end

ModMaterialsFileAdd("mods/evaisa.compatibility_fixes/materials.xml")