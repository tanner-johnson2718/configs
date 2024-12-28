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
}

# https://brbsix.github.io/2015/11/29/accessing-tab-completion-programmatically-in-bash/
#
# This is almost entirely stolen from ^^ 
# {pkgs,lib, ...}:
# let
#   bin = "mat-gen";
#   usage = ''
#     echo "mat-gen <cmd> <arg1> ... <argN>"
#     echo "  A wrapper that takes in a command and its positional args. Use the cmds bash"
#     echo "  completions to populate a list of possible inputs for each positional"
#     echo "  arguement. The 'subargs' passed to the command can either be one of those"
#     echo "  specified in the cmds bash completions or a '-'. If its a '-' then that arg"
#     echo "  specified will be looped over. You can loop over atleast one but no more than"
#     echo "  two args. A matrix is produced that shows the return code of the cmd ran over"
#     echo "  all possible '-' positional arguements." 
#   '';

#   # Applied for general info and for errorChecks
#   tag = "${applyColor colors.blue "[ mat-gen ]"}";

# in
# {
#   environment.systemPackages = [
#     (pkgs.writeScriptBin bin ''
#         #!${lib.makeBinPath [pkgs.bashInteractive]}/bash
#         source /etc/bashrc

#         echo -e "${tag} Checking args and Sourcing Completions"
        
#         # Check that we have a command and atleast a single postional arg
#         ${errorCheck "[ $# -lt 2 ]" "Not enough args" "1"}
#         cmd=$1
#         ${errorCheck "! which $cmd > /dev/null" "Could not find $cmd on path" "1"}

#         # Loop thorugh the args and make sure there are atleast one "-" but no more than two
#         ret=0
#         for var in "$@"; do
#           if [ "$var" = "-" ]; then
#             ret=$((ret+1))
#           fi
#         done

#         ${errorCheck "[ $ret = 0 ]" "Must have one '-' arg" "1"}
#         ${errorCheck "[ $ret -gt 2 ]" "Can have atmost '-' arg" "1"}

#         ${loadCompletions "$cmd"}

#         echo -e "${tag} Found Completion for $cmd -> $out"

#         # Now IDK? haha
#         for var in "$@"; do
#           if [ $var = $cmd ]; then
#             continue
#           fi
#         done
#       ''
#     )
#   ];
# }
# numCol = "80";
# statusOffset = "60";
# defSpaces = ''
#     spaces=""
#         for i in {0..${numCol}}; do
#           spaces="$spaces "
#         done
#       '';
#       watchJob = ''
#         pid=$!
#         while ${lib.getExe' pkgs.ps "ps"} -p $pid > /dev/null; do
#           echo -en "\r$spaces\r"
#           line=$(tail -n 1 $log | tr '\n' ' ')
#           line="$phase $line"
#           line=''${line:0:${numCol}}
#           echo -n $line
#           sleep 1
#         done
#         wait $pid
#         if [ $? != 0 ]; then
#           echo -en "\r$spaces\r"
#           printf "%-${statusOffset}s [\033[0;31m FAILED\033[0m  ]\n" "$phase"
#           exit 1
#         else
#           echo -en "\r$spaces\r"
#           printf "%-${statusOffset}s [\033[0;32m SUCCESS\033[0m ]\n" "$phase"
#         fi
#       '';
