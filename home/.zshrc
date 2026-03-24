# =========================
# KEYBINDINGS (FIX TERMINAL)
# =========================

bindkey "^[[1;5D" backward-word
bindkey "^[[1;5C" forward-word
bindkey "^[[1;5A" up-line-or-history
bindkey "^[[1;5B" down-line-or-history

bindkey "^[[D" backward-char
bindkey "^[[C" forward-char

# =========================
# OPCIONES
# =========================

setopt autocd
setopt interactivecomments
setopt hist_ignore_all_dups
setopt hist_reduce_blanks
setopt share_history

# =========================
# HISTORIAL
# =========================

HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000

# =========================
# COLORES
# =========================

autoload -U colors && colors

FG_CYAN="%F{109}"
FG_RED="%F{167}"
RESET="%f"

# =========================
# GLYPH SYSTEM
# =========================

GLYPH_NORMAL="◈"
GLYPH_GIT="󰊢"
GLYPH_ROOT=""
GLYPH_ERROR="✖"

_get_glyph() {
    local exit_code=$?

    # ROOT
    if [[ $EUID -eq 0 ]]; then
        echo "$GLYPH_ROOT"
        return
    fi

    # ERROR
    if [[ $exit_code -ne 0 ]]; then
        echo "$GLYPH_ERROR"
        return
    fi

    # GIT
    if command git rev-parse --is-inside-work-tree &>/dev/null; then
        echo "$GLYPH_GIT"
        return
    fi

    # NORMAL
    echo "$GLYPH_NORMAL"
}

# =========================
# PROMPT
# =========================

precmd() {
    local exit_code=$?
    local glyph=$(_get_glyph)

    # línea superior (path)
    print -P "%F{109}%~%f"

    # prompt principal
    if [[ $exit_code -ne 0 ]]; then
        PROMPT="%K{#1f2428}%F{167}z0m4 $glyph%f %F{167}>%f %k "
    else
        PROMPT="%K{#1f2428}%F{109}z0m4 $glyph%f %F{109}>%f %k "
    fi
}

# =========================
# ALIASES
# =========================

alias ..="cd .."
alias ...="cd ../.."
alias ....="cd ../../.."

alias ls="lsd --group-directories-first --icon never"
alias ll="lsd -l --icon never"
alias la="lsd -a --icon never"
alias lt="lsd --tree --icon never"

alias cat="batcat --paging=never"
alias bat="batcat --paging=never"

alias cls="clear"
alias h="history"

alias psa="ps aux | grep -v grep | grep -i"
alias ports="ss -tuln"

alias gs="git status"
alias ga="git add"
alias gc="git commit -m"
alias gp="git push"
alias gl="git log --oneline --graph --decorate"

alias zshconfig="nano ~/.zshrc"
alias reload="source ~/.zshrc"

# =========================
# COMPLETION
# =========================

autoload -Uz compinit
compinit

# =========================
# PATH
# =========================

export PATH="$HOME/.local/bin:$PATH"

# =========================
# FZF
# =========================

export FZF_DEFAULT_OPTS="\
--color=bg:#1e1e1e,fg:#c5c8c6,hl:#6f8f8f \
--color=bg+:#262626,fg+:#c5c8c6,hl+:#6f8f8f \
--border=rounded"

[ -f /usr/share/doc/fzf/examples/key-bindings.zsh ] && source /usr/share/doc/fzf/examples/key-bindings.zsh
[ -f /usr/share/doc/fzf/examples/completion.zsh ] && source /usr/share/doc/fzf/examples/completion.zsh

# =========================
# AUTOSUGGESTIONS
# =========================

source /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=#5c6370"

# =========================
# ZOXIDE
# =========================

export _ZO_FZF_OPTS="\
--color=bg:#1e1e1e,fg:#c5c8c6,hl:#6f8f8f \
--color=bg+:#262626,fg+:#c5c8c6,hl+:#6f8f8f \
--border=rounded"

eval "$(zoxide init zsh)"
