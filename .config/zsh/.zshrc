# vim:set fdm=marker:

autoload -U colors && colors

# Disable c-s and c-q for freezing and unfreezing terminal
unsetopt flow_control
stty -ixon

# Automatically remove duplicates from these arrays.
typeset -U path cdpath fpath manpath

setopt autocd                 # Change directory without cd command.
setopt interactive_comments   # Allow comments in interactive shells.
setopt no_beep                # Don't beep.
setopt no_bg_nice             # Don't run all background jobs at a lower priority.
setopt no_hup                 # Don't kill jobs on shell exit.
setopt no_auto_remove_slash   # Don't guess when slashes should be removed (too magic).
setopt nomatch                # Show error if globbing fails.
setopt extended_glob          # More globbing characters.
setopt pushd_ignore_dups      # Do not store duplicates in the stack.
setopt pushd_silent           # Do not print the directory stack after pushd or popd.

# Prompt
setopt prompt_subst           # Expand parameters commands, and arithmetic in PROMPT.

autoload -Uz vcs_info
precmd() { vcs_info }
zstyle ':vcs_info:*' enable git
zstyle ':vcs_info:git:*' formats ' %F{242}%b%f'

PS1='${SSH_CONNECTION+"%F{242}%n@%m "}%F{blue}%~${vcs_info_msg_0_}
%(?.%F{5}.%F{1})❯%f '

# History
setopt no_bang_hist           # Do not treat the '!' character specially during expansion.
setopt inc_append_history     # Append immediately rather than only at exit.
setopt extended_history       # Store some metadata as well.
setopt hist_ignore_dups       # Do not record an event that was just recorded again.
setopt hist_ignore_all_dups   # Delete an old recorded event if a new event is a duplicate.
setopt hist_find_no_dups      # Do not display a previously found event.
setopt hist_ignore_space      # Do not record a command starting with a space.
setopt hist_save_no_dups      # Do not write a duplicate event to the history file.

HISTFILE=~/.cache/zsh/history # Store history here.
HISTSIZE=10000                # Max. entries to keep in memory.
SAVEHIST=10000                # Max. entries to save to file.
HISTORY_IGNORE='([bf]g *|[bf]g|disown|cd ..|cd -)' # Don't add these to the history file.

# Completion
setopt complete_in_word       # Complete from within a word.
setopt always_to_end          # Move cursor to end of word when completing from middle.
setopt no_list_ambiguous      # Show options on single tab press.
setopt list_packed            # Use different column widths if we can; makes it more compact.
fpath=(/usr/share/zsh/site-functions $fpath)

# Load and init.
autoload -U compinit && compinit -d "${XDG_CACHE_HOME:-$HOME/.cache}/zsh/zcompdump"

# Load interactive menu.
zmodload -i zsh/complist

# Use menu for selecting.
zstyle ':completion:*' menu select

# Enable cache (not used by many completions).
zstyle ':completion::complete:*' use-cache on
zstyle ':completion::complete:*' cache-path "${XDG_CACHE_HOME:-$HOME/.cache}/zsh/zcompcache"

zstyle ':completion:*:warnings'  format 'No completions'            # Warn when there are no completions.
zstyle ':completion:*:default'   list-colors ${(s.:.)LS_COLORS}     # Show ls-like colors in file completion.
zstyle ':completion:*'           list-separator '│'                 # Separator before help; looks nicer than --.
zstyle ':completion:*'           squeeze-slashes true               # "path//<Tab>" is "path/" rather than "path/*"
zstyle ':completion:*'           matcher-list 'm:{a-zA-Z}={A-Za-z}' # Make completion case-insensitive.
zstyle ':completion:*:functions' ignored-patterns '_*'              # Ignore in completion.

# Bindings
bindkey -e # Use the default "emacs" bindings.

autoload -U up-line-or-beginning-search   && zle -N up-line-or-beginning-search
autoload -U down-line-or-beginning-search && zle -N down-line-or-beginning-search
autoload -U edit-command-line             && zle -N edit-command-line
autoload -U copy-earlier-word             && zle -N copy-earlier-word

# Insert 'sudo ' at the beginning of the line.
prepend-sudo() {
  [[ -z $BUFFER ]] && return
  local cmd="sudo "
  if [[ ${BUFFER} == ${cmd}* ]]; then
    CURSOR=$(( CURSOR-${#cmd} ))
    BUFFER="${BUFFER#$cmd}"
  else
    BUFFER="${cmd}${BUFFER}"
    CURSOR=$(( CURSOR+${#cmd} ))
  fi
  zle reset-prompt
}
zle -N prepend-sudo

bindkey '^[[A' up-line-or-beginning-search   # Arrow up.
bindkey '^[OA' up-line-or-beginning-search
bindkey '^P'   up-line-or-beginning-search
bindkey '^[[B' down-line-or-beginning-search # Arrow down.
bindkey '^[OB' down-line-or-beginning-search
bindkey '^N'   down-line-or-beginning-search
bindkey '^H'   backward-delete-char          # Backspace.
bindkey '^?'   backward-delete-char
bindkey '^[[Z' reverse-menu-complete         # Shift+Tab; so it works in menu completion to go back.
bindkey '^T'   edit-command-line             # Edit in Vim.
bindkey '^Q'   push-line-or-edit             # Use a more flexible push-line.
bindkey '^X^S' prepend-sudo                  # Insert 'sudo ' at the beginning of the line.
bindkey '\em'  copy-earlier-word             # Insert the last typed word again.

# Search shell history incrementally, but treat the search string typed as a pattern.
bindkey '^R' history-incremental-pattern-search-backward
bindkey '^S' history-incremental-pattern-search-forward

# Use vim keys in menu completion.
bindkey -M menuselect 'h' vi-backward-char
bindkey -M menuselect 'j' vi-down-line-or-history
bindkey -M menuselect 'k' vi-up-line-or-history
bindkey -M menuselect 'l' vi-forward-char

# Insert current completion, but stay in the menu for further completions.
bindkey -M menuselect 'i' accept-and-menu-complete

# Press enter in incremental search for selecting an entry without executing it.
bindkey -M isearch '^M' accept-search

# Go to parent dir.
bindkey -s '\eu' '^Ubuiltin cd ..\n'

# Load aliases if existent.
[ -f "${XDG_CONFIG_HOME:-$HOME/.config}/shell/aliasrc" ] && source "${XDG_CONFIG_HOME:-$HOME/.config}/shell/aliasrc"

# Load our own functions.
fpath=("$ZDOTDIR/zsh/functions" $fpath)
typeset -aU ffiles
ffiles=("$fpath[1]"/[^_]*(.N:t))
(( ${#ffiles} > 0 )) && autoload "${ffiles[@]}"
unset ffiles

# Load asdf version manager.
[ -f "$ASDF_DIR/asdf.sh" ] && source "$ASDF_DIR/asdf.sh"

# Load local config if existent.
[ -f "$ZDOTDIR/.zshrc.local" ] && source "$ZDOTDIR/.zshrc.local"

# Load syntax highlighting; should be last.
source /usr/share/zsh/plugins/fast-syntax-highlighting/fast-syntax-highlighting.plugin.zsh 2>/dev/null
