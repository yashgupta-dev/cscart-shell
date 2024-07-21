# opencart.sh

## Description
This script provides a set of functionalities to manage OpenCart addons and libraries from the command line.

## Usage

```
opencart.sh {create-addon <name>|install-validation-library|create-addon-zip <addon-name> [-z] <zip>|delete <addon-name>}
```

### Commands:

#### create-addon <name>
Creates an OpenCart addon with the specified name.

**Arguments:**
- `<name>`: Name of the addon to create. Should only contain alphanumeric characters and underscores.

**Example:**
```
opencart.sh create-addon my_new_addon
```

#### install-validation-library
Installs a validation library. This command is self-contained and does not require additional arguments.

**Example:**
```
opencart.sh install-validation-library
```

#### create-addon-zip <addon-name> [-z] <zip>
Creates a zip file for an addon.

**Arguments:**
- `<addon-name>`: Name of the addon to create a zip for.
- `[-z] <zip>`: Optional flag to compress the addon files into a zip archive.

**Example:**
```
opencart.sh create-addon-zip my_addon -z my_addon.zip
```

#### delete <addon-name>
Deletes an existing addon.

**Arguments:**
- `<addon-name>`: Name of the addon to delete.

**Example:**
```
opencart.sh delete my_addon
```

### Notes:
- Make sure to replace `<name>` and `<addon-name>` with actual names as per your requirements.
- The script assumes basic validation for addon names (alphanumeric characters and underscores).
- Use each command as per your specific needs and ensure proper input to avoid errors.

## Author
Yash Gupta

## License
This project is licensed under the Yash Gupta ( Code Corner ) License - see the LICENSE file for details.

---

Replace `Yash Gupta` with your actual name and `Yash Gupta ( Code Corner )` with the specific license under which your script is distributed. If you don't have a license file yet, you may want to consider adding one to specify the terms under which others can use, modify, and distribute your script.