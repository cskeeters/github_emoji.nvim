This Neovim plugin provides the user with the capability to input emojis in github flavored markdown through selection via fuzzy finder.

# How it works

The plugin creates a list of emoji from `data/emoji.txt` that is provided to `vim.ui.select`.  The plugin assumes that the user has replaced this with [telescope](https://github.com/nvim-telescope/telescope.nvim)'s [ui-select extension](https://github.com/nvim-telescope/telescope-ui-select.nvim) or [fzf-lua](https://github.com/ibhagwan/fzf-lua).

> [!WARNING]
> Neovim's default UI requires the user to scroll through too many pages of emoji before making a selection which is painful.

# Configuration

```lua
-- function is required so that require('github_emoji') will only execute when key
-- is pressed after Lua is initialized.
function SelectEmoji()
    require('github_emoji').select_emoji()
end

return {
    enabled = true,
    'cskeeters/github_emoji.nvim',
    lazy = false, -- Not lazy so that emoji can be loaded asynchronously

    keys = {
      { mode = {"n", "i"}, "<C-S-e>", SelectEmoji, desc = "Select GitHub Emoji" },
    },
    opts = {
        notify_min_level = vim.log.levels.INFO,
    },
}
```


## fzf-lua

```lua
return {
  "ibhagwan/fzf-lua",
  config = function()
    require("fzf-lua").setup({
        winopts = {
            fullscreen = true,
        },
    })

    -- Replace vim.ui.select menu
    require("fzf-lua").register_ui_select()

  end
}
```

## telescope

```lua
return {
    'nvim-telescope/telescope.nvim',
    dependencies = {
        'nvim-lua/plenary.nvim',
        'nvim-telescope/telescope-ui-select.nvim',
    },

    init = function()
        require("telescope").setup({
            defaults = {
                layout_strategy = 'horizontal',
                layout_config = {
                    height = 0.99,
                    width = 0.99,
                },
                sorting_strategy = "ascending",
            },
        })

        -- Replace vim.ui.select menu
        require('telescope').load_extension('ui-select')
    end
}
```
