" lots taken from
" https://medium.com/@hanspinckaers/setting-up-vim-as-an-ide-for-python-773722142d1d
source ~/dotfiles/vimrcs/keymaps.vim
call plug#begin('~/dotfiles/vimrcs/plugged')
Plug 'nvim-tree/nvim-web-devicons' " optional, for file icons
Plug 'nvim-tree/nvim-tree.lua'
Plug 'airblade/vim-rooter' " vim changes to vc root dir
Plug 'tpope/vim-eunuch' " quick file actions: mkdir, rename, etc
Plug 'tpope/vim-fugitive'
Plug 'junegunn/fzf', { 'dir': '~/.fzf', 'do': './install --all' }
Plug 'junegunn/fzf.vim'
Plug 'drewtempelmeyer/palenight.vim'
Plug 'lvht/mru'
Plug 'tpope/vim-commentary'  "comment-out by gc
Plug 'NLKNguyen/papercolor-theme'
Plug 'mhinz/vim-startify'
Plug 'itchyny/lightline.vim'
Plug 'majutsushi/tagbar'
Plug 'terryma/vim-multiple-cursors'
Plug 'szw/vim-maximizer' " toggle fullscreen
Plug 'machakann/vim-highlightedyank'
Plug 'jiangmiao/auto-pairs'
Plug 'tpope/vim-surround'
" Plug 'tiagofumo/vim-nerdtree-syntax-highlight'  " removed - using nvim-tree now
Plug 'unblevable/quick-scope' "highlights different chars on each line
Plug 'Vimjas/vim-python-pep8-indent'  "better indenting for python
Plug 'airblade/vim-gitgutter'  " show git changes to files in gutter
Plug 'bkad/CamelCaseMotion'
call plug#end()
if exists('g:vscode')
    nnoremap <space> :call VSCodeNotify('whichkey.show')<CR>
endif

" fzf bindings
set rtp+=~/.fzf
nnoremap <c-k> :Rg<cr>
nnoremap <c-j> :Files<cr>
nnoremap <c-h> :Mru<cr>
nnoremap <c-l> :Buffers<cr>

nnoremap <F8> :TagbarToggle<CR>

nnoremap <A-s> :mksession! ~/dotfiles/vimrcs/sessions/recent<cr>
nnoremap <leader>s :so ~/dotfiles/vimrcs/sessions/recent<cr>

" word segment mappings
" call camelcasemotion#CreateMotionMappings('<leader>') <----- MAKE SURE TO NOT CALL THIS FUNCTION
nmap <silent> W <Plug>CamelCaseMotion_w
vmap <silent> W <Plug>CamelCaseMotion_w
nmap <silent> B <Plug>CamelCaseMotion_b
vmap <silent> B <Plug>CamelCaseMotion_b

" path to your python
let g:python3_host_prog = '/usr/local/bin/python3'
let g:python_host_prog = '/usr/local/opt/python@2/bin/python2'

" toggle nvim-tree on ctrl+\
map <C-\> :NvimTreeToggle<CR>

" nvim-tree setup with file system watching
lua << EOF
-- disable netrw for nvim-tree
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

-- enable 24-bit colour
vim.opt.termguicolors = true

require("nvim-tree").setup({
  view = {
    width = 30,
  },
  renderer = {
    group_empty = true,
  },
  filters = {
    dotfiles = false,
  },
  git = {
    enable = true,
  },
  filesystem_watchers = {
    enable = true,
    debounce_delay = 50,
    ignore_dirs = {},
  },
})
EOF
map <C-t> :set nosplitright<CR>:TagbarToggle<CR>:set splitright<CR>

" vim fugitive
nnoremap <leader>gg :G<cr>
nnoremap <leader>gc :Gcommit<cr>
nnoremap <leader>gda :Gdiff<cr>
nnoremap <leader>gb :Gblame<cr>

" themeing
set background=dark
colorscheme palenight
let g:palenight_terminal_italics=1

let g:highlightedyank_highlight_duration = 150

" true colors- makes colors nicer
if (has("nvim"))
  "For Neovim 0.1.3 and 0.1.4 < https://g
  let $NVIM_TUI_ENABLE_TRUE_COLOR=1
