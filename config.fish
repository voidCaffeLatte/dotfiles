if type -q brew
    eval (brew shellenv)
end

starship init fish | source

abbr --add -- g git

if type -q mise
    mise activate fish | source
end
