local eggutils = require("beepboop.eggutils")

local M = {}

-- ##################### VALIDATION #####################

local validate_sound_directory = function(sound_directory)
	if sound_directory == nil then
		sound_directory = vim.fn.stdpath("config") .. "/sounds/"
	end

	if vim.uv.fs_stat(sound_directory) == nil then
		error("beepboop.nvim: Could not find sound_directory \"" .. sound_directory .. "\"", 1)
		return nil
	end
	return sound_directory
end

-- Should eventually test if the program even exists on the system
local validate_audio_player = function(audio_player)
	local os = eggutils.get_os()

	if os == "linux" then
		local linux_audio_players = { "paplay", "mpv", "ffmpeg" }
		-- default to paplay if no valid linux audi_player is given
		if not eggutils.has_value(linux_audio_players, audio_player) then
			if not M.suppress_warnings then
				error("beepboop.nvim: No audio player configured or the current one is unsupported, defaulting to paplay. Set \"supress_warnings = true\" in your config if this is intentional")
			end
			return "paplay"
		end
	elseif os == "macos" then
		local mac_os_audio_players = { "afplay", "mpv", "ffmpeg" }
		if not eggutils.has_value(mac_os_audio_players, audio_player) then
			if not M.suppress_warnings then
				error("beepboop.nvim: No audio player configured or the current one is unsupported, defaulting to afplay. Set \"supress_warnings = true\" in your config if this is intentional")
			end
			return "afplay"
		end
	elseif os == "windows" then
		error("beepboop.nvim: We do not support Windows at this time, try windows subsystem for linux.", 1)
		return nil
	end
	return audio_player
end

-- { auto_command = "", sound = "chestopen.oga" },
-- { key_press = {"n", "j"}, sounds = {"hit1.oga", "hit2.oga", "hit3.oga"} },
-- { trigger_name = "chestopen", sound = "hit1.oga" },

local validate_sound_map = function(sound_map, sound_directory)
	local validated_sound_map = {}
	local trigger_number = 0

	for _, map in ipairs(sound_map) do
		local trigger_name

		if map.trigger_name == nil then
			trigger_name = "trigger" .. trigger_number
			trigger_number = trigger_number + 1
		else
			trigger_name = map.trigger_name
		end

		local audio_files
		if map.sounds then
			audio_files = map.sounds
		elseif map.sound then
			audio_files = { map.sound }
		else
			if not M.suppress_warnings then
				error("beepboop.nvim: Trigger received no or invalid/missing audio files. Set \"supress_warnings = true\" in your config if this is intentional", 1)
			end
			audio_files = {}
		end

		-- validate that audio files exist
		for i, af in ipairs(audio_files) do
			if not vim.uv.fs_stat(sound_directory .. af) then
				if not M.suppress_warnings then
					error("beepboop.nvim: Sound \"" .. sound_directory .. af .. "\" doesn't exist. Set \"supress_warnings = true\" in your config if this is intentional", 1)
				end
				audio_files[i] = nil
			end
		end

		validated_sound_map[trigger_name] = {
			auto_command = map.auto_command,
			key_press = map.key_press,
			audio_files = audio_files,
		}
	end

	return validated_sound_map
end

-- ##################### INITIALIZATION #####################

local get_audio_player_callback = (function(audio_player, sound_directory)
	if audio_player == "paplay" then
		return (function(audio_files)
			if not M.sound_enabled then return end
			os.execute("paplay " ..
				sound_directory ..
				audio_files[math.random(#audio_files)] ..
				" --volume=" ..
				(M.volume * 65536) ..
				" &"
			)
		end)
	elseif audio_player == "pw-play" then
	elseif audio_player == "mpv" then
		return (function(audio_files)
			if not M.sound_enabled then return end
			os.execute("mpv " ..
				sound_directory ..
				audio_files[math.random(#audio_files)] ..
				" --volume=" ..
				M.volume * 100 ..
				" --msg-level=all=no 2> /dev/null &"
			)
		end)
	elseif audio_player == "ffplay" then
		-- TODO: curosr keeps sliding down when sounds are played
		return (function(audio_files)
			if not M.sound_enabled then return end
			os.execute("ffplay " ..
				sound_directory ..
				audio_files[math.random(#audio_files)] ..
				" -volume " ..
				(M.volume * 100) ..
				" -loglevel -8 -nodisp -autoexit > /dev/null &"
			)
		end)
	elseif audio_player == "afplay" then
		return (function(audio_files)
			-- TODO: handle logorithmic sound
			-- can currently only use wav and mp3 files on mac
			os.execute("afplay" ..
				sound_directory ..
				audio_files[math.random(#audio_files)] ..
				" -volume " ..
				M.volume ..
				" &"
			)
		end)
	end
end)

local initialize_user_commands = (function()
	vim.api.nvim_create_user_command("BeepBoopEnable", function()
		M.sound_enabled = true
	end, {})

	vim.api.nvim_create_user_command("BeepBoopDisable", function()
		M.sound_enabled = false
	end, {})

	vim.api.nvim_create_user_command("BeepBoopToggle", function()
		M.sound_enabled = not M.sound_enabled
	end, {})

	vim.api.nvim_create_user_command("BeepBoopVolume", function(args)
		if tonumber(args.fargs[1]) == nil then
			error("beepboop.nvim: Please provide the volume as a number between 0.0-1.0", 1)
			return
		end
		M.volume = tonumber(args.fargs[1])
	end, { nargs = "+" })
end)

local initialize_auto_commands = (function(sound_map)
	-- Groups the autocommands and doesnt allow duplicates that produce the same state
	M.augroup = vim.api.nvim_create_augroup("BeepBoop.nvim", { clear = true })

	for trigger_name, sound in pairs(sound_map) do
		if sound.auto_command then
			vim.api.nvim_create_autocmd(sound.auto_command, {
				callback = function()
					M.play_audio(trigger_name)
				end,
				group = M.augroup
			})
		end
	end
end)

-- ##################### SETUP #####################

M.play_audio = function(trigger_name)
	M.audio_player_callback(M.sound_map[trigger_name].audio_files)
end

M.setup = (function(opts)
	opts = opts or {}

	M.suppress_warnings = opts.supress_warnings ~= nil

	local sound_directory = validate_sound_directory(opts.sound_directory)
	if sound_directory == nil then return end

	local audio_player = validate_audio_player(opts.audio_player)
	if audio_player == nil then return end

	M.audio_player_callback = get_audio_player_callback(audio_player, sound_directory)
	if M.audio_player_callback == nil then return end -- shouldn't return nil

	local sound_map = validate_sound_map(opts.sound_map, sound_directory)
	if sound_map == nil then return end;

	M.sound_directory = sound_directory
	M.audio_player = audio_player
	M.sound_map = sound_map

	M.sound_enabled = opts.sound_enabled or true -- sound_enabled defaults true
	M.volume = opts.volume or 1.0 -- volume defaults 1.0

	initialize_user_commands()
	initialize_auto_commands(sound_map)
end)

return M

-- init_audio()

-- Cool buffer commands
-- VimEnter/VimLeave
-- InsertCharPre
-- BufEnter
-- BufWrite
-- RecordingEnter/RecordingLeave
-- ModeChanged
-- InsertEnter/InsertLeave
-- ExitPre
-- CursorMoved
-- CompleteDone