endif


"auto indent for brackets
nmap <leader>w :w!<cr>
nmap <leader>q :lcl<cr>:q<cr>
nnoremap <leader>h :nohlsearch<Bar>:echo<CR>

" Return to last edit position when opening files
au BufReadPost * if line("'\"") > 1 && line("'\"") <= line("$") | exe "normal! g'\"" | endif

let g:lightline = {
      \ 'colorscheme': 'palenight',
      \ 'active': {
      \   'left': [ [ 'mode', 'paste' ],
      \             [ 'gitbranch', 'readonly', 'filename', 'modified' ] ],
      \   'right': [ [ 'lineinfo' ],
      \              [ 'percent' ],
      \              [ 'fileencoding', 'filetype' ] ]
      \ },
      \ 'component_function': {
      \   'gitbranch': 'fugitive#head',
      \   'filename': 'LightlineFilename',
      \ },
      \ }

function! LightlineFilename()
  let root = fnamemodify(get(b:, 'git_dir'), ':h')
  let path = expand('%:p')
  if path[:len(root)-1] ==# root
    return path[len(root)+1:]
  endif
  return expand('%')
endfunction


" easy breakpoint python
au FileType python map <silent> <leader>b oimport bpdb; bpdb.set_trace()<esc>

" Options are in .pylintrc!
highlight VertSplit ctermbg=253

" mapping to make movements operate on 1 screen line in wrap mode
function! ScreenMovement(movement)
   if &wrap
      return "g" . a:movement
   else
      return a:movement
   endif
endfunction

onoremap <silent> <expr> j ScreenMovement("j")
onoremap <silent> <expr> k ScreenMovement("k")
onoremap <silent> <expr> 0 ScreenMovement("0")
onoremap <silent> <expr> ^ ScreenMovement("^")
onoremap <silent> <expr> $ ScreenMovement("$")
nnoremap <silent> <expr> j ScreenMovement("j")
nnoremap <silent> <expr> k ScreenMovement("k")
nnoremap <silent> <expr> 0 ScreenMovement("0")
nnoremap <silent> <expr> ^ ScreenMovement("^")
nnoremap <silent> <expr> $ ScreenMovement("$")

" highlight python and self function
autocmd BufEnter * syntax match Type /\v\.[a-zA-Z0-9_]+\ze(\[|\s|$|,|\]|\)|\.|:)/hs=s+1
autocmd BufEnter * syntax match pythonFunction /\v[[:alnum:]_]+\ze(\s?\()/
hi def link pythonFunction Function
autocmd BufEnter * syn match Self "\(\W\|^\)\@<=self\(\.\)\@="
highlight self ctermfg=239


" Remove all trailing whitespace by pressing C-S
nnoremap <C-S> :let _s=@/<Bar>:%s/\s\+$//e<Bar>:let @/=_s<Bar><CR>
autocmd BufReadPost quickfix nnoremap <buffer> <CR> <CR>

" move between defs python:
" NOTE: this break shortcuts with []
nnoremap [[ [m
nnoremap ]] ]m

nnoremap <silent><nowait> [ [[
nnoremap <silent><nowait> ] ]]

function! MakeBracketMaps()
    nnoremap <silent><nowait><buffer> [ :<c-u>exe 'normal '.v:count.'[m'<cr>
    nnoremap <silent><nowait><buffer> ] :<c-u>exe 'normal '.v:count.']m'<cr>
endfunction

augroup bracketmaps
    autocmd!
    autocmd FileType python call MakeBracketMaps()
augroup END

" neovim options
au BufEnter * if &buftype == 'terminal' | :startinsert | endif
nnoremap <C-a> <Esc>
nnoremap <C-x> <Esc>

" vimgutter options
let g:gitgutter_override_sign_column_highlight = 0
let g:gitgutter_map_keys = 0

set autoread
au CursorHold * checktime

" Return to last edit position when opening files
au BufReadPost * if line("'\"") > 1 && line("'\"") <= line("$") | exe "normal! g'\"" | endif

" toggle spell check
map <leader>ss :setlocal spell!<cr>
