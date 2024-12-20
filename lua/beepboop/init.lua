local M = {}

-- afplay
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
			os.execute("afplay" ..
				sound_directory ..
				audio_files[math.random(#audio_files)] ..
				" -volume " ..
				-- TODO: MAY BE LOGARITHMIC, TEST
				(M.volume * 255) ..
				" &"
			)
	else
		print("beepboop.nvim: \"" .. audio_player .. "\"" .. " is not a valid audio player")
		return nil
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
			print("beepboop.nvim: Please provide the volume as a number between 0.0-1.0")
			return
		end
		M.volume = tonumber(args.fargs[1])
	end, { nargs = "+" })
end)

local initialize_auto_commands = (function(sound_map, play_audio)
	for auto_cmd, audio_files in pairs(sound_map) do
		vim.api.nvim_create_autocmd(auto_cmd, {
			callback = function() play_audio(audio_files) end
		})
	end
end)

M.setup = (function(opts)
	opts = opts or {}

	local sound_directory = opts.sound_directory
	-- TODO:
	-- validate directory exists and is accessible
	-- maybe validate that all claimed audio files are accessible
	if sound_directory == nil then
		print("beepboop.nvim: \"sound_directory\" not provided. make a directory for beepboop to look for sounds in.")
		return
	end

	local audio_player = opts.audio_player or "paplay" -- audio_player defaults paplay

	local play_audio = get_audio_player_callback(audio_player, sound_directory)
	if play_audio == nil then return end

	local sound_map = opts.sound_map or {} -- sound_map defaults nothing

	M.sound_enabled = opts.sound_enabled or true -- sound_enabled defaults true
	M.volume = opts.volume or 1.0 -- volume defaults 1.0

	initialize_auto_commands(sound_map, play_audio)
	initialize_user_commands()
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
