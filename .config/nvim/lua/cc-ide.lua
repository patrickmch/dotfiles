-- cc-ide.lua — Nvim CC IDE
-- nvim-tree sidebar + Claude Code integration (claudecode.nvim)
-- Floating file preview from the tree. v/s for splits. t for new project tabs.

local M = {}

-------------------------------------------------------------------------------
-- Claude Code integration (coder/claudecode.nvim)
-------------------------------------------------------------------------------
local claude_ok, claudecode = pcall(require, "claudecode")
if claude_ok then
  claudecode.setup({
    terminal = {
      split_side = "right",
      split_width_percentage = 0.5,
    },
  })

  -- Keybindings for Claude Code
  vim.keymap.set("n", "<leader>ac", "<cmd>ClaudeCode<CR>", { desc = "Toggle Claude" })
  vim.keymap.set("v", "<leader>as", "<cmd>ClaudeCodeSend<CR>", { desc = "Send to Claude" })
  vim.keymap.set("n", "<leader>as", "<cmd>ClaudeCodeTreeAdd<CR>", { desc = "Add file to Claude" })
  vim.keymap.set("n", "<leader>ao", "<cmd>ClaudeCodeOpen<CR>", { desc = "Open Claude panel" })
end

-------------------------------------------------------------------------------
-- Theme + Visual Polish
-------------------------------------------------------------------------------
local ok, catppuccin = pcall(require, "catppuccin")
if ok then
  catppuccin.setup({
    flavour = "mocha",
    integrations = {
      nvimtree = true,
    },
    custom_highlights = function(colors)
      return {
        -- Softer window separators (like Zellij pane borders)
        WinSeparator = { fg = colors.surface0, bg = colors.base },
        -- Cleaner tab line
        TabLine = { fg = colors.subtext0, bg = colors.mantle },
        TabLineSel = { fg = colors.text, bg = colors.surface0, bold = true },
        TabLineFill = { bg = colors.mantle },
        -- Floating window border (for file preview)
        FloatBorder = { fg = colors.surface1, bg = colors.base },
        NormalFloat = { bg = colors.base },
      }
    end,
  })
  vim.cmd.colorscheme("catppuccin")
  vim.g["lightline"] = vim.tbl_deep_extend("force", vim.g["lightline"] or {}, {
    colorscheme = "catppuccin",
  })
end

-- Window chrome
vim.opt.fillchars = {
  vert = "│",      -- thin vertical separator
  horiz = "─",     -- thin horizontal separator
  horizup = "┴",
  horizdown = "┬",
  vertleft = "┤",
  vertright = "├",
  verthoriz = "┼",
}
vim.opt.laststatus = 2          -- always show status line
vim.opt.showtabline = 2         -- always show tab line
vim.opt.termguicolors = true    -- 24-bit color
vim.opt.title = true            -- set terminal title

-- Custom tab line with icons (like a modern IDE tab bar)
function _G.cc_tabline()
  local s = ""
  local total = vim.fn.tabpagenr("$")
  for i = 1, total do
    local winnr = vim.fn.tabpagewinnr(i)
    local name = vim.fn.fnamemodify(vim.fn.getcwd(winnr, i), ":t")
    if name == "" then name = "~" end
    -- Count terminals in this tab
    local bufs = vim.fn.tabpagebuflist(i)
    local term_count = 0
    for _, b in ipairs(bufs) do
      if vim.fn.getbufvar(b, "&buftype") == "terminal" then
        term_count = term_count + 1
      end
    end
    local icon = " "  -- folder icon
    if term_count > 0 then
      icon = " "  -- terminal icon when active
    end
    if i == vim.fn.tabpagenr() then
      s = s .. "%#TabLineSel# " .. icon .. name .. " %#TabLineFill#│"
    else
      s = s .. "%#TabLine# " .. icon .. name .. " %#TabLineFill#│"
    end
  end
  -- Right side: session info
  s = s .. "%#TabLineFill#%="
  s = s .. "%#TabLine#  " .. total .. " %#TabLineFill#"
  return s
end
vim.opt.tabline = "%!v:lua.cc_tabline()"

-------------------------------------------------------------------------------
-- Helpers
-------------------------------------------------------------------------------
local function toggle_sidebar()
  local was_terminal = vim.bo.buftype == "terminal"
  require("nvim-tree.api").tree.toggle({ find_file = false, focus = false })
  -- If we were in a terminal, go back to insert mode
  if was_terminal then
    vim.defer_fn(function()
      if vim.bo.buftype == "terminal" then
        vim.cmd("startinsert")
      end
    end, 50)
  end
