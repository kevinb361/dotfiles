" alot of this taken from https://web.archive.org/web/20180106045128/https://dougblack.io/words/a-good-vimrc.html

" colors  
colorscheme molokai                         " stored in $HOME/.vim/colors/ 
syntax enable                               " enable syntax highlighting

" general
set autoread                                " reload on external file changes
set nocompatible                            " entering vim mode, not plain vi
set scrolloff=999                           " center cursor position vertically

" spaces and tabs 
set tabstop=4                               " number of visual spaces per TAB
set softtabstop=4                           " number of spaces in tab when editing
set expandtab                               " tabs are spaces

" ui config  
set number relativenumber                   " show line numbers
set showcmd                                 " show (partial) command in status line
set cursorline                              " highlight current line
filetype indent on                          " load filetype-specific indent files (./vim/indent/python.vim)
set wildmenu                                " visual autocomplete for command menu
set lazyredraw                              " redraw only when we need to
set showmatch                               " highlight matching [{{}}]

" searching 
set incsearch                               " search as characters are entered
set hlsearch                                " highlight matches
set ignorecase smartcase                    " search options
nnoremap <leader><space> :nohlsearch<CR>    " turn off search highlight

" folding 
set foldenable                              " enable folding
set foldlevelstart=10                       " open most folds by default
set foldnestmax=10                          " 10 nested fold max
nnoremap <space> za                         " space open/close folds
set foldmethod=indent                       " fold based on indent level

" leader shortcuts 
let mapleader=","                           " leader is comma

" launch config 
call pathogen#infect()                      " use pathogen
let g:colorizer_auto_color=1                " auto load colorizer plugin

" autogroups 
augroup configgroup
    autocmd!
    autocmd VimEnter * highlight clear SignColumn
    autocmd BufWritePre *.php,*.py,*.js,*.txt,*.hs,*.java,*.md
                \:call <SID>StripTrailingWhitespaces()
    autocmd FileType java setlocal noexpandtab
    autocmd FileType java setlocal list
    autocmd FileType java setlocal listchars=tab:+\ ,eol:-
    autocmd FileType java setlocal formatprg=par\ -w80\ -T4
    autocmd FileType php setlocal expandtab
    autocmd FileType php setlocal list
    autocmd FileType php setlocal listchars=tab:+\ ,eol:-
    autocmd FileType php setlocal formatprg=par\ -w80\ -T4
    autocmd FileType ruby setlocal tabstop=2
    autocmd FileType ruby setlocal shiftwidth=2
    autocmd FileType ruby setlocal softtabstop=2
    autocmd FileType ruby setlocal commentstring=#\ %s
    autocmd FileType python setlocal commentstring=#\ %s
    autocmd BufEnter *.cls setlocal filetype=java
    autocmd BufEnter *.zsh-theme setlocal filetype=zsh
    autocmd BufEnter Makefile setlocal noexpandtab
    autocmd BufEnter *.sh setlocal tabstop=2
    autocmd BufEnter *.sh setlocal shiftwidth=2
    autocmd BufEnter *.sh setlocal softtabstop=2
augroup END

" backups 
set backup
set backupdir=~/.vim-tmp,~/.tmp,~/tmp,/var/tmp,/tmp
set backupskip=/tmp/*,/private/tmp/*
set directory=~/.vim-tmp,~/.tmp,~/tmp,/var/tmp,/tmp
set writebackup

" toggle between number and relativenumber 
function! ToggleNumber()
    if(&relativenumber == 1)
        set norelativenumber
        set number
    else
        set relativenumber
    endif
endfunc

" strips trailing whitespace at the end of files. this
" is called on buffer write in the autogroup above.
function! <SID>StripTrailingWhitespaces()
    " save last search & cursor position
    let _s=@/
    let l = line(".")
    let c = col(".")
    %s/\s\+$//e
    let @/=_s
    call cursor(l, c)
endfunction

" other stuff to check 
set clipboard=unnamedplus	                " copy/paste between vim and other programs
set laststatus=2		                    " always show statusline
set autoindent smarttab
set shiftwidth=4 
set mouse=nicr                              " mouse scrolling
set shortmess=atI                           " don't show the intro message when starting vim
set showmode                                " show the current mode
set ttyfast

" key mappings
cnoreabbrev w!! w !sudo tee > /dev/null %|  " write file with sudo
