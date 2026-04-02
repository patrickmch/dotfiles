-- cc-ide.lua — CC IDE features for nvim
-- Adds: project picker, Claude terminal, sidebar toggle, window/tab nav
-- Loaded via: lua require("cc-ide") in init.vim
-- Does NOT replace .vimrc — only adds CC IDE keybindings and functions.
--
-- Keybinding overrides from .vimrc:
--   Ctrl+h was :Mru, now gT (prev tab)
--   Ctrl+l was :Buffers, now gt (next tab)
--   Use :Mru and :Buffers manually or remap if needed.

local M = {}

-------------------------------------------------------------------------------
-- Theme: Catppuccin Mocha
-------------------------------------------------------------------------------
local ok, catppuccin = pcall(require, "catppuccin")
if ok then
  catppuccin.setup({
    flavour = "mocha",
    integrations = {
      nvimtree = true,
    },
  })
  vim.cmd.colorscheme("catppuccin")
  -- Update lightline to a compatible dark theme
  vim.g["lightline"] = vim.tbl_deep_extend("force", vim.g["lightline"] or {}, {
    colorscheme = "rosepine_moon",
  })
end

-------------------------------------------------------------------------------
-- Helpers
-------------------------------------------------------------------------------
local function toggle_sidebar()
  require("nvim-tree.api").tree.toggle({ find_file = false, focus = false })
end

-- Make nvim-tree open files in a split, never replacing a terminal buffer
local function setup_nvimtree_open_behavior()
  local api = require("nvim-tree.api")
  api.events.subscribe(api.events.Event.FileOpened, function()
    -- After opening a file, close nvim-tree if it was focused
    -- (the file opens in the previous window by default)
  end)
end

-- Override nvim-tree setup to open files in floating windows
-- This re-calls setup with on_attach — safe to call after .vimrc's setup
local function cc_nvimtree_on_attach(bufnr)
  local api = require("nvim-tree.api")
  -- Apply all default mappings first
  api.config.mappings.default_on_attach(bufnr)

  -- Override Enter: files open in float, dirs expand/collapse
  vim.keymap.set("n", "<CR>", function()
    local node = api.tree.get_node_under_cursor()
    if not node or node.type == "directory" then
      api.node.open.edit()
      return
    end
    -- Open file in a centered floating window
    local buf = vim.fn.bufadd(node.absolute_path)
    vim.fn.bufload(buf)
    local width = math.floor(vim.o.columns * 0.75)
    local height = math.floor(vim.o.lines * 0.8)
    local col = math.floor((vim.o.columns - width) / 2)
    local row = math.floor((vim.o.lines - height) / 2)
    vim.api.nvim_open_win(buf, true, {
      relative = "editor",
      width = width,
      height = height,
      col = col,
      row = row,
      style = "minimal",
      border = "rounded",
    })
    -- q and Esc close the float
    vim.keymap.set("n", "q", "<cmd>close<CR>", { buffer = buf, desc = "Close float" })
    vim.keymap.set("n", "<Esc>", "<cmd>close<CR>", { buffer = buf, desc = "Close float" })
  end, { buffer = bufnr, desc = "Open file in float" })
end

-- Re-setup nvim-tree with our on_attach (preserves existing .vimrc settings)
require("nvim-tree").setup({
  on_attach = cc_nvimtree_on_attach,
})

local function open_claude()
  vim.cmd("vsplit")
  vim.cmd("terminal " .. vim.fn.expand("~/bin/claude"))
end

local function open_claude_skip()
  vim.cmd("vsplit")
  vim.cmd("terminal " .. vim.fn.expand("~/bin/claude") .. " --dangerously-skip-permissions")
end

local function open_project(dir)
  vim.cmd("tabnew")
  vim.cmd("cd " .. vim.fn.fnameescape(dir))
  -- open terminal on the right
  vim.cmd("terminal")
  -- open nvim-tree sidebar on the left
  require("nvim-tree.api").tree.open()
  -- focus the terminal (rightmost window)
  vim.cmd("wincmd l")
end

