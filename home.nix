{ config, lib, pkgs, claude-code, codex-cli, ... }:

let
  # Host information is detected from the environment so that this
  # configuration works on any machine without editing. This requires
  # evaluating with `--impure`.
  environmentVariable =
    name: fallback:
    let
      value = builtins.getEnv name;
    in
    if value != "" then value else fallback;

  username = environmentVariable "USER" (
    environmentVariable "LOGNAME" (throw "USER or LOGNAME is not set; run home-manager with --impure")
  );
  homeDirectory = environmentVariable "HOME" (
    throw "HOME is not set; run home-manager with --impure"
  );
in
{
  # Home Manager needs a bit of information about you and the paths it should
  # manage.
  home.username = username;
  home.homeDirectory = homeDirectory;

  # This value determines the Home Manager release that your configuration is
  # compatible with. This helps avoid breakage when a new Home Manager release
  # introduces backwards incompatible changes.
  #
  # You should not change this value, even if you update Home Manager. If you do
  # want to update the value, then make sure to first check the Home Manager
  # release notes.
  home.stateVersion = "26.05"; # Please read the comment before changing.

  # The home.packages option allows you to install Nix packages into your
  # environment.
  home.packages = [
    claude-code.packages.${pkgs.stdenv.hostPlatform.system}.claude-code
    codex-cli.packages.${pkgs.stdenv.hostPlatform.system}.default
    pkgs.delta
    pkgs.direnv
    pkgs.fd
    pkgs.fish
    pkgs.fzf
    pkgs.gh
    pkgs.git
    pkgs.jq
    pkgs.mise
    pkgs.neovim
    pkgs.ripgrep
    pkgs.starship
    pkgs.uv

    # # Adds the 'hello' command to your environment. It prints a friendly
    # # "Hello, world!" when run.
    # pkgs.hello

    # # It is sometimes useful to fine-tune packages, for example, by applying
    # # overrides. You can do that directly here, just don't forget the
    # # parentheses. Maybe you want to install Nerd Fonts with a limited number of
    # # fonts?
    # (pkgs.nerdfonts.override { fonts = [ "FantasqueSansMono" ]; })

    # # You can also create simple shell scripts directly inside your
    # # configuration. For example, this adds a command 'my-hello' to your
    # # environment:
    # (pkgs.writeShellScriptBin "my-hello" ''
    #   echo "Hello, ${config.home.username}!"
    # '')
  ];

  # Home Manager is pretty good at managing dotfiles. The primary way to manage
  # plain files is through 'home.file'.
  home.file = {
    ".config/fish/config.fish".source = ./.config/fish/config.fish;
    ".config/git/config".source = ./.config/git/config;
    ".config/git/config.windows-mount".source = ./.config/git/config.windows-mount;
    ".config/mise/config.toml".source = ./.config/mise/config.toml;
    ".config/nvim".source =
      config.lib.file.mkOutOfStoreSymlink "${homeDirectory}/dotfiles/.config/nvim";
    ".config/starship.toml".source = ./.config/starship.toml;
    ".config/wezterm".source = ./.config/wezterm;

    # # Building this configuration will create a copy of 'dotfiles/screenrc' in
    # # the Nix store. Activating the configuration will then make '~/.screenrc' a
    # # symlink to the Nix store copy.
    # ".screenrc".source = dotfiles/screenrc;

    # # You can also set the file content immediately.
    # ".gradle/gradle.properties".text = ''
    #   org.gradle.console=verbose
    #   org.gradle.daemon.idletimeout=3600000
    # '';
  };

  # Home Manager can also manage your environment variables through
  # 'home.sessionVariables'. These will be explicitly sourced when using a
  # shell provided by Home Manager. If you don't want to manage your shell
  # through Home Manager then you have to manually source 'hm-session-vars.sh'
  # located at either
  #
  #  ~/.nix-profile/etc/profile.d/hm-session-vars.sh
  #
  # or
  #
  #  ~/.local/state/nix/profiles/profile/etc/profile.d/hm-session-vars.sh
  #
  # or
  #
  #  /etc/profiles/per-user/<username>/etc/profile.d/hm-session-vars.sh
  #
  home.sessionVariables = {
    # EDITOR = "emacs";
  };

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
}
