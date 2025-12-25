" ========================================================================
" ENHANCED OBSIDIAN VIM CONFIGURATION
" Version: 2.0
" Optimized for Obsidian workflow and note-taking efficiency
" ========================================================================

" === Core Settings ===
set clipboard=unnamed          " Sync with system clipboard
unmap <Space>                 " Clear space for leader key

" === Enhanced Movement ===
" Visual line movement (essential for wrapped text)
nmap j gj
nmap k gk
vmap j gj
vmap k gk

" Improved line navigation
nmap H ^                      " Start of line
nmap L $                      " End of line
vmap H ^                      " Visual mode support
vmap L $

" Faster paragraph navigation
"nmap <C-j> }                  " Next paragraph
"nmap <C-k> {                  " Previous paragraph

" Word movement improvements
"nmap W 5w                     " Jump 5 words forward
"nmap B 5b                     " Jump 5 words backward

" === File and Navigation Operations ===
" Quick file operations
exmap newNote obcommand file-explorer:new-file
nmap <Space>nn :newNote

"exmap newFolder obcommand file-explorer:new-folder
"nmap <Space>nf :newFolder

"exmap deleteFile obcommand app:delete-file
"nmap <Space>dd :deleteFile

"exmap renameFile obcommand workspace:edit-file-title
"nmap <Space>rn :renameFile

" Enhanced search and navigation
exmap searchFile obcommand global-search:open
nmap <Space>sf :searchFile

exmap searchInFile obcommand editor:open-search
nmap <Space>si :searchInFile

"exmap commandPalette obcommand command-palette:open
"nmap <Space>cp :commandPalette

exmap quickSwitcher obcommand switcher:open
nmap <Space>ff :quickSwitcher

" File explorer controls
exmap revealFile obcommand file-explorer:reveal-active-file
nmap <Space>gf :revealFile

exmap toggleLeftSideBar obcommand app:toggle-left-sidebar
nmap <C-n> :toggleLeftSideBar

exmap toggleRightSideBar obcommand app:toggle-right-sidebar
nmap <C-m> :toggleRightSideBar

" === View and Layout Management ===
" Tab/pane management
exmap closePane obcommand workspace:close
nmap <Space>q :closePane

exmap splitVertical obcommand workspace:split-vertical
nmap <Space>sv :splitVertical

exmap splitHorizontal obcommand workspace:split-horizontal
nmap <Space>sh :splitHorizontal

" Focus navigation between panes
exmap focusLeft obcommand editor:focus-left
nmap <C-h> :focusLeft

exmap focusRight obcommand editor:focus-right
nmap <C-l> :focusRight

exmap focusTop obcommand editor:focus-top
nmap <C-k> :focusTop

exmap focusBottom obcommand editor:focus-bottom
nmap <C-j> :focusBottom

" === Mode Switching ===
exmap togglePreview obcommand markdown:toggle-preview
nmap <Space>tp :togglePreview

exmap toggleReadingView obcommand markdown:toggle-reading-view
nmap <Space>tr :toggleReadingView

exmap toggleSourceMode obcommand editor:toggle-source
nmap <Space>ts :toggleSourceMode

" === Link and Reference Management ===
exmap followLink obcommand editor:follow-link
nmap gf :followLink

exmap goBack obcommand app:go-back
nmap <C-o> :goBack

exmap goForward obcommand app:go-forward
nmap <C-i> :goForward

" Insert links
exmap insertLink obcommand editor:insert-link
nmap <Space>il :insertLink

" === Text Formatting ===
exmap toggleBold obcommand editor:toggle-bold
nmap <Space>b :toggleBold

exmap toggleItalic obcommand editor:toggle-italics
nmap <Space>i :toggleItalic

exmap toggleHighlight obcommand editor:toggle-highlight
nmap <Space>h :toggleHighlight

exmap toggleCode obcommand editor:toggle-code
nmap <Space>c :toggleCode

exmap toggleStrikethrough obcommand editor:toggle-strikethrough
nmap <Space>s :toggleStrikethrough

