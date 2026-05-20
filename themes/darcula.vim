colorscheme darcula

call darcula#Hi('rustLifetime', darcula#palette.macroName, darcula#palette.bg, 'italic')
call darcula#Hi('Comment', [ '#7cc22d', 0 ], darcula#palette.null, 'italic')

highlight @comment guifg=#7cc22d cterm=italic
highlight @comment.documentation guifg=#7cc22d
highlight @constant guifg=#c77dbb
highlight @function.call guifg=#39a6d0
highlight @function.macro guifg=#35adff
highlight @function guifg=#56a8f5
highlight @variable.member guifg=#de66dc
highlight @variable.type guifg=#de66dc
highlight @type guifg=#de66dc
highlight @variable guifg=#d9b76e
highlight @string guifg=#5ba130
highlight @module guifg=#c4c1db
highlight @label guifg=#20999d

highlight DiagnosticVirtualTextError ctermfg=8
highlight DiagnosticVirtualTextInfo ctermfg=8
highlight DiagnosticVirtualTextWarn ctermfg=8
highlight DiagnosticVirtualTextHint ctermfg=8

highlight CursorLine term=NONE cterm=NONE ctermbg=236 ctermfg=NONE
hi CursorLineNr cterm=NONE ctermbg=236 ctermfg=7

