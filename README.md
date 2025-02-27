# BeepBoop.nvim

BeepBoop is a neovim plugin intended to make it easy to incorporate audio cues into neovim. This can be for accessibility reasons, or in my case, just for fun! Check out the demo below for a little taste of whats possible:

https://github.com/user-attachments/assets/0c3fa223-4d8c-428e-b561-bcbee5ccce8a

## Installation instructions

### I. Get the plugin into your config
Include the following in your `lazy.nvim` config:
```lua
{
    "EggbertFluffle/beepboop.nvim",
    opts = {
        max_sounds = 20,
        sound_map = {
            -- SOUND MAP DEFENITIONS HERE
        },
        loop_sound = "background_music.oga" -- Optional: special sound for looping
    }
}
```

### II. Create your sound maps
A sound map can be made in several different ways. The first way is to attach them to a neovim `auto_command`. A list of all the auto_commands in neovim can be found here [https://neovim.io/doc/user/autocmd.html](here).
```lua
{
    sound_map = {
        { auto_command = "VimEnter", sound = "chestopen.oga" },
        { auto_command = "InsertCharPre", sounds = { "stone1.oga", "stone2.oga", "stone3.oga" } }
    }
}
```

The second way is to use `key_maps` which are very simmilar to `vim.keymap.set("mode", "keychord", "rhs")`.
```lua
{
    { key_map = { mode = "n", key_chord = "<leader>pv", blocking = false }, sound = "chestopen.oga" },
    { key_map = { mode = "n", key_chord = "<C-Enter>", blocking = true }, sounds = {"stone1.oga", "stone2.oga", "stone3.oga", "stone4.oga"} },
}
```
These won't override previously defined keymaps for those keychords by default, but other keymap defenitions *WILL* override these! To avoid this just ensure that your config for beepboop.nvim *runs after* any keymaps you don't want to override. There is also the option for blocking and non-blocking keymaps to sounds. This means, when blocking is enabled, it will be like a normal keymap and *OVERRIDE* any previously set keymap, whereas when blocking is disabled, any previously made keymap will still play in addition to the sound.

The final way is to use triggers and then call the trigger somewhere else in lua code/neovim config.
```lua
-- beepboop config
{
    -- The sound_map below can EITHER be triggered by the key_chord OR a call to require("beepboop").play_audio("boom")
    { trigger_name = "boom", key_map = { mode = "n", key_chord = "<leader>pv" }, sound = "boom.oga" },

    -- The sound_map below can ONLY be tirggered by a call to require("beepboop").play_audio("bap")
    { trigger_name = "bap", sound = "bap.oga" },
}

-- other file
vim.keymap.set("n", "<leader>boom", function() -- just an example of how it *could* be called
    require("beepboop").play_audio("bap")
end)
```


Sounds can either be defined at `sound = "SOUND NAME"` which will play the defined sound when the sound map is triggered in some whay. The other option is to use sounds, which will play a random defined sound from the list when the sound_map is triggered, defined like so, `sounds = { "SOUND NAME", "OTHER SOUND NAME", "ONE MORE HEHE" }`.

### III. Audio Player

This plugin uses `paplay` exclusively to play audio files. Make sure you have the PulseAudio utilities installed on your Linux system:

* On Ubuntu/Debian: `sudo apt-get install pulseaudio-utils`
* On Fedora: `sudo dnf install pulseaudio-utils`
* On Arch: `sudo pacman -S pulseaudio-utils`

Note that this plugin only supports Linux systems with PulseAudio. Windows and macOS are not supported.

If you're using PipeWire as your audio server, you'll still have `paplay` available through PipeWire's PulseAudio compatibility layer.

### IV. Create a sounds folder
By default it will look in your config folder `sounds` directory, for example: `/home/eggbert/.config/nvim/sounds/`, or the equivalent: `~/.config/nvim/sounds`. This can be changed and spesified with the `sound_directory` option in your config like so:
```lua
{
    sound_directory = "/home/eggbert/.config/nvim/lua/eggbert/sounds/",
}
```

### V. Other options
After loading beepboop.nvim, you get access to some usercommands like `:BeepBoopVolume {volum}`, `:BeepBoopEnable`/`Disable` and `:BeepBoopToggle` which all give volume/mute control over beepboop's playback. Additionally, the `enable_sound` option will either pick the default state for the result of these commands when neovim is started.
* If you find that there are too many sounds playing, there is a default `max_sounds` of 20, but this property can be altered if desired.

### VI. Loop Sound
The plugin supports a special looping sound feature. This allows you to configure a background sound that will play continuously until stopped.

#### Configuration
Specify a loop sound in your plugin configuration:
```lua
{
    "EggbertFluffle/beepboop.nvim",
    opts = {
        -- other options
        loop_sound = "my_background_music.oga" 
    }
}
```

#### Commands
- `:BeepBoopLoopStart` - Start playing the configured loop sound
- `:BeepBoopLoopStop` - Stop the currently playing loop sound

#### Notes
- The loop sound can only be triggered manually with the command
- The plugin uses `pgrep` to detect if a looping sound is already playing
- If a looping sound is already playing, attempting to start it again will show a message
- When you exit Vim or call `:BeepBoopLoopStop`, the plugin will automatically kill any running loop sound processes
- Only one loop sound can play at a time across all Neovim instances

### VII. Plugin Compatability
Just some notes on using other plugins that are known to or may conflict with beepboop.nvim

#### nvim-autopairs
If using nvim-autopairs this will not allow beepboop.nvim to map sounds to <BS> (backspace key) or <CR> (enter key) by default. If you don't intend to map these keys to sounds, there's no conflict. If you do though, you need to turn off the maps for autopairs to <BS> and or  <CR> by including the following in your nvim-autopairs config:
```lua
{
    "windwp/nvim-autopairs",
    config = function()
        require("nvim-autopairs").setup({
            map_bs = false, -- removes map to <BS>
            map_cr = false  -- removes map to <CR>
        })
    end,
},
```

## Bug Reporting
I expect there to be a lot of bugs. If you end up finding one, please feel free to let me know through (or don't) through GitHub Issues or a simple e-mail to hdiambrosio@gmail.com. I'd love the support if you can offer it. Additionally, if you have any ideas, I'd love to hear them and be sure to tell your friends how lit this plugin is.
