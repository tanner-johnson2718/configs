# Provide some auto-generated index documentation that is generated from the 
# directory structure. To facilitate this we will assume our docs repo has the
# following directory structure:
#
# - docs/
#   - Topic_1
#     - Sub_Topic_1_1
#       - <.md>
#       - <.png / .jpg>
#       - <.drawio>
#       - .section.md
#   - .section.md 
# - .section.md
#
# The index page that will be generated should infer the headings from the
# directory structure. The .section.md allow you to add a short description
# of the topic and/or the contents of the docs in the directory this file is
# contained in. Then for each markdown file in a given, a table is generated
# linking to that file. Finally, for every .drawio file we have, we generate
# an .svg of that drawio file and place it in the dir of the drawio file, 
# replacing the extension with .svg. 

# TODO Link Checker
# TODO get rid of secondary lhs drop down menu thing
# TODO ' chars break it because of the echo '<index.md content>' command
# TODO replace the last modified date with the abstract from the page.
# TODO Generate docs from comments of Nix modules / confs?
# TODO create a nix shell for launching
# TODO need to have atleast two mds in a dir??

{pkgs, lib}:
let
  inherit (builtins) readDir readFile toString attrNames foldl' filter;
  inherit (lib.path) append;
  inherit (lib.path.subpath) components;
  inherit (lib.filesystem) pathIsDirectory;
  inherit (lib.strings) hasSuffix splitString replicate concatMapStrings;
  inherit (lib.lists) last sublist removePrefix;
  
  siteName = "Mono";
  theme = "readthedocs";
  colorScheme = "dark";

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
pkgs.writeScriptBin "mkdocs-generator" ''
	echo "${yml siteName theme colorScheme}" > ./mkdocs.yml
	echo '${dir2Index ../../docs 1}' > ./docs/index.md
	
	# Break index into lines
	lines=()
	IFS=$'\n'
	while read line; do
	  lines+=($line)
	done < ./docs/index.md
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

	sed -i "s/\#docs/\# ${siteName}/" _index.md

	mv _index.md ./docs/index.md 
  
	for i in $(find ./docs -name "*.drawio")
	do
	  pushd . &> /dev/null
	  cd $(dirname $i)
	  ${pkgs.drawio-headless}/bin/drawio -x -f svg $(basename $i) -o $(basename $i '.drawio').svg --no-sandbox
	  popd &> /dev/null
	done
      ''
