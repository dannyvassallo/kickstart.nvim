-- You can add your own plugins here or in other files in this directory!
--  I promise not to create any merge conflicts in this directory :)
--
-- See the kickstart.nvim README for more information

-- Indentation with brackets
vim.keymap.set('v', '<D-]>', '>gv', { noremap = true, silent = true })
vim.keymap.set('v', '<D-[>', '<gv', { noremap = true, silent = true })

-- Copy paste like a normal person
vim.keymap.set({ 'n', 'v' }, '<D-c>', '"+y', { noremap = true, silent = true })
vim.keymap.set({ 'n', 'i', 'v' }, '<D-v>', '<C-R>+', { noremap = true, silent = true })

-- New mapping for select all
vim.keymap.set({ 'n', 'v', 'i' }, '<D-a>', 'ggVG', { noremap = true, silent = true })
vim.keymap.set('i', '<D-a>', '<Esc>ggVG', { noremap = true, silent = true })

-- Open new files in tabs
vim.api.nvim_create_autocmd('VimEnter', {
  callback = function()
    if vim.bo.buftype ~= 'terminal' then
      if vim.fn.argc() >= 1 then
        vim.cmd 'tab all'
      end
    end
  end,
})

-- auto commands
local function augroup(name)
  return vim.api.nvim_create_augroup('mnv_' .. name, { clear = true })
end

-- See `:help vim.highlight.on_yank()`
-- local highlight_group = vim.api.nvim_create_augroup("YankHighlight", { clear = true })
local highlight_group = augroup 'YankHighlight'
vim.api.nvim_create_autocmd('TextYankPost', {
  callback = function()
    vim.highlight.on_yank()
  end,
  group = highlight_group,
  pattern = '*',
})

-- Check if we need to reload the file when it changed
vim.api.nvim_create_autocmd({ 'FocusGained', 'TermClose', 'TermLeave' }, {
  group = augroup 'checktime',
  command = 'checktime',
})

-- go to last loc when opening a buffer
vim.api.nvim_create_autocmd('BufReadPost', {
  callback = function()
    local mark = vim.api.nvim_buf_get_mark(0, '"')
    local lcount = vim.api.nvim_buf_line_count(0)
    if mark[1] > 0 and mark[1] <= lcount then
      pcall(vim.api.nvim_win_set_cursor, 0, mark)
    end
  end,
})

-- Auto toggle hlsearch
local ns = vim.api.nvim_create_namespace 'toggle_hlsearch'
local function toggle_hlsearch(char)
  if vim.fn.mode() == 'n' then
    local keys = { '<CR>', 'n', 'N', '*', '#', '?', '/' }
    local new_hlsearch = vim.tbl_contains(keys, vim.fn.keytrans(char))

    if vim.opt.hlsearch:get() ~= new_hlsearch then
      vim.opt.hlsearch = new_hlsearch
    end
  end
end
vim.on_key(toggle_hlsearch, ns)

-- windows to close
vim.api.nvim_create_autocmd('FileType', {
  pattern = {
    'OverseerForm',
    'OverseerList',
    'floggraph',
    'fugitive',
    'git',
    'help',
    'lspinfo',
    'man',
    'neotest-output',
    'neotest-summary',
    'oil',
    'qf',
    'query',
    'Scratch',
    'spectre_panel',
    'startuptime',
    'toggleterm',
    'tsplayground',
    'vim',
  },
  callback = function(event)
    vim.bo[event.buf].buflisted = false
    vim.keymap.set('n', 'q', '<cmd>close<cr>', { buffer = event.buf, silent = true })
  end,
})

vim.api.nvim_command 'autocmd VimResized * wincmd ='

-- ensure we always have a transparent background when we change themes :)
vim.api.nvim_create_autocmd('ColorScheme', {
  callback = function()
    local highlights = {
      'Normal',
      'LineNr',
      'Folded',
      'NonText',
      'SpecialKey',
      'VertSplit',
      'SignColumn',
      'EndOfBuffer',
      'TablineFill', -- this is specific to how I like my tabline to look like
    }
    for _, name in pairs(highlights) do
      vim.cmd.highlight(name .. ' guibg=none ctermbg=none')
    end
  end,
})

--vim.api.nvim_create_autocmd('VimEnter', {
--callback = function()
-- vim.cmd("<cmd>Telescope diagnostics<cr>")
--vim.cmd "lua require('telescope.builtin').find_files()"
--end,
--})

