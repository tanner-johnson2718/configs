# File contains random helper functions that usually fall into 2 categories:
#
# 1) Script Builder Functions to help construct bash functions in NIX
# 2) Nix helpers to help automate things like creating flake outputs from
#    dirs containting modules (and maybe other stuff in the future IDK).
#
# Script builder functions used to help construct bash scripts in NIX. Assumes
# that all args are positional and independant. The only not super obvious
# thing here is the args schema that is used throughout the file:
# 
# args = [
#   ({
#     name = "arg1";
#     description = "what this arg is";
#     opts = "bash-expr-to-gen-args";
#   })
# ]
#
# The above args schema is used to generate a tab completion function for the
# script. Its also used to generate automatic usage and error messages. It 
# assumes that it is a bash expression that generates the args. The output of 
# the bash expr !! MUST !! be space seperated string of the options you want 
# for tab complete.

let
  inherit (builtins) readDir attrNames;

  # [ ({opts = "bash-expr" ;}) ... ] -> [ "bash-expr1" "bash-expr2" ... ]
  exposeOpts = map (e: e.opts);

  # [ ({name="n1";}) ({name="n2";}) ... ] -> [ ["n1" "n2"] ... ]
  exposeName = map (e: e.name);
in 
rec {
  colors = {
    black  = "30";
    red    = "31";
    green  = "32";
    brown  = "33";
    blue   = "34";
    purple = "35";
    cyan   = "36";
    gray   = "37";
  };

  applyColor = color: txt: "\\033[0;${color}m${txt}\\033[0m";

  generateFullUsage = lib: name: args: description: '' 
    ${description}
    ${name} ${lib.strings.concatMapStrings (s: "[" + s + "] ") (exposeName args)}
    ${lib.strings.concatMapStrings (s: s + "\n") (map (v: "${v.name} - ${v.description}") args)}
  '';

  # Give me a proper bash conditional expression. If the expression evaluates
  # to true, tell me what error to return and a specific error message
  errorCheck = cond: msg: code: ''
    if ${cond} ; then
      echo -e "${applyColor colors.red "[ ERROR ] "} ${msg}"
      echo ""
      exit ${code}
    fi
  '';  

  readFileByIFS = {outArr, IFS, file} : ''
    ${outArr}=()
    IFS=${IFS}
    while read line; do
      ${outArr}+=($line)
    done < ${file}
    unset IFS
  '';

  ###############################################################################
  # COMP_WORDS - Array consisting of the individual words in the current command 
  #              line.
  # COMP_CWORD - Index into ${COMP_WORDS} of the word containing the current 
  #              cursor position.
  # COMP_LINE  - The current command line.
  # COMP_POINT - Index of the current cursor pos relative to the beginning of the
  #              current command. If the pos  is at the end of the current command, 
  #              the value of this variable is equal to ${#COMP_LINE}.
  # COMPREPLY  - Array from which Bash reads the possible completions generated 
  #              by a shell function invoked by the programmable completion
  #
  ###############################################################################
  #
  # loadCompletions - For a given command load its completion function and return
  #                   the completion func
  #
  # getCompletions - Given a string, place into the array COMPREPLY the set of 
  #                  tab complete strings one would see
  #
  ###############################################################################
  loadCompletions = cmd: ''
    xdg_dirs=$(echo "$XDG_DATA_DIRS" | tr ':' '\n')
    echo "$XDG_DATA_DIRS" | tr ':' '\n'
    for d in $xdg_dirs; do
      for sub in "$d"/*; do
        sub=$(basename "$sub")
        if [ "$sub" = "bash-completion" ]; then
          for sub2 in "$d"/"$sub"/*; do  
            sub2=$(basename "$sub2")
            echo "$d/$sub/$sub2"
            if [ "$sub2" = "bash_completion" ]; then
              # shellcheck disable=SC1090
              source "$d/$sub/$sub2"
              sourced=1
            fi
          done
        fi
      done
    done
    ${errorCheck "[ -z $sourced ]" "Could not find bash_completion script in XDG_DATA_DIRS" "1"}

    _completion_loader ${cmd}
    out=$(complete -p ${cmd})
    ${errorCheck "[ $? -ne 0 ]" "Could not find completion for ${cmd}" "1"}
    out=$(echo $out | grep -oe '-F [-_0-9A-Za-z]*' | awk '{print $2}')
  '';
  
  build = {
    name,
    description,
    args,
    text,
    pkgs
  }:
  let
  completionPreamble = ''
    function _${name}_complete() {
      case $COMP_CWORD in
  '';
  completionPostamble = ''
      esac
    }
    complete -F _${name}_complete ${name}
  '';
  in
  [
    (pkgs.writeTextFile {
        name = "${name}-completion.bash";
        executable = true;
        destination = "/etc/bash_completion.d/${name}-completion.bash";
      
        derivationArgs = {
          nativeBuildInputs = [ pkgs.installShellFiles ];
          postInstall = ''
            installShellCompletion /etc/bash_completion.d/${name}-completion.bash
          '';
        };

        text = ''
          ${completionPreamble}
            ${pkgs.lib.strings.concatMapStrings 
              (s: s + "\n")
              (pkgs.lib.lists.imap1
                (i: v: (toString i) + '') COMPREPLY=($(compgen -W "''$(${v})" "''${COMP_WORDS[${toString i}]}")) ;;'' ) 
                (exposeOpts args)
              )}
	  ${completionPostamble}  
        '';
      })
      (pkgs.writeShellApplication {
        inherit name;
        text = ''
          trap 'echo "${generateFullUsage pkgs.lib name args description }"' ERR
          ${text}
        '';
      })
    ];

  # For a given dir, import each subdir into a set whose name is the dir name
  # and whose value is the import of that dir.
  dir2Set = lib: dir: 
    (lib.genAttrs
      (attrNames (readDir dir))
      (name: import (lib.path.append dir name)) 
    );

  # For a given dir, import each subdir into a set whose name is the dir name
  # and whose value is the import of that dir + evaluate the import with the
  # given args.
  dir2Set' = lib: args: dir: 
    (lib.genAttrs
      (attrNames (readDir dir))
      (name: (import (lib.path.append dir name) args)) 
    );

  # TODO For now we are assuming all systems are x86. Dont do that.
  # For a given dir, import each subdir and create an attr set where the key
  # is the dir name and the value is a nixos system. Each sub dir is expected
  # to contain a single (top level) module that defines the system.
  dir2ConfigsSet = inputs: dir:
    (inputs.nixpkgs.lib.genAttrs
      (attrNames (readDir dir))
      (name: inputs.nixpkgs.lib.nixosSystem {
	system = "x86_64-linux";
	specialArgs = { inherit inputs; };
	modules = [ 
	  (import (inputs.nixpkgs.lib.path.append dir name)) 
	];
      })
    );

  # TODO What if we need to override or have out of band inputs?
  # For a given dir create an attr set whose name is the dir and whose value
  # is that of calling callPackage on the import of the dir
  dir2PackageSet  = pkgs: dir:
    (pkgs.lib.genAttrs
      (attrNames (readDir dir))
      (name: pkgs.callPackage (import (pkgs.lib.path.append dir name)){})
    );

  # Take as input an attr set (of nixosConfigurations) and produce a package
  # that runs the target "config.system.build.pkgTarget" for that closure
  config2RunPackage = confs: pkgs:
    (pkgs.lib.genAttrs
      (attrNames confs)
      (name: confs."${name}".config.system.build.runTarget)
    );
}