-------------------------------------------------------------------------------
-- Project picker
-------------------------------------------------------------------------------
function M.project_picker()
  local dirs = {}
  local seen = {}
  local base_dirs = {
    vim.fn.expand("~/projects"),
  }
  for _, base in ipairs(base_dirs) do
    if vim.fn.isdirectory(base) == 1 then
      for _, d in ipairs(vim.fn.globpath(base, "*", false, true)) do
        if vim.fn.isdirectory(d) == 1 and not seen[d] then
          local name = vim.fn.fnamemodify(d, ":t")
          if name:sub(1, 1) ~= "." and name ~= "_archive" then
            seen[d] = true
            table.insert(dirs, d)
          end
        end
      end
    end
  end
  table.sort(dirs, function(a, b)
    return vim.fn.fnamemodify(a, ":t") < vim.fn.fnamemodify(b, ":t")
  end)

  local display = {}
  for _, d in ipairs(dirs) do
    table.insert(display, vim.fn.fnamemodify(d, ":t"))
  end

  vim.ui.select(display, { prompt = "Project: " }, function(choice, idx)
    if choice and idx then
      open_project(dirs[idx])
    end
  end)
end

-------------------------------------------------------------------------------
-- Keybindings
-------------------------------------------------------------------------------
local map = vim.keymap.set
local ESC = [[<C-\><C-n>]]

-- Sidebar toggle: Ctrl+backslash
map("n", [[<C-\>]], toggle_sidebar, { desc = "Toggle sidebar" })

-- Window navigation: Alt+h/j/k/l (works from normal AND terminal mode)
map("n", "<M-h>", "<C-w>h", { desc = "Window left" })
map("n", "<M-l>", "<C-w>l", { desc = "Window right" })
map("n", "<M-j>", "<C-w>j", { desc = "Window down" })
map("n", "<M-k>", "<C-w>k", { desc = "Window up" })
map("t", "<M-h>", ESC .. "<C-w>h", { desc = "Window left (term)" })
map("t", "<M-l>", ESC .. "<C-w>l", { desc = "Window right (term)" })
map("t", "<M-j>", ESC .. "<C-w>j", { desc = "Window down (term)" })
map("t", "<M-k>", ESC .. "<C-w>k", { desc = "Window up (term)" })

-- Tab switching: Ctrl+h / Ctrl+l
-- NOTE: overrides fzf Mru (<C-h>) and Buffers (<C-l>) from .vimrc
map("n", "<C-h>", "gT", { desc = "Previous tab" })
map("n", "<C-l>", "gt", { desc = "Next tab" })
map("t", "<C-h>", ESC .. "gT", { desc = "Previous tab (term)" })
map("t", "<C-l>", ESC .. "gt", { desc = "Next tab (term)" })

-- Project picker: Alt+t
map("n", "<M-t>", M.project_picker, { desc = "Project picker" })
map("t", "<M-t>", function()
  vim.cmd("stopinsert")
  M.project_picker()
end, { desc = "Project picker (term)" })

-- Open Claude terminal: leader+cc / leader+cs
map("n", "<leader>cc", function() open_claude() end, { desc = "Open Claude" })
map("n", "<leader>cs", function() open_claude_skip() end, { desc = "Claude skip-perms" })

-- New terminal: Alt+n
map("n", "<M-n>", ":terminal<CR>", { desc = "New terminal" })
map("t", "<M-n>", ESC .. ":terminal<CR>", { desc = "New terminal (term)" })

-- Escape terminal mode: double-Esc
map("t", "<Esc><Esc>", ESC, { desc = "Exit terminal mode" })

-- Sidebar toggle from terminal mode: Ctrl+\ Ctrl+\
map("t", [[<C-\><C-\>]], function()
  vim.cmd("stopinsert")
  toggle_sidebar()
end, { desc = "Toggle sidebar (term)" })

-------------------------------------------------------------------------------
-- Terminal autocmds
-------------------------------------------------------------------------------
vim.api.nvim_create_autocmd("TermOpen", {
  group = vim.api.nvim_create_augroup("cc_ide_term", { clear = true }),
  callback = function()
    vim.cmd("startinsert")
    vim.opt_local.number = false
    vim.opt_local.relativenumber = false
    vim.opt_local.signcolumn = "no"
  end,
})

-------------------------------------------------------------------------------
-- Session persistence
-------------------------------------------------------------------------------
vim.api.nvim_create_autocmd("VimLeavePre", {
  group = vim.api.nvim_create_augroup("cc_ide_session", { clear = true }),
  callback = function()
    if vim.fn.tabpagenr("$") > 1 then
      vim.cmd("mksession! ~/.config/nvim/cc-ide-session.vim")
    end
  end,
})

return M
