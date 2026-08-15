if type -q /opt/homebrew/bin/brew
    eval (/opt/homebrew/bin/brew shellenv)
end

if type -q starship
    starship init fish | source
end

if type -q mise
    mise activate fish | source
end

if type -q direnv
    direnv hook fish | source
end

abbr --add -- g git
