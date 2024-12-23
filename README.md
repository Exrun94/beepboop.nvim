# BeepBoop.nvim

BeepBoop is a neovim plugin intended to make it easy to incorporate audio cues into neovim. This can be for accessibility reasons, or in my case, just for fun! Check out the demo below for a little taste of whats possible:

### INCLUDE DEMO HERE

## Installation instructions

1. Get the plugin into your config
Include the following in your `lazy.nvim` config:
```lua
	{
        "EggbertFluffle/beepboop.nvim",
		config = (function()
			require("beepboop").setup({
				audio_player = "pwplay",
				sound_map = {
                    -- SOUND MAP DEFENITIONS HERE
				}
			})
		end),
	}
```

2. Create your sound maps
A sound map can be made in several different ways. The first and main way is to attach them to a neovim `auto_command`. There is a list of commonly used auto_commands and what they do (MAKE A LINK TO THE BOTTOM OF THE README) here. 
```lua
{
    sound_map = {
        { auto_command = "VimEnter", sound = "chestopen.oga" },
        { auto_command = "InsertCharPre", sounds = { "stone1.oga", "stone2.oga", "stone3.oga" } }
    }
}
```

The second way is to use triggers and then call the trigger somewhere else in lua code.
```lua
-- beepboop config
{
    trigger_name = "boom",
    sound = "vineboom.mp3",
}

-- other file
vim.keymap.set("n", "<leader>boom", function() -- just an example of how it *could* be called
    require("beepboop").play_audio("boom")
end)
```

Of course you can give a sound auto_commands, key_presses(tbd), and or a trigger and trigger the sound any way you like. Sounds can either be defined at `sound = "SOUND NAME"` which will play the defined sound when the sound map is triggered in some whay. The other option is to use sounds, which will play a random defined sound from the list when the sound_map is triggered, defined like so, `sounds = { "SOUND NAME", "OTHER SOUND NAME", "ONE MORE HEHE" }`.

3. Choose your `audio_player` based on operating system. This is the program that beepboop will call to play the audio files you give it.

### Linux

* paplay - PulseAudio
For PulseAudio, the program `paplay` works flawlessly.

```lua
{
    audio_player = "paplay",
}
```

* ffplay - FFmpeg
To use ffplay, ensure you have FFmpeg install with your distrobutions package manager.
```lua
{
    audio_player = "ffplay",
}
```

* mpv - mpv
To use mpv, install it with your distributions package manager.
```lua
{
    audio_player = "mpv",
}
```

### Mac

* afplay - macOS
The program `afplay` comes default on al macs. the drawback is that as far as I can tell it ***only supports .mp3 and .wav file types***.
```lua
{
    audio_player = "afplay",
}
```

* other programs
FFmpeg's ffplay and mpv should work on mac as well if they are installed, but haven't been tested.

### Windows w/ WSL

Currently no viable options for Windows were identified immediately (and I don't have a great urge to support it either), BUT support for ***WSL only** is available but is still being tested as the current options don't perform well.

There is currently not support for the following audio interfaces
* Whatever wayland does
* PipeWire

3. Create a sounds folder
By default it will look in your config folder `sounds` directory, for example: `/home/eggbert/.config/nvim/sounds/`. This can be changed and spesified with the `sound_directory` option in your config like so:
```lua
{
    sound_directory = "/home/eggbert/.config/nvim/lua/eggbert/sounds/",
}
```
