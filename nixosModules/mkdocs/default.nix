# Module to wrap mkdocs into a systemd service that will host the website. Also
# provide some auto-generated index documentation that is generated from the 
# directory structure. To facilitate this we will assume our docs repo has the
# following directory structure:
#
# - docs/
#   - Topic_1
#     - Sub_Topic_1_1
#       - <.md>
#       - <.png / .jpg>
#       - .section.md
#   - .section.md 
# - .section.md
#
# The index page that will be generated should infer the headings from the
# directory structure. The .section.md allow you to add a short description
# of the topic and/or the contents of the docs in the directory this file is
# contained in. Then for each markdown file in a given, a table is generated
# linking to that file. Finally, one can also reference .drawio files in any
# of the markdown files contained in the docs dir. It is rendered to an svg
# and a reference such as ![](test.drawio) is replaced with the path to the 
# appropiate location of the rendered image

# TODO Link Checker
# TODO get rid of secdanru lhs drop down menu thing
{inputs, pkgs, lib, config, ... }:
let
  inherit (builtins) readDir readFile toString attrNames foldl' filter;
  inherit (lib.path) append;
  inherit (lib.path.subpath) components;
  inherit (lib.filesystem) pathIsDirectory;
  inherit (lib.strings) hasSuffix splitString replicate concatMapStrings;
  inherit (lib.lists) last sublist removePrefix;
  cfg = config.mkdocs;

  yml = siteName: theme: colorScheme: ''
    site_name: ${siteName}
    theme:
      name: ${theme}
      color_mode: ${colorScheme}
    extra_javascript:
      - https://cdnjs.cloudflare.com/ajax/libs/mathjax/2.7.0/MathJax.js?config=TeX-AMS-MML_HTMLorMML
    markdown_extensions:
      - mdx_math
      - tables
    plugins:
      - mkdocs-jupyter
  '';

  dir2Index = dir: n:
    (if pathIsDirectory dir then
      "\n"
      + (replicate n "#") 
      + "${concatMapStrings (n: n + " ") (splitString "_" (last (splitString ''-''  (toString (baseNameOf dir)))))}\n"
      + (readFile (append dir ".section.md"))
      + ''

	| Documents | Last Modified |
	|------|------|
      ''
      + (foldl' (a: e: a + e) "" 
	(map 
	  (d: (dir2Index (append dir d) (n+1)))
	  (filter (n: n!=".section.md") (attrNames (readDir dir)))
	)
      )
    else if ((hasSuffix ".md" dir) || (hasSuffix ".py" dir)) then
      ''
	| [${baseNameOf dir}](${ 
	  "./" + (concatMapStrings
	    (s: s + "/")
	    (removePrefix 
	      (sublist 0 4 (components ("."+(toString dir)))) 
	      (components ("." +(toString dir)))
	    )
	  )
	}) &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; | June 1 1970 |
      ''
    else
      ""
    );

  myenv = pkgs.python3.withPackages (ps: with ps; [
    mkdocs
    python-markdown-math
    mkdocs-linkcheck
    mkdocs-jupyter
  ]);
in
{
  options = with lib.types; {
    mkdocs.enable = lib.mkEnableOption "Enable Module";
    mkdocs.siteName = lib.mkOption {
      type = str;
      default = "My Docs";
    };
    mkdocs.ip = lib.mkOption { 
      type = str;
      default = "127.0.0.1";
    };
    mkdocs.port = lib.mkOption { 
      type = str;
      default = "8000";
    };
    mkdocs.colorScheme = lib.mkOption {
      type = enum ["light" "dark" "auto"];
      default = "dark";
    };
    mkdocs.theme = lib.mkOption {
      type = enum [ "readthedocs" "mkdocs" ];
      default = "readthedocs";
    };
    mkdocs.workingDir = lib.mkOption {
      type = str;
      default = "/var/mkdocs";
    };
    mkdocs.docsDir = lib.mkOption {
      type = path;
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.services.mkdocs = {
      enable = true;
      description = "Service to run backend of mkdocs";
      wantedBy = [ "multi-user.target" ];
      serviceConfig = { Type = "simple"; };
      path = [ pkgs.drawio-headless ];
      script = ''
	cd ${cfg.workingDir}
	rm -rf ./*
	mkdir ./docs
	mkdir ./docs/rendered_images
	echo "${yml cfg.siteName cfg.theme cfg.colorScheme}" > ${cfg.workingDir}/mkdocs.yml
	cp -r ${cfg.docsDir}/* ${cfg.workingDir}/docs
	echo '${dir2Index cfg.docsDir 1}' > ${cfg.workingDir}/docs/index.md
	
	# Break index into lines
	lines=()
	IFS=$'\n'
	while read line; do
	  lines+=($line)
	done < ${cfg.workingDir}/docs/index.md
	unset IFS
	
	# Go over each line and look 2 lines ahead, if we see the pattern)
	# | Documents | Last Modified |
	# | --- | --- |
	# <empty>
	# Then delete the first two lines. Else write out the line.
	line_1=""
	line_2=""
	for i in "''${lines[@]}"
	do
	  i=$(echo "$i" | tr -d '\n' | tr -d '\t')
	  if [ "$line_2" = "| Documents | Last Modified |" ] && [ "$line_1" = "|------|------|" ]; then
	    if ! [ "''${i:0:1}" = "|" ]; then
	      line_2=""
	      line_1=""
	    fi
	  fi

	  if [ "''${line_2:0:1}" = "#" ]; then
	    echo "" >> _index.md
	    echo "" >> _index.md
	  fi

	  echo "''${line_2}" >> _index.md
	 
	  line_2=$line_1
	  line_1=$i
	done
	
	echo "''${line_1}" >> _index.md
	echo "''${line_2}" >> _index.md

	sed -i "s/\#docs/\# ${cfg.siteName} Index Page/" _index.md

	mv _index.md ./docs/index.md 
  
	cd ${cfg.workingDir}/docs/Data_Management/Project_Files
	drawio -x -f svg test.drawio --no-sandbox
	mv test.svg ${cfg.workingDir}/docs/rendered_images
	cd ${cfg.workingDir}
	${myenv}/bin/mkdocs serve -a ${cfg.ip}:${cfg.port}
      '';
    };
  };
}
