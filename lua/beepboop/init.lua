local eggutils = require("beepboop.eggutils")

local M = {}

-- ##################### VALIDATION #####################

-- Global variable to track if looping sound is currently playing
-- This will be shared across all tmux sessions
M.looping_sound_job = nil
M.looping_sound_file = nil

local validate_sound_directory = function(sound_directory)
	if sound_directory == nil then
		sound_directory = vim.fn.stdpath("config") .. "/sounds/"
	elseif string.sub(sound_directory, 1, 1) == "~" then
		sound_directory = vim.fn.expand("$HOME") .. string.sub(sound_directory, 2, #sound_directory)
	end

	if string.sub(sound_directory, #sound_directory) ~= "/" then
		sound_directory = sound_directory .. "/"
	end

	if vim.uv.fs_stat(sound_directory) == nil then
		vim.print('beepboop.nvim: Could not find sound_directory "' .. sound_directory .. '"')
		return nil
	end

	return sound_directory
end

local validate_loop_sound = function(loop_sound, sound_directory)
	if loop_sound == nil then
		return nil
	end

	-- Check if file exists
	if not vim.uv.fs_stat(sound_directory .. loop_sound) then
		vim.print('beepboop.nvim: Loop sound "' .. sound_directory .. loop_sound .. "\" doesn't exist.")
		return nil
	end

	return loop_sound
end

-- Should eventually test if the program even exists on the system
local validate_audio_player = function(audio_player)
	local os = eggutils.get_os()

	if os == "linux" then
		local linux_audio_players = { "paplay", "pw-play", "mpv", "ffplay" }
		-- default to paplay if no valid linux audi_player is given
		if not eggutils.has_value(linux_audio_players, audio_player) then
			if not M.suppress_warnings then
				vim.print(
					'beepboop.nvim: No audio player configured or the current one is unsupported, defaulting to paplay. Set "suppress_warnings = true" in your config if this is intentional.'
				)
			end
			return "paplay"
		end
	elseif os == "macos" then
		local mac_os_audio_players = { "afplay", "mpv", "ffplay" }
		if not eggutils.has_value(mac_os_audio_players, audio_player) then
			if not M.suppress_warnings then
				vim.print(
					'beepboop.nvim: No audio player configured or the current one is unsupported, defaulting to afplay. Set "suppress_warnings = true" in your config if this is intentional.'
				)
			end
			return "afplay"
		end
	elseif os == "windows" then
		vim.print("beepboop.nvim: We do not support Windows at this time, try windows subsystem for linux.")
		return nil
	end
	return audio_player
end

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

		local audio_files = nil
		if map.sounds then
			audio_files = map.sounds
		elseif map.sound then
			audio_files = { map.sound }
		else
			if not M.suppress_warnings then
				vim.print(
					'beepboop.nvim: Trigger received but missing sound files to trigger. Set "suppress_warnings = true" in your config if this is intentional.'
				)
			end
		end

		if audio_files then
			-- validate that audio files exist
			for i, af in ipairs(audio_files) do
				if not vim.uv.fs_stat(sound_directory .. af) then
					if not M.suppress_warnings then
						vim.print(
							'beepboop.nvim: Sound "'
								.. sound_directory
								.. af
								.. '" doesn\'t exist. Set "suppress_warnings = true" in your config if this is intentional.'
						)
					end
					audio_files[i] = nil
				end
			end

			if #audio_files > 0 then
				validated_sound_map[trigger_name] = {
					auto_command = map.auto_command,
					key_press = map.key_press,
					audio_files = audio_files,
					key_map = map.key_map,
					volume = eggutils.clamp(map.volume or 100, 0, 100),
					is_loop = map.is_loop or false, -- new property to mark looping sounds
				}
			end
		end
	end

	return validated_sound_map
end

-- ##################### INITIALIZATION #####################

local get_audio_player_callback = function(audio_player, sound_directory)
	local callback = function(_, _)
		M.process_count = M.process_count - 1
	end

	if audio_player == "paplay" then
		return function(audio_files, sound_volume)
			if not M.sound_enabled then
				return
			end
			if M.process_count >= M.max_sounds then
				return
			end

			M.process_count = M.process_count + 1
			vim.uv.spawn("paplay", {
				args = {
					sound_directory .. audio_files[math.random(#audio_files)],
					"--volume=" .. ((sound_volume / 100) * (M.volume / 100) * 65536),
				},
			}, callback)
		end
	elseif audio_player == "pw-play" then
		return function(audio_files, sound_volume)
			if not M.sound_enabled then
				return
			end
			if M.process_count >= M.max_sounds then
				return
			end

			M.process_count = M.process_count + 1
			vim.uv.spawn("pw-play", {
				args = {
					sound_directory .. audio_files[math.random(#audio_files)],
					"--volume=" .. ((sound_volume / 100) * (M.volume / 100)),
				},
			}, callback)
		end
	elseif audio_player == "mpv" then
		return function(audio_files, sound_volume)
			if not M.sound_enabled then
				return
			end
			if M.process_count >= M.max_sounds then
				return
			end

			M.process_count = M.process_count + 1
			vim.uv.spawn("mpv", {
				args = {
					sound_directory .. audio_files[math.random(#audio_files)],
					"--volume=" .. ((sound_volume / 100) * M.volume),
				},
			}, callback)
		end
	elseif audio_player == "ffplay" then
		return function(audio_files, sound_volume)
			if not M.sound_enabled then
				return
			end
			if M.process_count >= M.max_sounds then
				return
			end

			M.process_count = M.process_count + 1
			vim.uv.spawn("ffplay", {
				args = {
					sound_directory .. audio_files[math.random(#audio_files)],
					"-volume",
					((sound_volume / 100) * M.volume),
					"-nodisp",
					"-autoexit",
				},
			}, callback)
		end
	elseif audio_player == "afplay" then
		return function(audio_files, sound_volume)
			-- can currently only use wav and mp3 files on mac
			if not M.sound_enabled then
				return
			end

			M.process_count = M.process_count + 1
			vim.uv.spawn("afplay", {
				args = {
					sound_directory .. audio_files[math.random(#audio_files)],
					"-volume",
					((sound_volume / 100) * (M.volume / 100)),
				},
			}, callback)
		end
	end
end

-- Function to start playing a looping sound
M.play_looping_sound = function()
	-- Prevent starting if it's already playing
	if M.looping_sound_job ~= nil then
		vim.print("beepboop.nvim: A looping sound is already playing")
		return
	end

	if not M.sound_enabled then
		vim.print("beepboop.nvim: Sounds are currently disabled")
		return
	end

	if M.loop_sound == nil then
		vim.print("beepboop.nvim: No loop sound configured")
		return
	end

	-- Complete path to sound file
	local full_path = M.sound_directory .. M.loop_sound

	-- Different audio players need different loop arguments
	local args = {}
	if M.audio_player == "mpv" then
		args = { full_path, "--loop=inf", "--volume=" .. M.volume }
	elseif M.audio_player == "ffplay" then
		args = { full_path, "-loop", "0", "-volume", M.volume, "-nodisp" }
	elseif M.audio_player == "paplay" then
		-- For paplay, play the sound 1000 times in sequence
		M.loop_counter = 0
		M.max_loops = 1000
		M.loop_active = true

		-- Function that plays one instance and schedules the next one
		local function play_next()
			if not M.loop_active or M.loop_counter >= M.max_loops then
				M.looping_sound_job = nil
				M.loop_active = false
				return
			end

			M.loop_counter = M.loop_counter + 1

			M.looping_sound_job = vim.uv.spawn("paplay", {
				args = {
					full_path,
					"--volume=" .. ((100 / 100) * (M.volume / 100) * 65536),
				},
			}, function(code, signal)
				if M.loop_active then
					vim.defer_fn(play_next, 0) -- Schedule next play immediately after this one ends
				end
			end)
		end

		play_next() -- Start the first play
		vim.print(
			string.format("beepboop.nvim: Started looping sound: %s (will play %d times)", M.loop_sound, M.max_loops)
		)
		return
	elseif M.audio_player == "pw-play" then
		-- Same approach as paplay for pw-play
		M.loop_counter = 0
		M.max_loops = 1000
		M.loop_active = true

		local function play_next()
			if not M.loop_active or M.loop_counter >= M.max_loops then
				M.looping_sound_job = nil
				M.loop_active = false
				return
			end

			M.loop_counter = M.loop_counter + 1

			M.looping_sound_job = vim.uv.spawn("pw-play", {
				args = {
					full_path,
					"--volume=" .. ((100 / 100) * (M.volume / 100)),
				},
			}, function(code, signal)
				if M.loop_active then
					vim.defer_fn(play_next, 0)
				end
			end)
		end

		play_next()
		vim.print(
			string.format("beepboop.nvim: Started looping sound: %s (will play %d times)", M.loop_sound, M.max_loops)
		)
		return
	elseif M.audio_player == "afplay" then
		-- Simulate looping by starting it again when it ends
		args = { full_path, "-volume", M.volume }
	end

	-- Start the looping playback (for non-paplay/pw-play players)
	M.looping_sound_job = vim.uv.spawn(M.audio_player, {
		args = args,
	}, function(code, signal)
		-- If using afplay on macOS, restart when finished
		if M.audio_player == "afplay" and M.looping_sound_job ~= nil then
			M.play_looping_sound()
		else
			M.looping_sound_job = nil
		end
	end)

	vim.print("beepboop.nvim: Started looping sound: " .. M.loop_sound)
end

-- Function to stop the looping sound
M.stop_looping_sound = function()
	if M.looping_sound_job == nil then
		vim.print("beepboop.nvim: No looping sound is currently playing")
		return
	end

	-- Stop the sequential looping for paplay/pw-play
	if M.audio_player == "paplay" or M.audio_player == "pw-play" then
		M.loop_active = false
	end

	-- Kill the process
	vim.uv.process_kill(M.looping_sound_job, "sigterm")
	M.looping_sound_job = nil
	vim.print("beepboop.nvim: Stopped looping sound")
end

local initialize_user_commands = function()
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
		local new_volume = tonumber(args.fargs[1])
		if new_volume == nil then
			error("beepboop.nvim: Please provide the volume as a number between 0.0-1.0", 1)
			return
		end
		M.volume = eggutils.clamp(new_volume, 0, 100)
	end, { nargs = "+" })

	-- New commands for looping sound
	vim.api.nvim_create_user_command("BeepBoopLoopStart", function()
		M.play_looping_sound()
	end, {})

	vim.api.nvim_create_user_command("BeepBoopLoopStop", function()
		M.stop_looping_sound()
	end, {})
end

local initialize_auto_commands = function(sound_map)
	-- Groups the autocommands and doesnt allow duplicates that produce the same state
	M.augroup = vim.api.nvim_create_augroup("BeepBoop.nvim", { clear = true })

	for trigger_name, sound in pairs(sound_map) do
		if sound.auto_command then
			vim.api.nvim_create_autocmd(sound.auto_command, {
				callback = function()
					M.play_audio(trigger_name)
				end,
				group = M.augroup,
			})
		end
	end
end

local initialize_key_maps = function(sound_map)
	for trigger_name, sound in pairs(sound_map) do
		if sound.key_map ~= nil then
			if sound.key_map.blocking == nil then
				sound.key_map.blocking = false
			end
			if sound.key_map.blocking then
				vim.keymap.set(sound.key_map.mode, sound.key_map.key_chord, function()
					M.play_audio(trigger_name)
				end)
			else
				local existing = vim.fn.maparg(sound.key_map.key_chord, sound.key_map.mode, false, true)

				if vim.tbl_isempty(existing) then
					vim.keymap.set(sound.key_map.mode, sound.key_map.key_chord, function()
						M.play_audio(trigger_name)
						vim.api.nvim_feedkeys(
							vim.api.nvim_replace_termcodes(sound.key_map.key_chord, true, true, true),
							"n",
							true
						)
					end, { expr = true })
				else
					vim.keymap.set(sound.key_map.mode, sound.key_map.key_chord, function()
						M.play_audio(trigger_name)
						if existing.rhs ~= nil and not vim.tbl_isempty(existing.rhs) then
							if existing.expr == 1 then
							else
								vim.api.nvim_feedkeys(
									vim.api.nvim_replace_termcodes(existing.rhs, true, true, true),
									"n",
									true
								)
							end
						else
							existing.callback()
						end
					end, { expr = true })
				end
			end
		end
	end
end

-- ##################### SETUP #####################

M.play_audio = function(trigger_name)
	if M.sound_map[trigger_name] then
		M.audio_player_callback(M.sound_map[trigger_name].audio_files, M.sound_map[trigger_name].volume)
	else
		if not M.suppress_warnings then
			error(
				'beepboop.nvim: Attempted to trigger sound "'
					.. trigger_name
					.. '", which hasn\'t been defined. Set "suppress_warnings = true" in your config if this is intentional.',
				1
			)
		end
	end
end

M.setup = function(opts)
	vim = vim or nil
	if vim == nil then
		return
	end

	opts = opts or {}

	M.suppress_warnings = opts.suppress_warnings ~= nil

	local sound_directory = validate_sound_directory(opts.sound_directory)
	if sound_directory == nil then
		return
	end

	local audio_player = validate_audio_player(opts.audio_player)
	if audio_player == nil then
		return
	end

	M.audio_player_callback = get_audio_player_callback(audio_player, sound_directory)

	local sound_map = validate_sound_map(opts.sound_map, sound_directory)
	if sound_map == nil then
		return
	end

	-- Validate loop sound if provided
	local loop_sound = validate_loop_sound(opts.loop_sound, sound_directory)

	M.sound_directory = sound_directory
	M.audio_player = audio_player
	M.sound_map = sound_map
	M.loop_sound = loop_sound
	M.max_sounds = opts.max_sounds or 20
	M.process_count = 0

	-- sound_enabled defaults to true
	if opts.sound_enabled == nil then
		M.sound_enabled = true
	else
		M.sound_enabled = opts.sound_enabled
	end

	M.volume = eggutils.clamp(opts.volume or 100, 0, 100) -- volume defaults 100

	initialize_user_commands()
	initialize_auto_commands(sound_map)
	initialize_key_maps(sound_map)
end

return M
