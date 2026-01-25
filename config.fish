if type -q /opt/homebrew/bin/brew
    eval (/opt/homebrew/bin/brew shellenv)
end

if type -q starship
    starship init fish | source
end

# Activate mise if installed locally
# (Homebrew installations are automatically activated via MISE_FISH_AUTO_ACTIVATE)
if type -q ~/.local/bin/mise
    ~/.local/bin/mise activate fish | source
end

abbr --add -- g git