" === List and Structure Management ===
exmap toggleCheckbox obcommand editor:toggle-checklist-status
nmap <Space>x :toggleCheckbox

exmap insertTemplate obcommand templater-obsidian:insert-templater
nmap <Space>tt :insertTemplate

" Fold/unfold sections
exmap foldAll obcommand editor:fold-all
nmap <Space>za :foldAll

exmap unfoldAll obcommand editor:unfold-all
nmap <Space>zA :unfoldAll

" === Quick Actions ===
" Paste as plain text
exmap pasteAsPlainText obcommand editor:paste-plain
nmap <Space>pp :pasteAsPlainText

" === Graph and Outline ===
exmap openGraph obcommand graph:open
nmap <Space>og :openGraph

exmap openLocalGraph obcommand graph:open-local
nmap <Space>lg :openLocalGraph

exmap openOutline obcommand outline:open
nmap <Space>oo :openOutline

" === Utility Mappings ===
" Clear search highlighting
nmap <F9> :nohl<CR>

" Quick save (if auto-save is disabled)
exmap saveFile obcommand editor:save-file
nmap <Space>w :saveFile

" Zoom in/out
exmap zoomIn obcommand app:zoom-in
nmap <Space>+ :zoomIn

exmap zoomOut obcommand app:zoom-out
nmap <Space>- :zoomOut

exmap resetZoom obcommand app:reset-zoom
nmap <Space>0 :resetZoom

" === Advanced Text Objects ===
" Move between headers
exmap nextHeading obcommand obsidian-editor-shortcuts:goToNextHeading
nmap ]] :nextHeading

exmap prevHeading obcommand obsidian-editor-shortcuts:goToPrevHeading
nmap [[ :prevHeading

" === Custom Workflows ===
" Quick note capture
exmap captureNote obcommand quickadd:choice
nmap <Space>qn :captureNote

" Open settings
exmap openSettings obcommand app:open-settings
nmap <Space>os :openSettings

" Reload app (useful for plugin development/debugging)
exmap reloadApp obcommand app:reload
nmap <Space>rl :reloadApp

" ========================================================================
" KEY BINDINGS SUMMARY:
" 
" === Movement ===
" j/k           - Visual line movement
" H/L           - Start/end of line  
" Ctrl+j/k      - Paragraph navigation
" W/B           - 5-word jumps
" ]]/[[         - Next/previous heading
" gf            - Follow link under cursor
" Ctrl+o/i      - Back/forward navigation
"
" === File Operations ===
" Space+nn      - New note
" Space+nf      - New folder
" Space+dd      - Delete file
" Space+rn      - Rename file
" Space+q       - Close pane
" Space+w       - Save file
"
" === Search and Navigation ===
" Space+sf      - Global search
" Space+si      - Search in file
" Space+ff      - Quick switcher
" Space+cp      - Command palette
" Space+gf      - Reveal in explorer
"
" === Layout Management ===
" Space+sv/sh   - Split vertical/horizontal
" Ctrl+h/j/k/l  - Focus pane direction
" Ctrl+n/m      - Toggle left/right sidebar
"
" === View Modes ===
" Space+tp      - Toggle preview
" Space+tr      - Toggle reading view
" Space+ts      - Toggle source mode
"
" === Formatting ===
" Space+b/i/h   - Bold/italic/highlight
" Space+c/s     - Code/strikethrough
" Space+x       - Toggle checkbox
" Space+il      - Insert link
"
" === Templates and Daily Notes ===
" Space+tt      - Insert template
" Space+dn      - Open daily note
" Space+td/yd/tm - Today/yesterday/tomorrow
"
" === Graph and Structure ===
" Space+og/lg   - Open graph/local graph
" Space+oo      - Open outline
" Space+za/zA   - Fold/unfold all
"
" === Utilities ===
" F9            - Clear search highlight
" Space+pp      - Paste as plain text
" Space+id/it   - Insert date/time
" Space++/-/0   - Zoom in/out/reset
" Space+os      - Open settings
" Space+rl      - Reload app
" ========================================================================
