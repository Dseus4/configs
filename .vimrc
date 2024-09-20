set nocp hi=1000 ar so=3 wmnu wim=list:longest wig=*.0,*~,*.pyc ru ch=1 hid bs=eol,start,indent ww+=<,> ic scs hls is lz magic sm mat=2 noeb novb t_vb= tm=500 enc=utf8 ffs=unix,dos,mac nobk nowb noswf et sta sw=4 ts=4 ai si lbr tw=500 nu bri


let g:netrw_banner=0
let g:netrw_liststyle=3
let g:ignore_wild_search='.*\(build\|venv\).*'

au!
mapclear
nmapclear
vmapclear
xmapclear
smapclear
omapclear
mapclear!
imapclear
cmapclear
lmapclear
if has('terminal')
    tmapclear
endif

if has("unix") && !has("win32unix")
    " Allow Meta bindings, check for esc keycode with <c-v><esc>
    exec "norm! :let g:esc_code=\"\<c-v>\<esc>\"\<cr>"
    for i in range(33,126)
        let c = nr2char(i)
        if c == '"' || c == '|'
            let c = '\'.c
        elseif c == '>'
            continue
        endif
        exec "set <A-".c.">=\e".c
        exec "set <M-".c.">=\e".c
    endfor
endif

filetype plugin on
filetype indent on

let mapleader=","
let g:mapleader=","

syntax enable

set laststatus=2
set statusline=\ %F%m%r%h\ %w\ \ CWD:\ %r%{getcwd()}%h\ \ \ Line:\ %l\ \ Column:\ %c

fu! s:get_tab_title(i, ...)
    let is_current = a:0
    let s = ""
    let ln = 3
    let ln += len(string(a:i))
    let buflist = tabpagebuflist(a:i)
    let winnr = tabpagewinnr(a:i)
    let s .= '%' . a:i . 'T'
    let s .= (is_current ?  '%1*' : '%2*')
    let s .= ' '
    let wn = tabpagewinnr(a:i,'$')

    let s .= (is_current ? '%#TabNumSel#' : '%#TabNum#')
    let s .= a:i
    " appends .# if there is a split tab
    if tabpagewinnr(a:i,'$') > 1
        let s .= '.'
        let s .= (is_current ? '%#TabWinNumSel#' : '%#TabWinNum#')
        let s .= (tabpagewinnr(a:i,'$') > 1 ? wn : '')
        let ln += 2
    end

    let s .= ' %*'
    let s .= (is_current ? '%#TabLineSel#' : '%#TabLine#')
    let bufnr = buflist[winnr - 1]
    let file = bufname(bufnr)
    let buftype = getbufvar(bufnr, 'buftype')
    if buftype == 'nofile'
        if file =~ '\/.'
            let file = substitute(file, '.*\/\ze.', '', '')
        endif
    else
        let file = fnamemodify(file, ':p:t')
    endif
    if file == ''
        let file = gettabwinvar(a:i, wn,'netrw_prvdir',"[No Name]")
    endif
    let s .= file
    let ln += len(file)
    let s .= (is_current ?  '%m' : '')
    let s .= '%#TabLineFill#'
    return [l:s,l:ln]
endfu