end

local open_project -- forward declaration

-------------------------------------------------------------------------------
-- nvim-tree on_attach
-------------------------------------------------------------------------------
local function cc_nvimtree_on_attach(bufnr)
  local api = require("nvim-tree.api")
  api.config.mappings.default_on_attach(bufnr)

  -- Enter on file: floating preview with title (q/Esc to close)
  vim.keymap.set("n", "<CR>", function()
    local node = api.tree.get_node_under_cursor()
    if not node or node.type == "directory" then
      api.node.open.edit()
      return
    end
    local buf = vim.fn.bufadd(node.absolute_path)
    vim.fn.bufload(buf)
    local w = math.floor(vim.o.columns * 0.75)
    local h = math.floor(vim.o.lines * 0.8)
    local filename = vim.fn.fnamemodify(node.absolute_path, ":t")
    vim.api.nvim_open_win(buf, true, {
      relative = "editor",
      width = w, height = h,
      col = math.floor((vim.o.columns - w) / 2),
      row = math.floor((vim.o.lines - h) / 2),
      style = "minimal",
      border = "rounded",
      title = " " .. filename .. " ",
      title_pos = "center",
    })
    -- Enable line numbers in preview
    vim.opt_local.number = true
    vim.keymap.set("n", "q", "<cmd>close<CR>", { buffer = buf })
    vim.keymap.set("n", "<Esc>", "<cmd>close<CR>", { buffer = buf })
  end, { buffer = bufnr, desc = "Float preview" })

  -- Helper: open file in float
  local function float_file(path)
    local buf = vim.fn.bufadd(path)
    vim.fn.bufload(buf)
    local w = math.floor(vim.o.columns * 0.75)
    local h = math.floor(vim.o.lines * 0.8)
    vim.api.nvim_open_win(buf, true, {
      relative = "editor", width = w, height = h,
      col = math.floor((vim.o.columns - w) / 2),
      row = math.floor((vim.o.lines - h) / 2),
      style = "minimal", border = "rounded",
    })
    vim.keymap.set("n", "q", "<cmd>close<CR>", { buffer = buf })
    vim.keymap.set("n", "<Esc>", "<cmd>close<CR>", { buffer = buf })
  end

  -- v on dir: vertical split with terminal in that dir
  -- v on file: floating preview
  vim.keymap.set("n", "v", function()
    local node = api.tree.get_node_under_cursor()
    if not node then return end
    if node.type == "directory" then
      vim.cmd("wincmd l | vsplit | terminal")
      vim.defer_fn(function()
        local chan = vim.b.terminal_job_id
        if chan then vim.fn.chansend(chan, "cd " .. vim.fn.shellescape(node.absolute_path) .. " && clear\n") end
      end, 100)
    else
      float_file(node.absolute_path)
    end
  end, { buffer = bufnr, desc = "Vertical split / float file" })

  -- s on dir: horizontal split with terminal in that dir
  -- s on file: floating preview
  vim.keymap.set("n", "s", function()
    local node = api.tree.get_node_under_cursor()
    if not node then return end
    if node.type == "directory" then
      vim.cmd("wincmd l | split | terminal")
      vim.defer_fn(function()
        local chan = vim.b.terminal_job_id
        if chan then vim.fn.chansend(chan, "cd " .. vim.fn.shellescape(node.absolute_path) .. " && clear\n") end
      end, 100)
    else
      float_file(node.absolute_path)
    end
  end, { buffer = bufnr, desc = "Horizontal split / float file" })

  -- t on dir: open as new tab (tree + terminal)
  vim.keymap.set("n", "t", function()
    local node = api.tree.get_node_under_cursor()
    if node and node.type == "directory" then
      open_project(node.absolute_path)
    end
  end, { buffer = bufnr, desc = "Open dir as tab" })
end

require("nvim-tree").setup({
  on_attach = cc_nvimtree_on_attach,
  renderer = {
    indent_markers = { enable = true },
    icons = {
      show = { file = true, folder = true, folder_arrow = true, git = true },
      glyphs = {
        folder = {
          arrow_closed = "›",
          arrow_open = "⌄",
        },
      },
    },
    highlight_git = true,
  },
  view = {
    width = 30,
    side = "left",
  },
  filters = {
    dotfiles = false,  -- show hidden files
  },
  git = {
    enable = true,
    ignore = false,
  },
})

