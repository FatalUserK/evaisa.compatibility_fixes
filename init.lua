local queued_prints = {}

local queue_print = function(msg)
	table.insert(queued_prints, msg)
end

local escaped_replace = function(path, find, replace)
	if(not ModDoesFileExist(path)) then return end
	local input = ModTextFileGetContent(path)

	local old = input
	local find_escaped = find:gsub("[%(%)%.%%%+%-%*%?%[%]%^%$]", "%%%0")
	input = input:gsub(find_escaped, replace)
	
	if(old == input)then
		queue_print("No changes made in "..path..": "..find.." not found.")
		return
	else	
		queue_print("Applied escaped_replace in "..path..": "..find.." -> "..replace)
		--queue_print("New Content: \n" ..input)
	end

	ModTextFileSetContent(path, input)


end

local pattern_replace = function(path, find, replace)
	if(not ModDoesFileExist(path)) then return end
	local input = ModTextFileGetContent(path)

	local old = input
	input = input:gsub(find, replace)
	
	if(old == input)then
		queue_print("No changes made in "..path..": "..find.." not found.")
		return
	else	
		queue_print("Applied pattern_replace in "..path..": "..find.." -> "..replace)
	end
	ModTextFileSetContent(path, input)
end

local function remove_all_biome_blocks_by_keyword(path, keyword)
	if not ModDoesFileExist(path) then return end
	local input = ModTextFileGetContent(path)
	local original = input

	local removed_count = 0

	-- loop until no more keyword
	while true do
		-- find keyword (plain search)
		local kpos = input:find(keyword, 1, true)
		if not kpos then break end

		-- find last '<Biome' before the keyword
		local last_open = nil
		local search_from = 1
		while true do
			local st = input:find("<Biome", search_from, true)
			if not st or st > kpos then break end
			last_open = st
			search_from = st + 1
		end

		if not last_open then
			queue_print("No changes made in "..path..": opening <Biome tag not found before "..keyword..".")
			break
		end

		-- find a self-closing "/>" after last_open (if any)
		local self_close_start, self_close_end = input:find("/>", last_open, true)
		-- find explicit closing tag "</Biome>" after last_open (if any)
		local close_tag_start, close_tag_end = input:find("</Biome>", last_open, true)

		local block_end_index = nil

		-- choose which ends the tag earlier / is present
		if self_close_start and (not close_tag_start or self_close_start < close_tag_start) then
			-- self-closing tag ends at self_close_end
			block_end_index = self_close_end
		elseif close_tag_end then
			-- full block ends at close_tag_end
			block_end_index = close_tag_end
		else
			-- malformed: no closing found -> bail out to avoid infinite loop
			queue_print("No changes made in "..path..": no closing for <Biome> found after position "..tostring(last_open))
			break
		end

		-- remove the block (from last_open to block_end_index)
		input = input:sub(1, last_open - 1) .. input:sub(block_end_index + 1)
		removed_count = removed_count + 1
	end

	if removed_count == 0 then
		queue_print("No changes made in "..path..": "..keyword.." not found.")
		return
	end

	ModTextFileSetContent(path, input)
	queue_print("Removed "..tostring(removed_count).." <Biome> block(s) containing "..keyword.." in "..path)
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

escaped_replace("mods/grahamsperks/files/materials/materials.xml", [[name="graham_confuse"]], [[name="graham_confuse"
	tags="[liquid],[water],[magic_liquid],[impure]"]])

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

escaped_replace("mods/elements_of_surprise/files/biomes.lua", "local content = ModTextFileGetContent(biome)", [[if(not ModDoesFileExist(biome)) then return end
local content = ModTextFileGetContent(biome)
]])

local function varia_is_deranged(file)
	escaped_replace(file, "if caster then", [[if caster and not reflecting then]])
end

varia_is_deranged("mods/variaAddons/files/actions.lua")
varia_is_deranged("mods/variaAddons/files/actions_joke.lua")

local function varia_remove_broken_for_loop(file)
	pattern_replace(file, "for i=1,action_count do%s+AddGunAction%( entity_id, gun_action %)%s+end", "")
end

local varia_specialty_wands = {
	"shovel", "shovel_golden", "shovel_tactical", "shovel_nuclear", "shovel_void",
	"brave_sword", "avernus", "bresi_trident", "minelayer", "espy_axe", "polar_star",
	"s-12", "subjugation_rifle", "ryyst_shotgun", "true_ampere_missile", "tower_shield",
	"strange_rocket_launcher", "desert_dragon", "rocket_launcher", "russian_roulette",
	"rock_launcher", "chroma_lash", "phantom_slasher", "desert_eagle", "completionists_codex",
	"fatal_lie", "draco_ferrio", "gaurdbubbler", "chaos_ordinance", "chaos_staff", "charming_miasma"
}

for _, wand in ipairs(varia_specialty_wands) do
	varia_remove_broken_for_loop("mods/variaAddons/files/entities/specialty_wands/" .. wand .. "/" .. wand .. "_lua.lua")
end


escaped_replace("mods/new_enemies/files/materials/materials.xml", [[ui_name="$mat_magic_liquid_random_polymorph"]], [[ui_name="$mat_magic_liquid_random_polymorph"
	tags="[liquid],[water],[magic_liquid],[magic_polymorph],[impure]"]])