function! MyTabLine()
    let t = tabpagenr()
    let max_columns = &columns - 6
    let t_t = s:get_tab_title(t,1)
    let t_s = t_t[0]
    let t_ln = t_t[1]
    let l = t - 1
    let r = t + 1
    let l_s = ''
    let l_ln = 0
    let r_s = ''
    let r_ln = 0
    while (l > 0 || r <= tabpagenr('$')) && l_ln+r_ln+t_ln < max_columns
        if l <= 0
            let tmp = s:get_tab_title(r)
            let r_s .= tmp[0]
            let r_ln += tmp[1]
            let r += 1
        elseif r >= tabpagenr('$')
            let tmp = s:get_tab_title(l)
            let l_s = tmp[0] . l_s
            let l_ln += tmp[1]
            let l -= 1
        else
            let poss_l = s:get_tab_title(l)
            let poss_r = s:get_tab_title(r)
            if l_ln+poss_l[1] < r_ln+poss_r[1]
                if l_ln +poss_l[1] > max_columns
                    break
                endif
                let l_s = poss_l[0].l_s
                let l_ln += poss_l[1]
                let l -= 1
            else
                if r_ln +poss_r[1] > max_columns
                    break
                endif
                let r_s .= poss_r[0]
                let r_ln += poss_r[1]
                let r += 1
            endif
        endif
    endw
    let s = l_s . t_s . r_s
    if l > 0
        let s = '<<'.s
    else
        let s = '||'.s
    endif

    if r <= tabpagenr('$')
        let s.='>>'
    else
        let s.='||'
    endif
    let s .= '%T%#TabLineFill#%='
    return s
endfu
set stal=2
set tabline=%!MyTabLine()

" === Maps ===
map <leader>ss :setlocal spell!<cr>
inoremap kj <Esc>
vnoremap > >gv
vnoremap < <gv