-------------------------------------------------------------------------------
-- Open project as new tab: tree + terminal
-------------------------------------------------------------------------------
open_project = function(dir)
  local name = vim.fn.fnamemodify(dir, ":t")
  vim.cmd("tabnew")
  vim.cmd("cd " .. vim.fn.fnameescape(dir))
  vim.cmd("terminal")
  require("nvim-tree.api").tree.open()
  vim.cmd("wincmd l") -- focus terminal
  -- Set Ghostty tab title
  vim.opt.titlestring = name
end

-------------------------------------------------------------------------------
-- Project picker (fzf-powered, fuzzy search)
-------------------------------------------------------------------------------
function M.project_picker()
  -- Collect dirs from all base locations
  local base_dirs = {
    vim.fn.expand("~/projects/clients"),
    vim.fn.expand("~/projects/code"),
    vim.fn.expand("~/projects/mcheyser"),
    vim.fn.expand("~/projects/workspace"),
    vim.fn.expand("~/projects"),
    vim.fn.expand("~"),
  }
  -- Use fd/find to get all directories, formatted nicely
  local cmd = "("
  for i, base in ipairs(base_dirs) do
    if i > 1 then cmd = cmd .. "; " end
    cmd = cmd .. "find " .. vim.fn.shellescape(base) .. " -maxdepth 1 -type d 2>/dev/null"
  end
  cmd = cmd .. ") | sort -u | grep -v '/\\.' | grep -v '_archive'"

  vim.fn["fzf#run"](vim.fn["fzf#wrap"]({
    source = cmd,
    options = {
      "--prompt", "Project> ",
      "--preview", "ls -la {} | head -20",
      "--preview-window", "right:40%",
      "--expect", "esc",
      "--bind", "esc:abort",
    },
    sinklist = function(lines)
      if #lines < 2 or lines[2] == "" then return end
      open_project(lines[2])
    end,
  }))
end

-------------------------------------------------------------------------------
-- Keybindings
-------------------------------------------------------------------------------
local map = vim.keymap.set
local ESC = [[<C-\><C-n>]]

map("n", [[<C-\>]], toggle_sidebar, { desc = "Toggle sidebar" })

map("n", "<M-h>", "<C-w>h", { desc = "Window left" })
map("n", "<M-l>", "<C-w>l", { desc = "Window right" })
map("n", "<M-j>", "<C-w>j", { desc = "Window down" })
map("n", "<M-k>", "<C-w>k", { desc = "Window up" })
map("t", "<M-h>", ESC .. "<C-w>h", { desc = "Window left (term)" })
map("t", "<M-l>", ESC .. "<C-w>l", { desc = "Window right (term)" })
map("t", "<M-j>", ESC .. "<C-w>j", { desc = "Window down (term)" })
map("t", "<M-k>", ESC .. "<C-w>k", { desc = "Window up (term)" })

map("n", "<C-h>", "gT", { desc = "Previous tab" })
map("n", "<C-l>", "gt", { desc = "Next tab" })
map("t", "<C-h>", ESC .. "gT", { desc = "Previous tab (term)" })
map("t", "<C-l>", ESC .. "gt", { desc = "Next tab (term)" })

map("n", "<M-t>", M.project_picker, { desc = "Project picker" })
map("t", "<M-t>", function() vim.cmd("stopinsert"); M.project_picker() end, { desc = "Project picker (term)" })

map("t", "<Esc><Esc>", ESC, { desc = "Exit terminal mode" })
map("t", [[<C-\><C-\>]], function() vim.cmd("stopinsert"); toggle_sidebar() end, { desc = "Toggle sidebar (term)" })

-------------------------------------------------------------------------------
-- Terminal autocmds
-------------------------------------------------------------------------------
local term_group = vim.api.nvim_create_augroup("cc_ide_term", { clear = true })

-- Auto insert mode when opening a terminal
vim.api.nvim_create_autocmd("TermOpen", {
  group = term_group,
  callback = function()
    vim.cmd("startinsert")
    vim.opt_local.number = false
    vim.opt_local.relativenumber = false
    vim.opt_local.signcolumn = "no"
  end,
})

-- Auto insert mode when entering a terminal window
vim.api.nvim_create_autocmd({ "BufEnter", "WinEnter" }, {
  group = term_group,
  callback = function()
    if vim.bo.buftype == "terminal" and vim.fn.mode() ~= "t" then
      vim.defer_fn(function()
        if vim.bo.buftype == "terminal" then
          vim.cmd("startinsert")
        end
      end, 10)
    end
  end,
})

return M
