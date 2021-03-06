" Drupal settings for highlighting and indenting:  see
" :help ft-php-syntax and comments in $VIMRUNTIME/indent/php.vim .
let php_htmlInStrings = 1   "Syntax highlight for HTML inside PHP strings
let php_parent_error_open = 1 "Display error for unmatch brackets
let PHP_autoformatcomment = 0

augroup Drupal
  " Remove ALL autocommands for the Drupal group.
  autocmd!

  " Highlight trailing whitespace.
  autocmd BufWinEnter * call s:ToggleWhitespaceMatch('BufWinEnter')
  autocmd BufWinLeave * call s:ToggleWhitespaceMatch('BufWinLeave')
  autocmd InsertEnter * call s:ToggleWhitespaceMatch('InsertEnter')
  autocmd InsertLeave * call s:ToggleWhitespaceMatch('InsertLeave')
augroup END
highlight default link drupalExtraWhitespace Error

" @function s:ToggleWhitespaceMatch(event) {{{
" Adapted from http://vim.wikia.com/wiki/Highlight_unwanted_spaces {{{
function! s:ToggleWhitespaceMatch(event)
  " Bail out unless the filetype is php.drupal, css.drupal, ...
  if &ft !~ '\<drupal\>'
    return
  endif
  if a:event == 'BufWinEnter'
    let w:whitespace_match_number = matchadd('drupalExtraWhitespace', '\s\+$')
    return
  endif
  if !exists('w:whitespace_match_number')
    return
  endif
  call matchdelete(w:whitespace_match_number)
  if a:event == 'BufWinLeave'
    unlet w:whitespace_match_number
  elseif a:event == 'InsertEnter'
    call matchadd('drupalExtraWhitespace', '\s\+\%#\@<!$', 10, w:whitespace_match_number)
  elseif a:event == 'InsertLeave'
    call matchadd('drupalExtraWhitespace', '\s\+$', 10, w:whitespace_match_number)
  endif
endfunction " }}} }}}

" @function s:Drush(command) {{{
" :Drush <subcommand> executes "Drush <subcommand>" and puts the output in a
" new window. Command-line completion uses the output of "drush --sort --pipe"
" unless the current argument starts with "@", in which case it uses the
" output of "drush site-alias".
command! -nargs=* -complete=custom,s:DrushComplete Drush call s:Drush(<q-args>)
function! s:Drush(command) abort " {{{
  " Open a new window. It is OK to quit without saving, and :w does nothing.
  new
  setlocal buftype=nofile bufhidden=hide noswapfile
  " Do not wrap long lines and try to handle ANSI escape sequences.
  setl nowrap
  " For now, just use the --nocolor option.
  " if exists(":AnsiEsc") == 2
    " AnsiEsc
  " endif
  " Execute the command and grab the output. Clean it up.
  " TODO: Does the clean-up work on other OS's?
  let commandline = 'drush --nocolor ' . a:command
  let shortcommand = 'drush ' . a:command
  " Change the status line to list the command instead of '[Scratch]'.
  let &l:statusline = '%<[' . shortcommand . '] %h%m%r%=%-14.(%l,%c%V%) %P'
  let out = system(commandline)
  let out = substitute(out, '\s*\r', '', 'g')
  " Add the command and output to our new scratch window.
  put = '$ ' . shortcommand
  put = repeat('=', 2 + strlen(shortcommand))
  put = out
  " Delete the blank line at the top and stay there.
  1d
endfun " }}} }}}

" @function! s:DrushComplete(ArgLead, CmdLine, CursorPos) {{{

" On Windows, shelling out is slow, so let's cache the results.
let s:drush_completions = {'command': '', 'alias': ''}
function! s:DrushComplete(ArgLead, CmdLine, CursorPos) abort " {{{
  let options = ''
  if a:ArgLead =~ '@\S*$'
    if s:drush_completions.alias == ''
      let s:drush_completions.alias = system('drush site-alias')
    endif
    let options = s:drush_completions.alias
  else
    if s:drush_completions.command == ''
      let commands = system('drush --sort --pipe')
      let s:drush_completions.command = substitute(commands, ' \+', '\n', 'g')
    endif
    let options = s:drush_completions.command
  endif
  return options
endfun
" }}} }}}
