local M = {}

M.setup = (function(opts)
	opts = opts or {}

	local sound_directory = opts.sound_directory or "/home/eggbert/.config/nvim/lua/eggbert/sounds/"
	local audio_player = opts.audio_player or "paplay" -- default audio_player is paplay
	local sound_map = opts.sound_map or {}

	for auto_cmd, audio_files in pairs(opts.sound_map or {}) do
		vim.api.nvim_create_autocmd(auto_cmd, {
			callback = function()
				os.execute(audio_player .. " " .. sound_directory .. audio_files[math.random(#audio_files)] .. " &")
			end
		})
	end
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