" Fast Brackets
inoremap <leader>(<cr> (<cr>)<c-o>O
inoremap <leader>{<cr> {<cr>}<c-o>O
inoremap <leader>[<cr> [<cr>]<c-o>O

au InsertLeave * set nopaste

" ======= Garrett T Custom ======
" Auto Save and Load Sessions
fu! SaveSess()
    if g:just_file == 0
        execute 'mksession!' . getcwd() .'/.session.vim'
    endif
    let g:justfile = 0
endfu

fu! RestoreSess()
    if len(argv()) > 0
        let g:just_file = 1
    else
        let g:just_file = 0
        if filereadable(getcwd() . '/.session.vim')
            execute 'so ' . getcwd() . '/.session.vim'
        endif
        execute 'tabe .'
        execute 'tabm0'
    endif
endfu
autocmd VimLeave * call SaveSess()
autocmd VimEnter * call RestoreSess()

" Create term if doesn't exist, jump to existing one if does
fu! JumpTerm(...)
    let g:lasttabnr = tabpagenr()
    if a:0 == 1
        let s:tabnr = a:1
    else
        let s:tabnr = 1
    endif
    let s:foundcount = 0
    for s:l in gettabinfo()
        if TabIsTerm(s:l['tabnr'])
            let s:foundcount += 1
            if s:foundcount == s:tabnr
                execute s:l['tabnr'] . 'tabn'
                execute 'normal! i'
                break
            endif
        endif
        if s:foundcount == s:tabnr
            break
        endif
    endfor
    if s:foundcount != s:tabnr
        execute 'tab ter++kill=hup'
    endif
endfu

fu! JumpBack()
    exe g:lasttabnr . 'tabn'
endfu

fu! JumpOrBack()
    if TabIsTerm(tabpagenr())
        execute JumpBack()
    else
        execute JumpTerm()
    end
endfu

fu! NewTerm()
    execute 'tab ter++kill=hup'
endfu

fu! GoToTab(wildcard)
    let s:found = 0
    for l:l in gettabinfo()
        if TabIsTerm(l['tabnr'])
            execute 'tabn ' . l:l['tabnr']
            let s:found = 1
            break
        endfor
        if s:found
            break
        endif
    endfor
endfu

fu! ListTabData()
    for s:l in gettabinfo()
        for s:w in s:l['windows']
            echo s:l['tabnr']
            echo getwininfo(s:w)
        endfor
    endfor
endfu

" Fast set tab length
fu! SetTabLength(length)
    execute 'set ts=' . a:length
    execute 'set sw=' . a:length
endfu
command! -nargs=1 Tablen call SetTabLength(<args>)

" Fast tab jump
fu! Jump()
    let g:lasttabnr = tabpagenr()
    let num = nr2char(getchar())
    echo num
    execute 'silent! tabn '.num
endfu

fu! JumpSelect()
    let g:lasttabnr = tabpagenr()
    let options = []
    for tab_vals in gettabinfo()
        let option_name = bufname(tabpagebuflist(tab_vals['tabnr'])[tabpagewinnr(tab_vals['tabnr']) - 1])
        if empty(option_name)
            let option_name = gettabwinvar(tab_vals['tabnr'], tab_vals['windows'][0],'netrw_prvdir',"[No Name]")
        endif
        call add(options, tab_vals['tabnr'].":".option_name)
    endfor
    let choice = inputlist(options)
    if choice > 0
        exe 'tabn '.inputlist(options)
    endif
endfu

" Full unmap seq
fu! Unmap(seq)
    execute 'unmap ' . a:seq
    execute 'nunmap ' . a:seq
    execute 'vunmap ' . a:seq
    execute 'sunmap ' . a:seq
    execute 'xunmap ' . a:seq
    execute 'ounmap ' . a:seq
    execute 'uunmap ' . a:seq
    execute 'iunmap ' . a:seq
    execute 'lunmap ' . a:seq
    execute 'cunmap ' . a:seq
    execute 'tunmap ' . a:seq
endfu

fu! TabIsTerm(tabnr)
    return has_key(getwininfo(gettabinfo(a:tabnr)[0]['windows'][0])[0], 'terminal') && getwininfo(gettabinfo(a:tabnr)[0]['windows'][0])[0]['terminal'] == 1
endfu

fu! s:term_paste()
    let char = nr2char(getchar())
    call feedkeys("i\<C-W>\"".char)
endfu

if has('terminal')
"Easier Terminal tab navigation
    nnoremap <leader>z :call JumpOrBack()<CR>
    tnoremap <leader>z <C-W>N:call JumpBack()<CR>
    tnoremap <leader>g <C-W>N:call Jump()<CR>
    tnoremap <leader>G <C-W>N:call JumpSelect()<CR>
    tnoremap <leader><ESC> <C-W>N:q!<CR>
    tnoremap <leader>t <C-W>Ngt
    tnoremap <leader>r <C-W>NgT
    command! -nargs=* JT call JumpTerm(<args>)
    tnoremap <leader>: <C-W>N:
    tnoremap <leader>p <C-W>N:call <SID>term_paste()<CR>
endif

" Easier Tab navigation
nnoremap <leader>t gt
nnoremap <leader>r gT
nnoremap <leader>g :call Jump()<CR>
nnoremap <leader>G :call JumpSelect()<CR>
command! -nargs=1 T call GoToTab('<args>')
nnoremap <leader><left> :vert res -10<CR>
nnoremap <leader><right> :vert res +10<CR>
nnoremap <leader><down> :res -10<CR>
nnoremap <leader><up> :res +10<CR>

"Re-source
command! SRC so ~/.vimrc

" Fast save
inoremap <leader>w <ESC>:w!<CR>
vnoremap <leader>w <ESC>:w!<CR>
nnoremap <leader>w :w!<CR>

" paste result of vim command into file
fu! s:put_result(command)
    exec "norm!\"=".a:command."\<c-m>p"
endfu
command! -nargs=1 Put :call <SID>put_result("\<args>")

" ============ VSCode replacements ===========

" <c-s-j>/<c-s-k> replace alt+shift+down and alt+shift+up
" TODO: add ability to comment selection

" == be able to auto-parenthesis selections
fu! Surround(char)
    let s:charmap = {'"':'"', "'":"'", "(":")", "[":"]", "{":"}"}
    let pos = "getcharpos"("'>")
    exe 's/\%V\(.*\%V.\)/'.a:char.'\1'.s:charmap[a:char].'/'
    call setcharpos('.',pos)
endfu

nnoremap <m-j> ddp

xnoremap '' :call Surround("'")<CR>
xnoremap "" :call Surround('"')<CR>
xnoremap (( :call Surround('(')<CR>
xnoremap [[ :call Surround('[')<CR>
xnoremap {{ :call Surround('{')<CR>


" == <a-s-up> and <a-s-down>
" == <a-up> and <a-down>
nnoremap <A-K> yyP
nnoremap <A-J> yyp
nnoremap <A-k> ddkP
nnoremap <A-j> ddp
fu! s:move_block()
    let bl = getline("'<")
    let el = getline("'>")
    echo bl
    echo el
endfu

fu! s:find_file()
    let search_str = ""
    echom "Enter search and press <cr>: ".search_str
    let ready = 0
    while 1
        while 1
            let char_num = getchar()
            if char_num == 13
                if ready
                    redraw
                    let options = []
                    let c = 1
                    for option in found
                        call add(options, c.':'.option)
                        let c+= 1
                    endfor
                    let choice = inputlist(options)
                    if choice != 0
                        try
                            exe 'tabe '.found[choice-1]
                            return
                        catch
                            echo "Continuing"
                            break
                        endtry
                    endif
                endif
                let ready = 1
                break
            endif
            if char_num == 27
                return
            endif

            if char_num is# "\<BS>" && len(search_str) > 0
                let search_str = search_str[:-2]
            endif
            let char = nr2char(char_num)
            let search_str .= char
            let ready = 0
            redraw
            echom "Enter search and press <cr>: ".search_str
        endwhile

        let searched_dirs = 0
        let found = []
        let q = ['.']
        " use BFS search to find files
        if len(search_str) > 0
            while len(q) > 0 && len(found) < 40 && searched_dirs < 3000
                let next_dir = remove(q, 0)
                if next_dir =~ g:ignore_wild_search
                    continue
                endif
                call extend(q, filter(glob(l:next_dir.'/*',0,1), 'isdirectory(v:val)'))
                let files = filter(glob(l:next_dir.'/*'.search_str.'*',0,1), '!isdirectory(v:val)')
                call extend(found, files[:min([20-len(found), len(files)-1])])
                let searched_dirs += 1
            endwhile
        endif
        redraw
        for path in found
            echo path
        endfor
        echo "keep typing to try another search"
        echo "<CR> to select from choices"
    endwhile
endfu

" == <c-e> replacement
nnoremap <leader>e :call <SID>find_file()<CR>

" ============ Useful binds to start using ============
" <c-o>  jump back
" <c-i>  jump forwards
" ; redo movement

" ============  Functionalities still being tested  ============

fu! s:redoable(seq,action,...)
    if a:0
        execute a:action
    else
        " set up
        let &operatorfunc = matchstr(expand('<sfile>'), '[^. ]*$')
        echo &operatorfunc
        return "g@".a:seq
    endif
endfu

" ============  REMAPPING: REMOVE UNWANTED ============

" NORMAL up = go to last command
nnoremap <up> :<up>

" Better line join
fu! s:join_spaceless()
    exec 'normal! gJ'
    if matchstr(getline('.'), '\%' . col('.') . 'c.') =~ '\s'
        exec 'normal! dw'
    endif
endfu
nnoremap J :call <SID>join_spaceless()<CR>

" Expand ./ to be relative to current file/dir in commands
fu! s:expand_dot_slash()
    if getwinvar(gettabinfo(tabpagenr())[0]['windows'][0], 'netrw_prvfile', '') != ''
        let path = '/'.join(split(getwinvar(gettabinfo(tabpagenr())[0]['windows'][0], 'netrw_prvfile', ''),'/')[:-2],'/').'/'
    else 
        let path = getwinvar(gettabinfo(tabpagenr())[0]['windows'][0], 'netrw_prvdir', getcwd()) . '/'
    endif
    return path
endfu
cnoremap <expr> ./ <SID>expand_dot_slash()
cnoremap ../  ../
