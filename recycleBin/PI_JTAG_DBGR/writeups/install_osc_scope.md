# Installing the Software for our OWON VDS1022i

* `sudo apt install default-jre`
* Download latest release at [github repo](https://github.com/florentbr/OWON-VDS1022)
* `cd <owon_rep> && chmod +x ./install-linux.sh && ./install-linux.sh`
* `sudo mv /usr/lib/python3.11/EXTERNALLY-MANAGED /usr/lib/python3.11/EXTERNALLY_MANAGED.old`
* `pip install --no-cache-dir api/python --break-system-packages`
	* This would fail but would need to wget and locally install each wheel package
* `scope_scripts` has some scripts for using the python interface