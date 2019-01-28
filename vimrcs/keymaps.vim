" basic mappings that you can cp to a server
filetype indent on

set fileformat=unix
set shortmess+=c

set mouse=a  " change cursor per mode
set number  " always show current line number
set nu " absolute line number
set smartcase  " better case-sensitivity when searching
set wrapscan  " begin search from top of file when nothing is found anymore

set expandtab
set tabstop=4
set shiftwidth=4
set fillchars+=vert:\  " remove chars from seperators
set softtabstop=4

set history=1000  " remember more commands and search history

set noswapfile  " swap files give annoying warning

set breakindent  " preserve horizontal whitespace when wrapping
set showbreak=..
set lbr  " wrap words
" set nowrap  " i turn on wrap manually when needed

set scrolloff=3 " keep three lines between the cursor and the edge of the screen

set undodir=~/dotfiles/vimrcs/undodir
set undofile  " save undos
set undolevels=10000  " maximum number of changes that can be undone
set undoreload=100000  " maximum number lines to save for undo on a buffer reload

" set noshowmode  " keep command line clean
" set noshowcmd

set laststatus=2  " always slow statusline

set splitright  " i prefer splitting right and below
set splitbelow

set hlsearch  " highlight search and search while typing
set incsearch
set cpoptions+=x  " stay at seach item when <esc>
" remove highlight after esc
nnoremap <esc> :noh<CR><esc>

set noerrorbells  " remove bells (i think this is default in neovim)
set visualbell
set t_vb=
set viminfo='20,<1000  " allow copying of more than 50 lines to other applications

" easy split movement
nnoremap <C-h> <C-w>h
nnoremap <C-j> <C-w>j
nnoremap <C-k> <C-w>k
nnoremap <C-l> <C-w>l

" tabs:
nnoremap tn :tabnew<Space>
nnoremap tk :tabnext<CR>
nnoremap tj :tabprev<CR>
nnoremap th :tabfirst<CR>
nnoremap tl :tablast<CR>

" map S to replace current word with pasteboard
nnoremap S diw"0P
nnoremap cc "_cc

inoremap <c-d> <Del>
nnoremap J 5j
nnoremap K 5k
vnoremap J 5j
vnoremap K 5k
nnoremap C cc
nnoremap cc ciw
nnoremap dd D
nnoremap D dd
nnoremap dj :d2<cr>
nnoremap dk :-d2<cr>
nnoremap cj 2cc
nnoremap ck -2cc
vnoremap <s-h> ^
nnoremap <s-h> ^
vnoremap <s-l> $
nnoremap <s-l> $
nnoremap yj :execute "normal! Vjy"<cr>
nnoremap yk :execute "normal! Vkyj"<cr>
" insert semicolon at end of line:
" https://vi.stackexchange.com/questions/3721/why-do-i-get-a-missing-quote-error-when-using-the-following-in-a-mapping-using-e
nnoremap <expr> <leader>; getline('.') =~ ';$' ? '' : "mqA;\<esc>`q"
" map paste, yank and delete to named register so the content
" will not be overwritten (I know I should just remember...)
nnoremap x "_x
vnoremap x "_x

set clipboard=unnamedplus
set autoindent