-- allow for 2 space indenting for some files
local setIndent = augroup 'setIndent'
vim.api.nvim_create_autocmd('Filetype', {
  group = setIndent,
  pattern = { 'xml', 'html', 'xhtml', 'css', 'scss', 'javascript', 'typescript', 'jsx', 'tsx', 'typescriptreact', 'javascriptreact' },
  command = 'setlocal shiftwidth=2 tabstop=2',
})

-- no more annoying eol issues when comparing buffers
vim.api.nvim_create_autocmd({ 'FileType' }, {
  pattern = { 'json', 'yaml', 'txt', '.sarif' },
  command = 'setlocal noeol binary shiftwidth=2 tabstop=2 expandtab smartindent fileformats=mac,unix,dos',
})

vim.api.nvim_create_autocmd('User', {
  pattern = 'LazyVimStarted',
  callback = function()
    vim.schedule(function()
      require('telescope.builtin').find_files()
    end)
  end,
})

-- Utils
local M = {}

function M.EqualizeSplits()
  vim.cmd 'wincmd =' -- Equalize the size of all windows
end

function M.SmartDelete()
  if vim.fn.getline '.' == '' then
    return '"_dd'
  end
  return 'dd'
end

-- ty @ https://github.com/adibhanna/nvim/blob/main/lua/config/utils.lua
function M.CopyFilePathAndLineNumber()
  local current_file = vim.fn.expand '%:p'
  local current_line = vim.fn.line '.'
  local is_git_repo = vim.fn.system('git rev-parse --is-inside-work-tree'):match 'true'

  if is_git_repo then
    local current_repo = vim.fn.systemlist('git remote get-url origin')[1]
    local current_branch = vim.fn.systemlist('git rev-parse --abbrev-ref HEAD')[1]

    -- Convert Git URL to GitHub web URL format
    current_repo = current_repo:gsub('git@github.com:', 'https://github.com/')
    current_repo = current_repo:gsub('%.git$', '')

    -- Remove leading system path to repository root
    local repo_root = vim.fn.systemlist('git rev-parse --show-toplevel')[1]
    if repo_root then
      current_file = current_file:sub(#repo_root + 2)
    end

    local url = string.format('%s/blob/%s/%s#L%s', current_repo, current_branch, current_file, current_line)
    vim.fn.setreg('+', url)
    print('Copied to clipboard: ' .. url)
  else
    -- If not in a Git directory, copy the full file path
    vim.fn.setreg('+', current_file .. '#L' .. current_line)
    print('Copied full path to clipboard: ' .. current_file .. '#L' .. current_line)
  end
end

-- Lazyvim config

return {
  -- Add Dracula theme
  { 'Mofiqul/dracula.nvim' },

  -- Configure LazyVim to load Dracula
  {
    'LazyVim/LazyVim',
    opts = {
      colorscheme = 'dracula',
    },
  },

  -- Add snacks.nvim
  {
    'folke/snacks.nvim',
    priority = 1000,
    lazy = false,
    opts = {
      bigfile = { enabled = true },
      notifier = { enabled = true },
      quickfile = { enabled = true },
      statuscolumn = { enabled = true },
      words = { enabled = true },
    },
  },

  -- Add nvim-tree
  {
    'nvim-tree/nvim-tree.lua',
    dependencies = { 'nvim-tree/nvim-web-devicons' },
    lazy = false, -- Load immediately on startup
    config = function()
      require('nvim-tree').setup {
        view = {
          width = 30,
          side = 'left',
        },
        renderer = {
          icons = {
            show = {
              file = true,
              folder = true,
              folder_arrow = true,
              git = true,
            },
          },
        },
        diagnostics = {
          enable = true,
        },
        git = {
          enable = true,
        },
        update_focused_file = {
          enable = true,
          update_cwd = true,
        },
      }

      -- Automatically open the file tree when starting Neovim
      local function open_nvim_tree()
        -- Check if the buffer is empty (no file opened yet)
        local bufnr = vim.api.nvim_get_current_buf()
        local bufname = vim.api.nvim_buf_get_name(bufnr)
        if bufname == '' then
          require('nvim-tree.api').tree.open()
        end
      end

      vim.api.nvim_create_autocmd({ 'VimEnter' }, { callback = open_nvim_tree })
    end,
  },

  -- Optional: Disable Neo-tree if used by LazyVim
  --{
  --'nvim-neo-tree/neo-tree.nvim',
  --enabled = false,
  --},

  -- Add null-ls for linting and formatting
  {
    'jose-elias-alvarez/null-ls.nvim',
    dependencies = { 'nvim-lua/plenary.nvim' },
    lazy = false,
    config = function()
      local null_ls = require 'null-ls'
      null_ls.setup {
        sources = {
          null_ls.builtins.formatting.prettier,
          null_ls.builtins.diagnostics.eslint,
          null_ls.builtins.code_actions.eslint,
        },
      }
    end,
  },

  -- Add Treesitter for syntax highlighting and bracket colorization
  {
    'nvim-treesitter/nvim-treesitter',
    lazy = false,
    build = ':TSUpdate',
    config = function()
      require('nvim-treesitter.configs').setup {
        highlight = {
          enable = true,
        },
        rainbow = {
          enable = true,
          extended_mode = true,
        },
      }
    end,
  },

  -- YAML language server for schema validation
  {
    'neovim/nvim-lspconfig',
    lazy = false,
    config = function()
      require('lspconfig').yamlls.setup {
        settings = {
          yaml = {
            schemas = {
              ['file:///path/to/schema.json'] = '**/definition.yaml',
            },
          },
        },
      }
    end,
  },

  {
    'mg979/vim-visual-multi',
    event = 'VeryLazy',
    init = function()
      -- Disable default mappings
      vim.g.VM_default_mappings = 0

      -- Set up custom mappings
      vim.g.VM_maps = {
        ['Find Under'] = '<C-d>', -- Ctrl+d to select next occurrence
        ['Find Subword Under'] = '<C-d>', -- Same for subword
        ['Select Cursor Down'] = '<C-Down>', -- Ctrl+Down to add cursor below
        ['Select Cursor Up'] = '<C-Up>', -- Ctrl+Up to add cursor above
        ['Undo'] = '<C-u>', -- Ctrl+u to undo last selection
        ['Redo'] = '<C-r>', -- Ctrl+r to redo
        ['Add Cursor At Pos'] = '<C-LeftMouse>', -- Ctrl+LeftClick to add cursor
      }

      -- Additional Cmd key mappings for GUI Neovim
      if vim.fn.has 'gui_running' == 1 then
        vim.g.VM_maps['Find Under'] = '<D-d>'
        vim.g.VM_maps['Find Subword Under'] = '<D-d>'
        vim.g.VM_maps['Undo'] = '<D-u>'
        vim.g.VM_maps['Redo'] = '<D-r>'
        vim.g.VM_maps['Add Cursor At Pos'] = '<D-LeftMouse>'
      end
    end,
  },

  --

  -- {
  --   'https://git.sr.ht/~swaits/zellij-nav.nvim',
  --   lazy = true,
  --   event = 'VeryLazy',
  --   keys = {
  --     { '<c-h>', '<cmd>ZellijNavigateLeftTab<cr>', { silent = true, desc = 'navigate left or tab' } },
  --     { '<c-j>', '<cmd>ZellijNavigateDown<cr>', { silent = true, desc = 'navigate down' } },
  --     { '<c-k>', '<cmd>ZellijNavigateUp<cr>', { silent = true, desc = 'navigate up' } },
  --     { '<c-l>', '<cmd>ZellijNavigateRightTab<cr>', { silent = true, desc = 'navigate right or tab' } },
  --   },
  --   opts = {},
  -- },

  {
    'numToStr/Comment.nvim',
    opts = {},
    keys = {
      -- Add this line to map Cmd+/ for both normal and visual modes
      { '<D-/>', mode = { 'n', 'v' }, desc = 'Comment toggle' },
    },
    config = function(_, opts)
      require('Comment').setup(opts)

      local api = require 'Comment.api'

      vim.keymap.set('n', '<D-/>', api.toggle.linewise.current, { desc = 'Comment toggle current line' })
      vim.keymap.set('x', '<D-/>', function()
        vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('<ESC>', true, false, true), 'nx', false)
        api.toggle.linewise(vim.fn.visualmode())
      end, { desc = 'Comment toggle linewise (visual)' })
    end,
  },

  -- LSP Configuration for TypeScript
  {
    'neovim/nvim-lspconfig',
    dependencies = {
      'williamboman/mason.nvim',
      'williamboman/mason-lspconfig.nvim',
      'jose-elias-alvarez/typescript.nvim', -- TypeScript utilities
    },
    event = { 'BufReadPre', 'BufNewFile' },
    opts = {
      servers = {
        rust_analyzer = {
          mason = false,
          cmd = { vim.fn.expand '~/.rustup/toolchains/nightly-x86_64-unknown-linux-gnu/bin/rust-analyzer' },
          settings = {
            ['rust-analyzer'] = {
              imports = {
                granularity = {
                  group = 'module',
                },
                prefix = 'self',
              },
              cargo = {
                buildScripts = {
                  enable = true,
                },
              },
              procMacro = {
                enable = true,
              },
            },
          },
        },
      },
    },
    config = function()
      require('lspconfig').tsserver.setup {
        on_attach = function(client, bufnr)
          local bufmap = function(keys, func)
            vim.keymap.set('n', keys, func, { buffer = bufnr })
          end
          bufmap('<leader>co', ':TypescriptOrganizeImports<CR>')
          bufmap('<leader>cR', ':TypescriptRenameFile<CR>')
        end,
      }

      -- Add multiple mappings for "go to definition"
      local goto_definition = function()
        vim.lsp.buf.definition()
      end

      vim.keymap.set('n', '<A-LeftMouse>', goto_definition, { desc = 'Go to definition (Alt+LeftClick)' })
      vim.keymap.set('n', '<M-LeftMouse>', goto_definition, { desc = 'Go to definition (Meta+LeftClick)' })
      vim.keymap.set('n', 'gd', goto_definition, { desc = 'Go to definition (gd)' })
      vim.keymap.set('n', '<C-]>', goto_definition, { desc = 'Go to definition (Ctrl+])' })

      -- Optionally, add a mapping that doesn't require the mouse
      vim.keymap.set('n', '<leader>gd', goto_definition, { desc = 'Go to definition' })
    end,
  },

  -- Tailwind CSS and Colorizer for Autocomplete
  {
    'roobert/tailwindcss-colorizer-cmp.nvim',
    dependencies = { 'hrsh7th/nvim-cmp' },
    config = function()
      require('tailwindcss-colorizer-cmp').setup()
    end,
  },

  -- Prettier Formatter
  {
    'MunifTanjim/prettier.nvim',
    dependencies = { 'neovim/nvim-lspconfig' },
    config = function()
      require('prettier').setup {
        bin = 'prettier',
        filetypes = {
          'javascript',
          'typescript',
          'css',
          'html',
          'json',
          'markdown',
          'react',
          'typescriptreact',
        },
      }
    end,
  },

  -- Treesitter for better syntax highlighting
  {
    'nvim-treesitter/nvim-treesitter',
    build = ':TSUpdate',
    opts = {
      ensure_installed = { 'javascript', 'typescript', 'tsx', 'html', 'css', 'json' },
      highlight = { enable = true },
      indent = { enable = true },
    },
  },

  -- Git integration
  {
    'lewis6991/gitsigns.nvim',
    config = function()
      require('gitsigns').setup()
    end,
  },

  {
    'nvim-telescope/telescope.nvim',
    keys = {
      -- Add this line to map Cmd+P to Telescope find_files
      { '<C-f>', '<cmd>Telescope live_grep<cr>', desc = 'Grep Files' },
      { '<D-p>', '<cmd>Telescope find_files<cr>', desc = 'Find Files' },
    },
    -- Keep any existing options and configuration you might have
    opts = {
      -- Your existing Telescope options here (if any)
      defaults = {
        mappings = {
          i = {
            ['<CR>'] = function(bufnr)
              require('telescope.actions').select_default(bufnr)
              vim.cmd 'tabclose'
              vim.cmd 'tabnew'
              vim.cmd('b' .. vim.fn.bufnr '#')
            end,
          },
        },
      },
    },
    config = function(_, opts)
      require('telescope').setup(opts)

      -- Add an additional keymap for ctrl+f
      vim.keymap.set('n', '<C-f>', function()
        require('telescope.builtin').live_grep()
      end, { desc = 'Grep Files (ctrl+F)' })

      -- Add an additional keymap for Cmd+P
      vim.keymap.set('n', '<D-p>', function()
        require('telescope.builtin').find_files()
      end, { desc = 'Find Files (Cmd+P)' })
    end,
  },

  {
    'ruifm/gitlinker.nvim',
    dependencies = { 'nvim-lua/plenary.nvim' },
    config = function()
      require('gitlinker').setup {
        opts = {
          -- Options to customize behavior
          callbacks = nil, -- Custom remote URL callbacks
          remote = nil, -- Remote to use (e.g., "origin")
          add_current_line_on_normal_mode = true, -- Add current line in normal mode
          action_callback = require('gitlinker.actions').open_in_browser, -- Default action to open in browser
          print_url = true, -- Print the URL after generation
          mappings = '<leader>gy', -- Default keybinding to copy the URL
        },
      }
    end,
  },

  {
    'APZelos/blamer.nvim',
    config = function()
      -- Always enable Blamer
      vim.g.blamer_enabled = 1

      -- Display Blamer annotations without delay
      vim.g.blamer_delay = 0

      -- Optional: Customize appearance
      vim.g.blamer_prefix = '  ' -- Git icon prefix (can be any string)
      vim.g.blamer_date_format = '%Y-%m-%d' -- Date format for blame messages

      -- Always show blame in all modes
      vim.g.blamer_show_in_visual_modes = 1
      vim.g.blamer_show_in_insert_modes = 1
    end,
  },

  {
    'hrsh7th/nvim-cmp',
    dependencies = {
      'hrsh7th/cmp-nvim-lsp',
      'hrsh7th/cmp-buffer',
      'hrsh7th/cmp-path',
      'hrsh7th/cmp-cmdline',
      'L3MON4D3/LuaSnip',
      'saadparwaiz1/cmp_luasnip',
    },
    config = function()
      local cmp = require 'cmp'
      local luasnip = require 'luasnip'

      cmp.setup {
        snippet = {
          expand = function(args)
            luasnip.lsp_expand(args.body)
          end,
        },
        mapping = cmp.mapping.preset.insert {
          ['<C-b>'] = cmp.mapping.scroll_docs(-4),
          ['<C-f>'] = cmp.mapping.scroll_docs(4),
          ['<C-Space>'] = cmp.mapping.complete(),
          ['<C-e>'] = cmp.mapping.abort(),
          ['<CR>'] = cmp.mapping.confirm { select = true },
          ['<Tab>'] = cmp.mapping(function(fallback)
            if cmp.visible() then
              cmp.select_next_item()
            elseif luasnip.expand_or_jumpable() then
              luasnip.expand_or_jump()
            else
              fallback()
            end
          end, { 'i', 's' }),
          ['<S-Tab>'] = cmp.mapping(function(fallback)
            if cmp.visible() then
              cmp.select_prev_item()
            elseif luasnip.jumpable(-1) then
              luasnip.jump(-1)
            else
              fallback()
            end
          end, { 'i', 's' }),
        },
        sources = cmp.config.sources({
          { name = 'nvim_lsp' },
          { name = 'luasnip' },
        }, {
          { name = 'buffer' },
        }),
      }
    end,
  },

  -- Statusline
  {
    'nvim-lualine/lualine.nvim',
    dependencies = { 'nvim-tree/nvim-web-devicons' },
    config = function()
      require('lualine').setup {
        options = {
          theme = 'auto',
          globalstatus = true,
        },
        sections = {
          lualine_a = { 'mode' },
          lualine_b = { 'branch', 'diff', 'diagnostics' },
          lualine_c = { 'filename' },
          lualine_x = { 'encoding', 'fileformat', 'filetype' },
          lualine_y = { 'progress' },
          lualine_z = { 'location' },
        },
        tabline = {
          lualine_a = { 'buffers' },
          lualine_b = {},
          lualine_c = {},
          lualine_x = {},
          lualine_y = {},
          lualine_z = { 'tabs' },
        },
      }

      -- Enable the tabline
      vim.opt.showtabline = 2 -- Always show tabline
    end,
  },

  {
    'romgrk/barbar.nvim',
    dependencies = {
      'lewis6991/gitsigns.nvim',
      'nvim-tree/nvim-web-devicons',
    },
    init = function()
      vim.g.barbar_auto_setup = false
    end,
    opts = {
      -- Your barbar options here
    },
    config = function()
      local map = vim.api.nvim_set_keymap
      local opts = { noremap = true, silent = true }

      -- Move to previous/next
      map('n', '<A-,>', '<Cmd>BufferPrevious<CR>', opts)
      map('n', '<A-.>', '<Cmd>BufferNext<CR>', opts)
      -- Re-order to previous/next
      map('n', '<A-<>', '<Cmd>BufferMovePrevious<CR>', opts)
      map('n', '<A->>', '<Cmd>BufferMoveNext<CR>', opts)
      -- Close buffer
      map('n', '<A-c>', '<Cmd>BufferClose<CR>', opts)
    end,
    version = '^1.0.0',
  },
}
