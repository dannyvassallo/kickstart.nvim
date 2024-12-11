-- You can add your own plugins here or in other files in this directory!
--  I promise not to create any merge conflicts in this directory :)
--
-- See the kickstart.nvim README for more information
--
--
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

-- Keymaps

local keymap = vim.keymap.set

keymap('n', 'zj', 'o<Esc>k', { desc = 'Create a line above without insert' })
keymap('n', 'zk', 'O<Esc>j', { desc = 'Create a line below without insert' })
keymap('n', '<leader>pv', '<cmd>NvimTreeToggle<CR>', { desc = 'Toggle Neo-Tree' })

keymap('n', '<leader>0', function()
  EqualizeSplits()
end, { noremap = true, silent = true })

-- Resize window using <shift> arrow keys since we have remapped cmd + h/j/k/l as arrow keys this is really convenient
keymap('n', '<S-Up>', '<cmd>resize +2<CR>')
keymap('n', '<S-Down>', '<cmd>resize -2<CR>')
keymap('n', '<S-Left>', '<cmd>vertical resize -2<CR>')
keymap('n', '<S-Right>', '<cmd>vertical resize +2<CR>')

-- move lines
keymap('n', '<A-j>', ':m .+1<CR>==')
keymap('v', '<A-j>', ":m '>+1<CR>gv=gv")
keymap('i', '<A-j>', '<Esc>:m .+1<CR>==gi')
keymap('n', '<A-k>', ':m .-2<CR>==')
keymap('v', '<A-k>', ":m '<-2<CR>gv=gv")
keymap('i', '<A-k>', '<Esc>:m .-2<CR>==gi')

-- Add undo break-points
keymap('i', ',', ',<c-g>u')
keymap('i', '.', '.<c-g>u')
keymap('i', ';', ';<c-g>u')

keymap('n', 'J', 'mzJ`z')

-- Center screen after C-d / C-u
keymap('n', '<C-d>', '<C-d>zz')
keymap('n', '<C-u>', '<C-u>zz')

keymap('n', 'N', 'Nzzzv')

keymap('n', 'n', 'nzzzv')

-- paste from register without overriding register
keymap('x', '<leader>p', [["_dP]])

-- yank to global(?) clipboard ...i.e. can now paste outside of vim buffers
keymap({ 'n', 'v' }, '<leader>y', [["+y]])
keymap('n', '<leader>Y', [["+Y]])

-- delete without overwriting vim register
keymap({ 'n', 'v' }, '<leader>d', [["_d]])

keymap('n', 'Q', '<nop>')

keymap('n', '<leader>f', vim.lsp.buf.format)

-- search and replace word under cursor
keymap('n', '<leader>s', [[:%s/\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>]])

-- nice way to exit normal mode
keymap('i', 'jj', '<esc>')
keymap('i', 'kk', '<esc>')

keymap('n', '<leader>sv', '<cmd> vsplit<CR><C-w>w', { desc = 'Split pane vertically' })
keymap('n', '<leader>sh', '<cmd> split<CR><C-w>w', { desc = 'Split pane horizontally' })

-- Diagnostic keymaps
keymap('n', '[d', vim.diagnostic.goto_prev, { desc = 'Go to previous diagnostic message' })
keymap('n', ']d', vim.diagnostic.goto_next, { desc = 'Go to next diagnostic message' })
keymap('n', '<leader>de', vim.diagnostic.open_float, { desc = 'Open floating diagnostic message' })
keymap('n', '<leader>dl', vim.diagnostic.setloclist, { desc = 'Open diagnostics list' })

-- Stay in visual mode when changing the indent for selection
keymap('v', '<', '<gv')
keymap('v', '>', '>gv')

-- Map enter to ciw in normal mode
keymap('n', '<CR>', 'ciw')

keymap({ 'n', 'o', 'x' }, '<s-h>', '^')
keymap({ 'n', 'o', 'x' }, '<s-l>', 'g_')

keymap('n', '<leader>L', 'vg_', { desc = 'Select to end of line' })
keymap('n', '<leader>pa', 'ggVGp', { desc = 'Select all and paste' })
keymap('n', '<leader>sa', 'ggVG', { desc = 'Select all' })
keymap('n', '<leader>gp', '`[v`]', { desc = 'Select pasted text' })
keymap('n', '<BS>', '^', { desc = 'Move to first non-blank char' })
keymap(
  'n',
  '<leader>cpf',
  ':let @+ = expand("%:p")<cr>:lua print("Copied path to: " .. vim.fn.expand("%:p"))<cr>',
  { desc = 'Copy current file name and path', silent = false }
)

keymap('n', 'U', '<C-r>')
keymap('n', 'U', '<C-r>')

keymap('n', '<leader>xo', ':e <C-r>+<CR>', { noremap = true, desc = 'Go to location in clipboard' })

keymap('n', '<leader>x', function()
  utils.CopyFilePathAndLineNumber()
end, { noremap = true, desc = 'copy file path and line number' })

keymap('n', 'dd', function()
  if vim.fn.getline '.' == '' then
    return '"_dd'
  end
  return 'dd'
end, { expr = true })

keymap('n', '<leader>dm', ':delm! | delm A-Z0-9<CR>', {})

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
  {
    'nvim-neo-tree/neo-tree.nvim',
    enabled = false,
  },

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
}
