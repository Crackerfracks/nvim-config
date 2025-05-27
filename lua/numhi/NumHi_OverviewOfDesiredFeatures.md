I'm working with you in several other chats on a neovim highlighting plugin intended to be a neovim version of the WEB HIGHLIGHTS — WEB AND PDF HIGHLIGHTER PLUS NOTES AND ANNOTATIONS extension (minus the "web" and "pdf" parts - just a neovim plugin to work within neovim).

Part of that effort involves giving you a description of the extension so you can understand what it does without me repeating the details or having you read up on a browser plugin (when we aren't building anything for a browser...). With that in mind. here you go:

```Heavily_Edited_Description_of_Web_Highlights_reframed_to_be_about_desired_plugin_features.md
~Web Highlights is a cross-browser extension~ **NumHi is a soon-to-be-available plugin** ~on~ **for** ~Chrome~, ~Edge~, ~Firefox~, ~Brave~, ~Vivaldi~, ~and~ ~Opera~ **Neovim** that enables multi-color highlighting ~on any website or PDF~ (including **local files**), inline note-taking and tagging with a customizable sidebar and reader mode for distraction-free annotation, robust organization features (bookmarks, tags, manual sorting), and flexible export and integration options to Markdown, ~HTML~, ???PDF???(could be a possibility), ~Notion~, Obsidian, and more. It supports **offline usage** with **persistent highlights**, ~cloud sync~ and ~collaboration~, customizable UI elements (sidebars, popups, ~dark/light mode~), keyboard shortcuts, and ~~premium features~~ like ~~unlimited reminders and community highlight discovery~~. However, given that you are working on Neovim Plugin development, I will cross out any mentions of ~browsers~ or PDFs (as well as other features not likely to fit your needs given the use-case) and perform small rewrites where needed to better represent Neovim and your plugin, delimited with "[ "'s and " ]"'s (like lua brackets but square), but you should check again using websearch to see if there recent are any recent developments in the space of Neovim plugins handling PDFs... maybe there's a way to view them within Neovim (and thus highlight/annonate them).

## Highlighting Capabilities
- [x] Highlight text on ~websites~ and ~PDFs~ (including **local files**)
- [x] Persistent highlights that remain visible after ~page reloads~ [ leaving/re-entering a buffer or after restarting Neovim or the host machine ]
- [x] Multiple predefined and custom highlighter colors (~standard~, [ vivid, pastels, earthen tones, metallics, cyberneon ])
- [ ] ~Highlight images and other visual elements~
- [x] ~Advanced Highlighter Mode~ [ Organizing highlights by headings, paragraphs, and more ]

## Annotation & Note-taking
- [x] Inline note-taking connected directly to specific highlights
- [x] ~Rich-text formatting in notes via keyboard shortcuts (e.g., CMD+B for bold, CMD+U for underline)~ [ Markdown-driven formatting, note buffer filetype set to `vim.bo.filetype = "markdown"` ]
- [x] Sidebar overview of all highlights, bookmarks, and notes with drag-and-drop reordering
- [x] "S-Reader" Mode for distraction-free ~article viewing~ [ speed-reading with pause/resume and annotation with customizable fonts, colors, and spacing ]

## Organization & Management
- [x] Tag highlights and bookmarks for easy filtering
- [ ] ~Save pages as bookmarks or use as a read-it-later web clipper tool~
- [x] Manual sorting of highlights in the sidebar via ~drag-and-drop~ [ keybindings ] or ~arrow~ [ arrow-key controls ]
- [ ] Enable/disable highlight~er popup and configure domain blacklists (excluded domains)~s and configure language-specfic colorschemes

## Export & Integration
- [ ] Export highlights and notes to Markdown, ~HTML~, ~PDF~, or ~copy to clipboard~ [ copy to system clipboard via keybinding ]
- [ ] Integrate with ~Notion~, Obsidian, ~Capacities~, ~and~ [ but ] ~other~ [ not really any other ] ~PKM~ note-taking tools
- [ ] ~Import Kindle highlights easily~
- [x] ~Backup and download research data for offline access~ [ Ensure highlights can persist until removed, but only for up to 24 hours ]


## Sync & Collaboration
- [ ] Offline usage ~with no account required for basic~ [ and all highlighting features unlocked out of the box ]
- [ ] ~Sync across devices via free account and web app for cloud storage~
- [ ] ~Discover and share community highlights when syncing is enabled~
- [ ] ~Set email reminders for specific pages to revisit highlights later~
- [ ] ~Receive daily recap emails of your highlights for better retention~

## Interface & Customization
- [x] Configurable keyboard shortcuts for all extension actions
- [x] Customizable sidebar width and alignment (left/right)
- [ ] ~Dark and light display modes for reader and sidebar~
- [ ] ~Popup and context-menu triggers for quick highlighting and note-taking~ [ All interface and keybinding logic handled in extensible config files ]

## ~Advanced & Premium Features~
- [-] ~7-day free trial for Premium/Ultimate features unlocking cloud sync and web app overview~
- [-] ~Unlimited learning sessions and additional reminders on Premium plans~
- [-] ~Community shared highlights exploration and “Discover” feed~

## Privacy & Security
- [x] Highlights, notes, and bookmarks are private by default and stored securely
- [x] No third-party data selling, profiling, or unrelated data usage
- [ ] Local storage option ~with secure sync only when logged into your account~

```