escaped_replace("mods/cool_spell/files/appends/gun_actions.lua", [[print("OVERCAST spells loaded! spell count: " .. tostring(spells_count) .. " (" .. tostring(disabled_count) .. " disabled)")]], "")

escaped_replace("mods/cool_spell/files/appends/gun.lua", [[	if wand ~= nil then
		if wand.mana >= wand.manaMax then -- check if cooldown over
			OVERDRAW_cooldown = false
		end
	end
	
	if wand.mana < 0 then -- extra check, since swapping wands can do funny stuff
		OVERDRAW_cooldown = true
	end
	
	--GamePrint(tostring(OVERDRAW_cooldown))
	
	local comp = EntityGetFirstComponent(wand.entity_id]], [[	if wand ~= nil then
		if wand.mana >= wand.manaMax then -- check if cooldown over
			OVERDRAW_cooldown = false
		end
		if wand.mana < 0 then -- extra check, since swapping wands can do funny stuff
			OVERDRAW_cooldown = true
		end
	end
	
	--GamePrint(tostring(OVERDRAW_cooldown))
	
	if wand == nil then return end
	local comp = EntityGetFirstComponent(wand.entity_id]])


function OnModPostInit()
	remove_all_biome_blocks_by_keyword("data/biome/_biomes_all.xml", "biome_labyrinth")
end

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

local function tag_annihilator(input_file)
	escaped_replace(input_file, ",[meltable_metal]", "")
end

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

tag_annihilator("mods/biome-plus/data/mod/appends/materials.xml")

function stop_using_globals_too_early(file)
	-- insert at start of file
	local stuff = [[
local requires_world_state = {"GlobalsGetValue", "GlobalsSetValue", "GameAddFlagRun", "GameHasFlagRun"}
local has_default = {
	["GlobalsGetValue"] = 2
}
for _, v in ipairs(requires_world_state) do
    local old = _G[v]
    _G[v] = function(...)
        if not EntityGetIsAlive(GameGetWorldStateEntity()) then
            if has_default[v] then
                local args = {...}
                return args[ has_default[v] ]
            end
            return
        end
        return old(...)
    end
end
	]]

	

	local input = ModTextFileGetContent(file)
	input = stuff .. "\n" .. input
	ModTextFileSetContent(file, input)
end

stop_using_globals_too_early("data/scripts/empty_enemy_helper_start.lua")
stop_using_globals_too_early("mods/biome-plus/init.lua")

if ModIsEnabled("copis_things") and ModIsEnabled("config_lib") then
	local path = "mods/copis_things/files/scripts/gui/compat_crap.lua"
	if ModDoesFileExist(path) then
		ModTextFileSetContent(path, [[local current_button_reservation = tonumber( GlobalsGetValue( "mod_button_tr_current", "0" ) ) or 0
GlobalsSetValue( "mod_button_tr_current", tostring( current_button_reservation + 15 ) )
return current_button_reservation]])
	end
	
	path = "mods/copis_things/files/scripts/gui/button.lua"
	if ModDoesFileExist(path) then
		local content = ModTextFileGetContent(path)
		content = string.gsub(content, "local function button%(Gui, id_fn%)", [[local function button(Gui, id_fn, button_offset)
    button_offset = button_offset or 0]])
		content = string.gsub(content, "screen_w %- 14, 2", "screen_w - 14 - button_offset, 2")
		ModTextFileSetContent(path, content)
	end
	
	path = "mods/copis_things/files/scripts/gui/gui.lua"
	if ModDoesFileExist(path) then
		local content = ModTextFileGetContent(path)
		content = string.gsub(content, 'button%.lua"%)%(self%.obj, new_id%)', 'button.lua")(self.obj, new_id, curr_res)')
		ModTextFileSetContent(path, content)
	end
	
	path = "mods/config_lib/files/gui.lua"
	if ModDoesFileExist(path) then
		local content = ModTextFileGetContent(path)
		content = string.gsub(content, 'local mod_button_reservation = tonumber%( GlobalsGetValue%( "config_lib_mod_button_reservation", "0" %) %);', "local mod_button_reservation = 9999;")
		ModTextFileSetContent(path, content)
	end
end

if ModIsEnabled("gkbrkn_noita") and ModIsEnabled("config_lib") then
	local path = "mods/gkbrkn_noita/files/gkbrkn/gui/update.lua"
	if ModDoesFileExist(path) then
		local content = ModTextFileGetContent(path)
		content = string.gsub(content, 'local button_x, button_y = setting_get%( "main_button_x", screen_width %), setting_get%( "main_button_y", 0 %)', [[local _gkbrkn_reservation = tonumber( GlobalsGetValue( "mod_button_tr_current", "0" ) ) or 0
	GlobalsSetValue( "mod_button_tr_current", tostring( _gkbrkn_reservation + 15 ) )
	local button_x, button_y = setting_get( "main_button_x", screen_width - _gkbrkn_reservation ), setting_get( "main_button_y", 0 )]])
		ModTextFileSetContent(path, content)
	end
end

local DEBUG = true

function OnMagicNumbersAndWorldSeedInitialized()
	if not DEBUG then return end
	for _, msg in ipairs(queued_prints) do
		print(msg)
	end
end

ModMaterialsFileAdd("mods/evaisa.compatibility_fixes/materials.xml")