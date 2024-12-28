# BeepBoop.nvim

BeepBoop is a neovim plugin intended to make it easy to incorporate audio cues into neovim. This can be for accessibility reasons, or in my case, just for fun! Check out the demo below for a little taste of whats possible:

### INCLUDE DEMO HERE

## Installation instructions

## I. Get the plugin into your config
Include the following in your `lazy.nvim` config:
```lua
{
    "EggbertFluffle/beepboop.nvim",
    config = (function()
        require("beepboop").setup({
            audio_player = "paplay",
            sound_map = {
                -- SOUND MAP DEFENITIONS HERE
            }
        })
    end),
}
```

## II. Create your sound maps
A sound map can be made in several different ways. The first way is to attach them to a neovim `auto_command`. A list of all the auto_commands in neovim can be found here [https://neovim.io/doc/user/autocmd.html](here).
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

The third way is to use `key_maps` which are very simmilar to `vim.keymap.set("mode", "keychord", "rhs")`.
```lua
{
    { key_map = { mode = "n", key_chord = "<leader>pv" }, sound = "chestopen.oga" },
    { key_map = { mode = "n", key_chord = "<C-Enter>" }, sounds = {"stone1.oga", "stone2.oga", "stone3.oga", "stone4.oga"} },
}
```
These won't override previously defined keymaps for those keychords, but other keymap defenitions *WILL* override these! To avoid this just ensure that your config for beepboop.nvim *runs after* any keymaps you don't want to override.

Sounds can either be defined at `sound = "SOUND NAME"` which will play the defined sound when the sound map is triggered in some whay. The other option is to use sounds, which will play a random defined sound from the list when the sound_map is triggered, defined like so, `sounds = { "SOUND NAME", "OTHER SOUND NAME", "ONE MORE HEHE" }`.

## III. Choose your `audio_player` based on operating system. This is the program that beepboop will call to play the audio files you give it.

### Unix-like (Linux and MacOS) 

* paplay - For PulseAudio, the program `paplay` works flawlessly
* ffplay - Comes with your distro's FFmpeg package
* mpv - Comes in mpv package, very good video player as well
* afplay (***MacOS exclusive***) - Comes default on MacOS, but as far as I can tell **only supports .mp3 and .wav file types**.

WSL is also supported by these audio players but has some issues with latency and is still being tested.

### Windows

Currently no viable options for Windows were identified immediately (and I don't have a great urge to support it either), BUT support for **WSL** is available, albeit not very well. (see above)

### No support
* PipeWire (on the todo list)
* aplay from ALSA (more research) - doesn't have much support for popular audio file formats
* email me if you have any ideas for more audio players that could be useful

## IV. Create a sounds folder
By default it will look in your config folder `sounds` directory, for example: `/home/eggbert/.config/nvim/sounds/`, or the equivalent: `~/.config/nvim/sounds`. This can be changed and spesified with the `sound_directory` option in your config like so:
```lua
{
    sound_directory = "/home/eggbert/.config/nvim/lua/eggbert/sounds/",
}
```

## V. Other options
After loading beepboop.nvim, you get access to some usercommands like `:BeepBoopVolume {volum}`, `:BeepBoopEnable`/`Disable` and `:BeepBoopToggle` which all give volume/mute control over beepboop's playback. Additionally, the `enable`
