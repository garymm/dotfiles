hs.window.animationDuration = 0.0

-- config for https://github.com/corentin-ant/PaperWM.spoon
PaperWM = hs.loadSpoon("PaperWM")
-- based on https://github.com/garymm/dotfiles/blob/master/mac/.config/skhd/skhdrc
PaperWM:bindHotkeys({
    -- Focus window (m,n,e,i = west,south,north,east - Colemak layout)
    focus_left = {{"alt"}, "m"},
    focus_down = {{"alt"}, "n"},
    focus_up = {{"alt"}, "e"},
    focus_right = {{"alt"}, "i"},

    -- Swap windows
    swap_left = {{"alt", "shift"}, "m"},
    swap_down = {{"alt", "shift"}, "n"},
    swap_up = {{"alt", "shift"}, "e"},
    swap_right = {{"alt", "shift"}, "i"},

    -- Go to specific spaces. Doing this through OS shortcuts instead
    -- see Settings > Keyboard > Shortcuts > Mission Control
--     switch_space_1 = {{"ctrl"}, "1"},


    -- Send to space
    move_window_1 = {{"shift", "ctrl"}, "1"},
    move_window_2 = {{"shift", "ctrl"}, "2"},
    move_window_3 = {{"shift", "ctrl"}, "3"},
    move_window_4 = {{"shift", "ctrl"}, "4"},
    move_window_5 = {{"shift", "ctrl"}, "5"},
    move_window_6 = {{"shift", "ctrl"}, "6"},
    move_window_7 = {{"shift", "ctrl"}, "7"},
    move_window_8 = {{"shift", "ctrl"}, "8"},
    move_window_9 = {{"shift", "ctrl"}, "9"},
    move_window_10 = {{"shift", "ctrl"}, "0"},

    -- Toggle float
    toggle_floating = {{"alt"}, "f"},

    -- position and resize focused window
    full_width           = {{"ctrl", "alt"}, "f"},
    cycle_width          = {{"ctrl", "cmd"}, "r"},
    reverse_cycle_width  = {{"ctrl", "alt", "cmd"}, "r"},
    cycle_height         = {{"alt", "cmd", "shift"}, "r"},
    reverse_cycle_height = {{"ctrl", "alt", "cmd", "shift"}, "r"},

    -- move focused window into / out of a column
    slurp_in = {{"alt", "cmd"}, "i"},
    barf_out = {{"alt", "cmd"}, "o"},
})

PaperWM.window_gap = 4

PaperWM:start()