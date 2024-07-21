#!/bin/bash

# Function to display success message in green color
print_success() {
    echo -e "\e[32m$1\e[0m" # \e[32m sets color to green, \e[0m resets color back to default
}

# Function to display error message in red color
print_error() {
    echo -e "\e[31m$1\e[0m" # \e[31m sets color to red, \e[0m resets color back to default
}

# Function to prompt for table name
prompt_for_table_name() {
    local table_name # Variable to store table name entered by user

    # Prompt user to enter table name (without prefix, it will be auto added)
    read -p "Enter table name (without prefix, it will be auto added): " table_name

    # Combine DB_PREFIX with user-provided table name
    table_name="?:${table_name}"

    # Echo the table name
    echo "$table_name"
}

# Function to generate SQL query based on table name and fields
generate_sql_query() {
    local table_name="$1"
    local sql_query=""

    # Start building SQL query with DB_PREFIX and combined table name
    sql_query+="CREATE TABLE IF NOT EXISTS \`$table_name\` (\n"

    # Prompt for fields and types until done
    while true; do
        read -p "Enter field name (or 'y' to finish): " field_name
        if [ "$field_name" == "y" ]; then
            break
        fi

        read -p "Enter field data type: " field_data_type

        # Append field and type to SQL query with proper newline and indentation
        sql_query+="  \`$field_name\` $field_data_type,"
    done

    # Remove the last comma and close the statement
    sql_query=$(echo -e "$sql_query" | sed '$ s/,$//')
    sql_query+=") ENGINE=MyISAM DEFAULT CHARSET UTF8;"

    # Echo the generated SQL query
    echo "$sql_query"
}

prompt_for_inputs() {
    local TEXT="$1"
    local var # Variable to store table name entered by user

    # Prompt user to enter table name (without prefix, it will be auto added)
    read -p "$TEXT: " var

    # Echo the var
    echo "$var"
}

# Function to check if a variable is in array
check_in_array() {
    local value="$1"
    shift              # Shifts the arguments, skipping the first one which is now in 'value'
    local array=("$@") # Store the remaining arguments in the array

    for item in "${array[@]}"; do
        if [ "$item" = "$value" ]; then
            return 0 # Found a match, return success (true)
        fi
    done
    return 1 # No match found, return failure (false)
}

# Functcion to delete addons from directory
prompt_delete_addon() {
    local MODULE="$1"

    # Prompt for fields and types until done
    read -p "Are you sure, want to remove addon <$MODULE>? (Y) " choice
    if [ "$choice" == "Y" ]; then
        # Directories to delete
        directories=(
            "app/addons"
            "design/backend/templates/addons"
            "var/langs/en/addons"
            "js/addons"
            "design/backend/media/images/addons"
            "design/backend/css/addons"
            "design/themes/responsive/css/addons"
            "design/themes/responsive/media/images/addons"
            "design/themes/responsive/templates/addons"
        )

        # Loop through each directory and delete it
        for dir in "${directories[@]}"; do
            # Check if the directory exists
            if [ -d "$dir/$MODULE" ] || [ -f "$dir/$MODULE.po" ]; then
                # Remove directory
                if [ -f "$dir/$MODULE.po" ]; then
                    if rm -rf "$dir/$MODULE".po; then
                        print_success "Language $dir/$MODULE.po successfully removed"
                    else
                        print_error "Failed to remove language $dir/$MODULE"
                    fi
                else
                    if rm -rf "$dir/$MODULE"; then
                        print_success "Directory $dir/$MODULE successfully removed"
                    else
                        print_error "Failed to remove directory $dir/$MODULE"
                    fi
                fi
            else
                print_error "Directory $dir/$MODULE does not exist"
            fi
        done
    else
        exit 1
    fi
}

prompt_addon_zip() {
    local MODULE="$1"
    local ISZIP="$2"

    local ADMIN_PATH='app/addons'

    MODULE_DIRECTORY="$ADMIN_PATH/$MODULE"

    # Check if module directory exists
    if [ -d "$MODULE_DIRECTORY" ]; then
        if [ "$ISZIP" = "-z" ]; then

            # Directories to delete
            directories=(
                "app/addons/$MODULE"
                "design/backend/templates/addons/$MODULE"
                "var/langs/en/addons/$MODULE.po"
                "var/langs/fr/addons/$MODULE.po"
                "js/addons/$MODULE"
                "design/backend/media/images/addons/$MODULE"
                "design/backend/css/addons/$MODULE"
                "design/themes/responsive/css/addons/$MODULE"
                "design/themes/responsive/media/images/addons/$MODULE"
                "design/themes/responsive/templates/addons/$MODULE"
            )

            # Name of the output zip file
            zip_file="addon_$MODULE.zip"

            # Create the zip file
            if zip -r "$zip_file" "${directories[@]}"; then
                print_success "Zip file '$zip_file' created successfully."
            else
                print_success "Unable to create $MODULE Zip file."
            fi

        else
            echo "Usage: opencart.sh {create-addon <name>|install-validation-library|create-addon-zip <addon-name> [-z] <zip>|delete <addon-name>}"
            exit 1
        fi
    else
        print_error "Addon <$MODULE> does not exist"
        exit 1
    fi

}

# Function to create directories and files for admin and catalog sides
create_extension() {
    local EXTENSION_NAME="$1"
    local ADMIN_PATH='app/addons'

    MODULE_DIRECTORY="$ADMIN_PATH/$EXTENSION_NAME"

    # Check if module directory exists
    if [ -d "$MODULE_DIRECTORY" ]; then
        print_error "Module directory already exist: $MODULE_DIRECTORY"
        exit 1 # Exit script with error code
    fi

    # Convert extension name to CamelCase for class name
    local CLASS_NAME=$(echo "$EXTENSION_NAME" | sed -e 's/_//g' | awk '{for(i=1;i<=NF;i++) $i=toupper(substr($i,1,1)) tolower(substr($i,2)); print $0}')

    # Create admin directories and files
    mkdir -p $ADMIN_PATH/$EXTENSION_NAME
    cat <<EOF >$ADMIN_PATH/$EXTENSION_NAME/addons.xml
<?xml version="1.0"?>
<addon scheme="4.0">
    <id>$EXTENSION_NAME</id>
    <version>1.0</version>
EOF

    # Call function to prompt for inputs
    priority=$(prompt_for_inputs "Enter addon priority?")
    if [ -n "${priority}" ]; then
        cat <<EOF >>$ADMIN_PATH/$EXTENSION_NAME/addons.xml
    <priority>$priority</priority>
EOF
    fi

    # Call function to prompt for inputs
    position=$(prompt_for_inputs "Enter addon position?")
    if [ -n "${position}" ]; then
        cat <<EOF >>$ADMIN_PATH/$EXTENSION_NAME/addons.xml
    <position>$position</position>
EOF
    fi

    # Call function to prompt for inputs
    has_icon=$(prompt_for_inputs "Enter addon has_icon (Y/N)?")
    valid_values=("Y" "N")
    # Check if 'has_icon' is not null, not blank, equals 'Y', and is in the 'valid_values' array
    if [ -n "${has_icon}" ] && check_in_array "$has_icon" "${valid_values[@]}"; then
        cat <<EOF >>$ADMIN_PATH/$EXTENSION_NAME/addons.xml
    <has_icon>$has_icon</has_icon>
EOF
    fi

    # Call function to prompt for inputs
    default_language=$(prompt_for_inputs "Enter addon default_language (en/fr)?")
    valid_values=("en" "fr")
    if [ -n "${default_language}" ] && check_in_array "$default_language" "${valid_values[@]}"; then
        cat <<EOF >>$ADMIN_PATH/$EXTENSION_NAME/addons.xml
    <default_language>$default_language</default_language>
EOF
    fi

    # Call function to prompt for inputs
    status=$(prompt_for_inputs "Enter addon status (active or inactive)?")
    valid_values=("active" "inactive")
    if [ -n "${status}" ] && check_in_array "$status" "${valid_values[@]}"; then
        cat <<EOF >>$ADMIN_PATH/$EXTENSION_NAME/addons.xml
    <status>$status</status>
EOF
    fi

    # Call function to prompt for inputs
    auto_install=$(prompt_for_inputs "Enter addon auto_install (MULTIVENDOR and ULTIMATE and Both)?")
    valid_values=("MULTIVENDOR","ULTIMATE")
    if [ -n "${auto_install}" ] && check_in_array "$auto_install" "${valid_values[@]}"; then
        cat <<EOF >>$ADMIN_PATH/$EXTENSION_NAME/addons.xml
    <auto_install>$auto_install</auto_install>
EOF
    fi

    # Call function to prompt for inputs
    supplier=$(prompt_for_inputs "Enter addon supplier?")
    if [ -n "${supplier}" ]; then
        cat <<EOF >>$ADMIN_PATH/$EXTENSION_NAME/addons.xml
    <supplier>$supplier</supplier>
EOF
    fi

    # Call function to prompt for inputs
    supplier_link=$(prompt_for_inputs "Enter addon supplier_link?")
    if [ -n "${supplier_link}" ]; then
        cat <<EOF >>$ADMIN_PATH/$EXTENSION_NAME/addons.xml
    <supplier_link>$supplier_link</supplier_link>
EOF
    fi

    # Call function to prompt for inputs
    authors=$(prompt_for_inputs "Enter addon authors (Y/N)")
    valid_values=("Y" "N")
    if [ -n "${authors}" ] && check_in_array "$authors" "${valid_values[@]}"; then
        cat <<EOF >>$ADMIN_PATH/$EXTENSION_NAME/addons.xml
    <authors>
        <author>
            <name>cscart</name>
            <email>cscart@example.com</email>
            <url>example.store</url>
        </author>
    </authors>
EOF
    fi

    # Call function to prompt for inputs
    dependencies=$(prompt_for_inputs "Enter addon dependencies (Seprated comma)")

    if [ -n "${dependencies}" ]; then
        cat <<EOF >>$ADMIN_PATH/$EXTENSION_NAME/addons.xml
    <compatibility>
        <dependencies>$dependencies</dependencies>
    </compatibility>
EOF
    fi

    cat <<EOF >>$ADMIN_PATH/$EXTENSION_NAME/addons.xml
    <autoload>
        <psr4 prefix="Tygh\Addons\\$CLASS_NAME\">src</psr4>
    </autoload>  
    <bootstrap>\Tygh\Addons\\$CLASS_NAME\Bootstrap</bootstrap>
    <installer>\Tygh\Addons\\$CLASS_NAME\Installer</installer> 
EOF

    # Call function to prompt for inputs
    settings=$(prompt_for_inputs "Want to create configuration tpl? (Y)")
    valid_values=("Y")
    if [ -n "${settings}" ] && check_in_array "$settings" "${valid_values[@]}"; then
        cat <<EOF >>$ADMIN_PATH/$EXTENSION_NAME/addons.xml
    <settings edition_type="ROOT,ULT:VENDOR">
        <sections>
            <section id="general">                
                <items>
                    <item id="${EXTENSION_NAME}_configuration"> 
                        <type>template</type>                        
                        <default_value>${EXTENSION_NAME}_setting.tpl</default_value>
                    </item>                    
                </items>
            </section>
        </sections>  
    </settings>
EOF

        # Create admin directories and files
        mkdir -p $ADMIN_PATH/$EXTENSION_NAME/controllers/backend
        cat <<EOF >>$ADMIN_PATH/$EXTENSION_NAME/controllers/backend/addons.post.php
<?php
/******************************************************************
/* $EXTENSION_NAME                                            *
*******************************************************************/

use ${CLASS_NAME}Controller\AddonsPost;

if (!defined('BOOTSTRAP')) {die('Access denied');}

\$addons = new AddonsPost(\$mode);

if (isset(\$addons->response) && !empty(\$addons->response)) {
    return \$addons->response;
}

EOF

        if [ -f "$ADMIN_PATH/$EXTENSION_NAME/controllers/backend/addons.post.php" ]; then
            print_success "Created:: $ADMIN_PATH/$EXTENSION_NAME/controllers/backend/addons.post.php"
        else
            print_error "Failed:: $ADMIN_PATH/$EXTENSION_NAME/controllers/backend/addons.post.php"
        fi

        # Create admin directories and files
        mkdir -p design/backend/templates/addons/$EXTENSION_NAME/settings
        cat <<EOF >>design/backend/templates/addons/$EXTENSION_NAME/settings/${EXTENSION_NAME}_setting.tpl

EOF

        if [ -f "design/backend/templates/addons/$EXTENSION_NAME/settings/${EXTENSION_NAME}_setting.tpl" ]; then
            print_success "Created:: design/backend/templates/addons/$EXTENSION_NAME/settings/${EXTENSION_NAME}_setting.tpl"
        else
            print_error "Failed:: design/backend/templates/addons/$EXTENSION_NAME/settings/${EXTENSION_NAME}_setting.tpl"
        fi

        # Create admin directories and files
        mkdir -p design/backend/media/images/addons/$EXTENSION_NAME
        print_success "Info:: add your icon.png image here [design/backend/media/images/addons/$EXTENSION_NAME]/icon.png"
    fi

    # Call function to prompt for inputs
    table=$(prompt_for_inputs "Want create table? (Y)")
    valid_values=("Y")
    if [ -n "${table}" ] && check_in_array "$table" "${valid_values[@]}"; then

        # Call function to prompt for table name
        table_name=$(prompt_for_table_name)

        # Call function to generate SQL query based on the table name
        sql_query=$(generate_sql_query "$table_name")

        cat <<EOF >>$ADMIN_PATH/$EXTENSION_NAME/addons.xml
    <queries>
        <item>DROP TABLE IF EXISTS \`$table_name\`;</item>
        <item>
            $sql_query
        </item>
        <item for="uninstall">DROP TABLE IF EXISTS \`$table_name\`;</item>
    </queries>
EOF
    fi
    cat <<EOF >>$ADMIN_PATH/$EXTENSION_NAME/addons.xml
</addon>
EOF

    if [ -f "$ADMIN_PATH/$EXTENSION_NAME/addons.xml" ]; then
        print_success "Created:: $ADMIN_PATH/$EXTENSION_NAME/addons.xml\n"

        echo "Generating src directory..."
        mkdir -p $ADMIN_PATH/$EXTENSION_NAME/src

        # creating bootstrap file
        cat <<EOF >>$ADMIN_PATH/$EXTENSION_NAME/src/Bootstrap.php
<?php

namespace Tygh\Addons\\$CLASS_NAME;

use Tygh\Core\ApplicationInterface;
use Tygh\Core\BootstrapInterface;
use Tygh\Core\HookHandlerProviderInterface;

class Bootstrap implements BootstrapInterface, HookHandlerProviderInterface
{

    /** @inheritDoc */
    public function boot(ApplicationInterface \$app)
    {
        \$app->register(new ServiceProvider());
    }

    /** @inheritDoc */
    public function getHookHandlerMap()
    {
        return [
            // 'delete_product_post'=> [
            //    'addons.wk_shopify_channel.hook_handlers.products',
            //    'deleteProductPost',
            // ]
        ];

        
    }
}
EOF

        if [ -f "$ADMIN_PATH/$EXTENSION_NAME/src/Bootstrap.php" ]; then
            print_success "Created:: $ADMIN_PATH/$EXTENSION_NAME/src/Bootstrap.php"
        else
            print_error "Failed:: $ADMIN_PATH/$EXTENSION_NAME/src/Bootstrap.php"
        fi

        # creating Installer file
        cat <<EOF >>$ADMIN_PATH/$EXTENSION_NAME/src/Installer.php
<?php
namespace Tygh\Addons\\$CLASS_NAME;

use Tygh\Addons\InstallerInterface;
use Tygh\Core\ApplicationInterface;

class Installer implements InstallerInterface
{

    /**
     * @inheritDoc
     */
    public static function factory(ApplicationInterface \$app)
    {
        return new self();
    }

    /**
     * @inheritDoc
     */
    public function onBeforeInstall()
    {
    }

    /**
     * @inheritDoc
     */
    public function onInstall()
    {

        \$addon_name = __('$EXTENSION_NAME'.addon_name);

        fn_set_notification(
            'S',
            __('$EXTENSION_NAME.well_done'),
            __('$EXTENSION_NAME.user_guide_content', array('[support_link]' => 'https://webkul.uvdesk.com/en/customer/create-ticket/', '[user_guide]' => 'https://webkul.com/blog/cs-cart-point-of-sale-pos/', '[addon_name]' => \$addon_name))
        );
    }

    /**
     * @inheritDoc
     */
    public function onUninstall()
    {
        
    }
}

EOF

        if [ -f "$ADMIN_PATH/$EXTENSION_NAME/src/Installer.php" ]; then
            print_success "Created:: $ADMIN_PATH/$EXTENSION_NAME/src/Installer.php"
        else
            print_error "Failed:: $ADMIN_PATH/$EXTENSION_NAME/src/Installer.php"
        fi

        # creating ServiceProvider file
        cat <<EOF >>$ADMIN_PATH/$EXTENSION_NAME/src/ServiceProvider.php
<?php

namespace Tygh\Addons\\$CLASS_NAME;

use Pimple\Container;
use Pimple\ServiceProviderInterface;

class ServiceProvider implements ServiceProviderInterface
{
    /**
     * {@inheritdoc}
     */
    public function register(Container \$app)
    {
        // \$app['addons.wk_shopify_channel.hook_handlers.products'] = static function () {
            // return new HookHandlers\ProductHookHandler();
        // };
    }
}


EOF

        if [ -f "$ADMIN_PATH/$EXTENSION_NAME/src/ServiceProvider.php" ]; then
            print_success "Created:: $ADMIN_PATH/$EXTENSION_NAME/src/ServiceProvider.php"
        else
            print_error "Failed:: $ADMIN_PATH/$EXTENSION_NAME/src/ServiceProvider.php"
        fi

        print_success "Generating $ADMIN_PATH/$EXTENSION_NAME/src/HookHandlers directory..."
        mkdir -p $ADMIN_PATH/$EXTENSION_NAME/src/HookHandlers
        print_success "Generated."

        echo "Successfully deployed src directory into the $EXTENSION_NAME addons"

        # created controller
        mkdir -p $ADMIN_PATH/$EXTENSION_NAME/${CLASS_NAME}Controller

        # creating Installer file
        cat <<EOF >>$ADMIN_PATH/$EXTENSION_NAME/${CLASS_NAME}Controller/BaseController.php
<?php
/******************************************************************
# $EXTENSION_NAME --- $CLASS_NAME                                *
*******************************************************************/
namespace ${CLASS_NAME}Controller;

use Tygh\Tygh;
use Tygh\Registry;
use ${CLASS_NAME}Models\\${CLASS_NAME}Model;
use Helpers\\${CLASS_NAME}Helper;

class BaseController
{
    /**
     * @var string mode is the method of the class.
     */
    protected \$mode;

    /**
     * @var object mode is the method of the class.
     */
    protected \$view;

    /**
     * @var array mode is the method of the class.
     */
    protected \$auth;

    /**
     * @var string mode is the method of the class.
     */

    /**
     * @var string Server Request method like GET,POST is save under this variable
     */
    protected \$requestMethod;

    /**
     * @var array|string \$_REQUEST data is save under this variable
     */
    protected \$requestParam;

    /**
     * @var array this variable stores all the mode which will be able to run under this class
     */
    protected \$runMode = array();

    /**
     * @var object this variable is used to return the response.
     */
    public \$response;

    protected \$loadModel;

    public \$helper;

    /**
     * BaseController constructor.
     *
     * @param string \$mode
     */
    public function __construct(\$mode = '')
    {
        \$this->mode = \$mode;
        \$this->loadModel = new ${CLASS_NAME}Model();
        \$this->view = Tygh::\$app['view'];
        \$this->auth = Tygh::\$app['session']['auth'];
        \$this->requestMethod = \$_SERVER['REQUEST_METHOD'];
        \$this->requestParam = \$_REQUEST;
        \$this->helper = new ${CLASS_NAME}Helper();
    }

    /**
     * @param array \$runMode
     * 
     * @return void
     */
    protected function setRunMode(\$runMode = array())
    {
        if (is_array(\$runMode)) {
            \$this->runMode = array_unique(\$runMode);
        } else {
            array_push(\$this->runMode, \$runMode);
            \$this->runMode = array_unique(\$this->runMode);
        }
    }

    /**
     * @param array \$runMode
     * 
     * @return void
     */
    protected function setNoPage()
    {
        \$url = fn_url('_no_page?' . http_build_query(array('page' => \$_SERVER['REQUEST_URI'])), AREA, 'rel');
        \$_REQUEST['redirect_url'] = \$url;
    }

    /**
     * Name:- paginationMethod
     * Description:- This method will use for all the pages for creating pagination;
     * 
     * @param int
     * @return array
     */
    public function paginationMethod(\$totalItems)
    {
        \$offset = 0;
        if (isset(\$this->requestParam['items_per_page'])) {
            \$itemsPerPage = \$this->requestParam['items_per_page'];
        } else {
            \$itemsPerPage = trim(Registry::get('settings.Appearance.admin_elements_per_page'));
        }
        \$page = 1;
        if (isset(\$this->requestParam['is_ajax'])) {
            if (isset(\$this->requestParam['page'])) {
                \$page = \$this->requestParam['page'];
                if ((\$page - 1) * \$itemsPerPage >= \$totalItems) {

                    \$page = ceil(\$totalItems / \$itemsPerPage);
                }
                \$offset = ((\$page - 1) * \$itemsPerPage);
            }
        }
        \$params['items_per_page'] = \$itemsPerPage;
        \$params['page'] = \$page;
        \$params['total_items'] = \$totalItems;
        \$params['offset'] = \$offset;
        return \$params;
    }
}
EOF

        if [ -f "$ADMIN_PATH/$EXTENSION_NAME/${CLASS_NAME}Controller/BaseController.php" ]; then
            print_success "Created:: $ADMIN_PATH/$EXTENSION_NAME/${CLASS_NAME}Controller/BaseController.php"
        else
            print_error "Failed:: $ADMIN_PATH/$EXTENSION_NAME/${CLASS_NAME}Controller/BaseController.php"
        fi

        # creating addonPost
        cat <<EOF >>$ADMIN_PATH/$EXTENSION_NAME/${CLASS_NAME}Controller/AddonsPost.php
<?php
/******************************************************************
# $CLASS_NAME                        *
*******************************************************************/
namespace ${CLASS_NAME}Controller;

use Tygh\Registry;
use Tygh\Tygh;
use Tygh\Settings;
use ${CLASS_NAME}Controller\BaseController;


class AddonsPost extends BaseController {
    /**
     * AddonsPost constructor.
     *
     * @param string \$mode
     * 
     */
    public function __construct(\$mode)
    {
        parent::__construct(\$mode);
        \$this->setRunMode(['update']);
       

        if(in_array(\$this->mode, \$this->runMode)){
            \$this->\$mode();
        }
        
    }

    public function update(){

        if (\$this->requestMethod === 'POST') {
            if (\$this->requestParam['addon'] == '$EXTENSION_NAME' && (!empty(\$this->requestParam['$EXTENSION_NAME'])))
            {
                fn_trusted_vars('$EXTENSION_NAME');
                \$this->loadModel->saveAddonConfiguration(\$this->requestParam['$EXTENSION_NAME']);  
            }
        }
       
        if (\$this->requestParam['addon'] == '$EXTENSION_NAME') {
            \$config = \$this->loadModel->getSettingsData();
            Registry::get('view')->assign('${EXTENSION_NAME}_settings_data', \$config);
        }
    }
}
EOF

        if [ -f "$ADMIN_PATH/$EXTENSION_NAME/${CLASS_NAME}Controller/AddonsPost.php" ]; then
            print_success "Created:: $ADMIN_PATH/$EXTENSION_NAME/${CLASS_NAME}Controller/AddonsPost.php"
        else
            print_error "Failed:: $ADMIN_PATH/$EXTENSION_NAME/${CLASS_NAME}Controller/AddonsPost.php"
        fi

        cat <<EOF >>$ADMIN_PATH/$EXTENSION_NAME/controllers/backend/$EXTENSION_NAME.php
<?php
/******************************************************************
/* $EXTENSION_NAME                                            *
*******************************************************************/

use ${CLASS_NAME}Controller\\$CLASS_NAME;

if (!defined('BOOTSTRAP')) {die('Access denied');}

\$obj = new $CLASS_NAME(\$mode);

if (isset(\$obj->response) && !empty(\$obj->response)) {
    return \$obj->response;
}

EOF

        if [ -f "$ADMIN_PATH/$EXTENSION_NAME/controllers/backend/$EXTENSION_NAME.php" ]; then
            print_success "Created:: $ADMIN_PATH/$EXTENSION_NAME/controllers/backend/$EXTENSION_NAME.php"
        else
            print_error "Failed:: $ADMIN_PATH/$EXTENSION_NAME/controllers/backend/$EXTENSION_NAME.php"
        fi

        cat <<EOF >>$ADMIN_PATH/$EXTENSION_NAME/${CLASS_NAME}Controller/$CLASS_NAME.php
<?php
/******************************************************************
# $CLASS_NAME                        *
*******************************************************************/
namespace ${CLASS_NAME}Controller;

use Tygh\Registry;
use Tygh\Tygh;
use Tygh\Settings;
use ${CLASS_NAME}Controller\BaseController;


class $CLASS_NAME extends BaseController {
    /**
     * $CLASS_NAME constructor.
     *
     * @param string \$mode
     * 
     */
    public function __construct(\$mode)
    {
        parent::__construct(\$mode);
        \$this->setRunMode(['index']);
       

        if(in_array(\$this->mode, \$this->runMode)){
            \$this->\$mode();
        }
    }

    public function index(){
        // Your logic goes here
    }
} 
EOF

        if [ -f "$ADMIN_PATH/$EXTENSION_NAME/${CLASS_NAME}Controller/$CLASS_NAME.php" ]; then
            print_success "Created:: $ADMIN_PATH/$EXTENSION_NAME/${CLASS_NAME}Controller/$CLASS_NAME.php"
        else
            print_error "Failed:: $ADMIN_PATH/$EXTENSION_NAME/${CLASS_NAME}Controller/$CLASS_NAME.php"
        fi

        # Create admin directories and files
        mkdir -p design/backend/templates/addons/$EXTENSION_NAME/views/$EXTENSION_NAME/
        cat <<EOF >>design/backend/templates/addons/$EXTENSION_NAME/views/$EXTENSION_NAME/${EXTENSION_NAME}.tpl

        welcome auto generated addon 

EOF

        if [ -f "design/backend/templates/addons/$EXTENSION_NAME/views/$EXTENSION_NAME/${EXTENSION_NAME}.tpl" ]; then
            print_success "Created:: design/backend/templates/addons/$EXTENSION_NAME/views/$EXTENSION_NAME/${EXTENSION_NAME}.tpl"
        else
            print_error "Failed:: design/backend/templates/addons/$EXTENSION_NAME/views/$EXTENSION_NAME/${EXTENSION_NAME}.tpl"
        fi

        mkdir -p $ADMIN_PATH/$EXTENSION_NAME/Helpers
        echo "Helpers directory created."
        cat <<EOF >>$ADMIN_PATH/$EXTENSION_NAME/Helpers/${CLASS_NAME}Helper.php
<?php
/******************************************************************
# $EXTENSION_NAME --- $CLASS_NAME                                 *
 ********************************************************************/

namespace Helpers;

use ${CLASS_NAME}Models\\${CLASS_NAME}Model;
class ${CLASS_NAME}Helper extends ${CLASS_NAME}Model
{

}
EOF

        if [ -f "$ADMIN_PATH/$EXTENSION_NAME/Helpers/${CLASS_NAME}Helper.php" ]; then
            print_success "Created:: $ADMIN_PATH/$EXTENSION_NAME/Helpers/${CLASS_NAME}Helper.php"
        else
            print_error "Failed:: $ADMIN_PATH/$EXTENSION_NAME/Helpers/${CLASS_NAME}Helper.php"
        fi

        # created model
        mkdir -p $ADMIN_PATH/$EXTENSION_NAME/${CLASS_NAME}Models
        echo "Generated models directory."

        cat <<EOF >>$ADMIN_PATH/$EXTENSION_NAME/${CLASS_NAME}Models/BaseModel.php
<?php
/******************************************************************
# $EXTENSION_NAME --- $CLASS_NAME                                 *
*******************************************************************/

namespace ${CLASS_NAME}Models;

use Exception;

class BaseModel
{

    private \$data;

    private \$logId;

    private \$logFileLocation;

    public function __construct()
    {
        \$this->logId = TIME;

        \$baseUrl = substr(__DIR__, 0, strpos(__DIR__, "${CLASS_NAME}Models"));
        \$this->logFileLocation = \$baseUrl . 'logs/${EXTENSION_NAME}mysql.log';
        // Here base model is loaded
    }

    /**
     * 
     * @param string \$varName
     * 
     * @return string|array|object
     */
    public function __get(\$varName)
    {

        if (!array_key_exists(\$varName, \$this->data)) {
            throw new Exception('.....');
        } else return \$this->data[\$varName];
    }

    /**
     * 
     * 
     * @return void
     */
    public function __set(\$varName, \$value)
    {
        \$this->data[\$varName] = \$value;
    }

    /**
     * 
     * @param string
     * @param string|array
     * @param array
     * @param string
     * @param string
     * 
     * @return string|array|object|void
     */
    public function select(\$table, \$selection, \$where, \$func, \$others = '', \$limit = '', \$offset = '')
    {

        \$selection = (is_array(\$selection)) ? implode(",", \$selection) : \$selection;
        \$selection = (empty(\$selection)) ? '*' : \$selection;
        \$query = "SELECT \$selection FROM ?:\$table";
        if (!empty(\$where)) {
            \$query .= " WHERE 1 ";
            foreach (\$where as \$column => \$values) {
                if (is_array(\$values)) {

                    if (\$this->checkWhereClause(\$values[1])) {
                        \$value = "('" . implode("', '", \$values[0]) . "')";
                    } else {                        
                        \$value = \$this->checkIsString(\$values[0]);
                    }
                    \$constraint = \$values[1];                    
                } else {

                    \$_isValid = !empty(explode(':', \$values)[1]) ? true : false;
                    if (filter_var(\$values, FILTER_VALIDATE_URL)) {
                        \$_isValid = false;
                    }
                    if (\$_isValid) {
                        \$value = \$this->checkIsString(explode(':', \$values)[0]);
                        \$constraint = explode(':', \$values)[1];
                    } else {
                        \$value = \$this->checkIsString(\$values);
                        \$constraint = '=';
                    }
                }
                \$query .= "AND \$column \$constraint \$value ";
            }
        }
        \$query = (!empty(trim(\$others))) ? \$query . \$others : \$query;
        \$func = empty(\$func) ? 'db_get_array' : \$func;

        if (!empty(\$limit)) {
            \$data = (!empty(\$offset)) ? \$offset . ', ' . \$limit : \$limit;
            \$query .= " LIMIT \$data";
        }

        try {
            \$result = \$func(\$query);
            return \$result;
        } catch (Exception \$e) {

            \$this->writeLog(\$this->logFileLocation, \$e->getMessage());
        }
    }

    /**
     * 
     * @param string
     * @param array
     * 
     * @return
     */
    public function insert(\$table, \$params)
    {
        \$query = "INSERT INTO ?:\$table ?e";

        try {
            return db_query(\$query, \$params);
        } catch (Exception \$e) {

            \$this->writeLog(\$this->logFileLocation, \$e->getMessage());
        }
    }

    /**
     * 
     * @param string
     * @param array
     * 
     * @return void
     */
    public function replace(\$table, \$params)
    {

        \$query = "REPLACE INTO ?:\$table ?e";
        try {
            return db_query(\$query, \$params);
        } catch (Exception \$e) {
            \$this->writeLog(\$this->logFileLocation, \$e->getMessage());
        }
    }

    /**
     * 
     * @param string
     * @param array
     * @param array
     * 
     * @return void
     */
    public function update(\$table, \$params, \$where = array())
    {
        \$query = "UPDATE ?:\$table SET ?u";
        if (!empty(\$where)) {
            \$query .= " WHERE ";
            \$condition = ' AND ';

            \$extraWhere = true;
            \$lastIndex = 0; // check last index
            \$totalCondition = count(\$where); // check total where condition.

            if (count(\$where) > 1) {
                \$extraWhere = false;
            }

            foreach (\$where as \$column => \$values) {
                if (is_array(\$values)) {
                    if (\$this->checkWhereClause(\$values[1])) {
                        \$value = "('" . implode("', '", \$values[0]) . "')";
                    } else {
                        \$value = \$this->checkIsString(\$values[0]);
                    }
                    \$constraint = \$values[1];
                } else {
                    \$value = \$this->checkIsString(\$values);
                    \$constraint = '=';
                }

                // this will work for single where condition;
                if (\$extraWhere) {

                    \$query .= "\$column \$constraint \$value ";
                } else {
                    // this will work for multiple where condition
                    if (++\$lastIndex === \$totalCondition) {
                        \$query .= "\$column \$constraint \$value";
                    } else {
                        \$query .= "\$column \$constraint \$value \$condition";
                    }
                }
            }
        }
        try {
            db_query(\$query, \$params);
        } catch (Exception \$e) {
            \$this->writeLog(\$this->logFileLocation, \$e->getMessage());
        }
    }


    /**
     * 
     * @param string
     * @param array
     * 
     * @return void
     */
    public function delete(\$table, \$where = array())
    {
        \$query = "DELETE FROM ?:\$table";
        if (!empty(\$where)) {
            \$query .= " WHERE ";
            foreach (\$where as \$column => \$value) {
                if (is_array(\$value)) {
                    \$value = \$this->checkIsString(\$value[0]);
                    \$constraint = \$value[1];
                } else {
                    \$value = \$this->checkIsString(\$value);
                    \$constraint = '=';
                }
                \$query .= "\$column \$constraint \$value ";
            }

            try {
                return db_query(\$query);
            } catch (Exception \$e) {
                \$this->writeLog(\$this->logFileLocation, \$e->getMessage());
            }
        }
    }

    public function deleteMoreCondition(\$table, \$where = array())
    {
        \$query = "DELETE FROM ?:\$table";
        if (!empty(\$where)) {
            \$query .= " WHERE ";
            \$condition = ' AND ';

            \$extraWhere = true;
            \$lastIndex = 0; // check last index
            \$totalCondition = count(\$where); // check total where condition.

            if (count(\$where) > 1) {
                \$extraWhere = false;
            }

            foreach (\$where as \$column => \$values) {
                if (is_array(\$values)) {
                    if (\$this->checkWhereClause(\$values[1])) {
                        \$value = "('" . implode("', '", \$values[0]) . "')";
                    } else {
                        \$value = \$this->checkIsString(\$values[0]);
                    }
                    \$constraint = \$values[1];
                } else {
                    \$value = \$this->checkIsString(\$values);
                    \$constraint = '=';
                }

                // this will work for single where condition;
                if (\$extraWhere) {

                    \$query .= "\$column \$constraint \$value ";
                } else {
                    // this will work for multiple where condition
                    if (++\$lastIndex === \$totalCondition) {
                        \$query .= "\$column \$constraint \$value";
                    } else {
                        \$query .= "\$column \$constraint \$value \$condition";
                    }
                }
            }
        }


        try {
            return db_query(\$query);
        } catch (Exception \$e) {

            \$this->writeLog(\$this->logFileLocation, \$e->getMessage());
        }
    }

    /**
     * @param string
     * 
     * @return string
     */
    private function checkIsString(\$value)
    {
        return (is_string(\$value)) ? "\"\$value\"" : \$value;
    }

    /**
     * @param string
     * @param array
     * 
     * @return string|array|void
     */
    public function writeLog(\$file, \$contents)
    {
        \$file = fopen(\$this->logFileLocation, "a+");
        \$contents = \$this->logId . " " . date("Y-m-d h:i:s", TIME) . " " . \$contents . "\n";
        fwrite(\$file, \$contents);
        fclose(\$file);
    }

    /**
     * Check Where clause exist or not.
     * 
     * @param string
     * 
     * @return bool
     */
    private function checkWhereClause(\$value)
    {
        \$allowedClause = array('NOT IN', 'IN');
        return in_array(\$value, \$allowedClause);
    }

    public function manualQuery(\$query, \$func)
    {

        \$result = \$func(\$query);
        return \$result;
    }
}

EOF

        if [ -f "$ADMIN_PATH/$EXTENSION_NAME/${CLASS_NAME}Models/BaseModel.php" ]; then
            print_success "Created:: $ADMIN_PATH/$EXTENSION_NAME/${CLASS_NAME}Models/BaseModel.php"
        else
            print_error "Failed:: $ADMIN_PATH/$EXTENSION_NAME/${CLASS_NAME}Models/BaseModel.php"
        fi

        cat <<EOF >>$ADMIN_PATH/$EXTENSION_NAME/${CLASS_NAME}Models/${CLASS_NAME}Model.php
<?php
/******************************************************************
# $EXTENSION_NAME --- $CLASS_NAME                                 *
*******************************************************************/

namespace ${CLASS_NAME}Models;

use Tygh\Tygh;
use Tygh\Registry;
use Tygh\Settings;
use Tygh\Enum\YesNo;
use ${CLASS_NAME}Models\BaseModel;

class ${CLASS_NAME}Model extends BaseModel
{

    public function __construct()
    {
        parent::__construct();
    }

    /**
     * saveAddonConfiguration
     *
     * @param  mixed \$_data
     * @param  mixed \$lang_code
     * @return void
     */
    public function saveAddonConfiguration(\$_data, \$company_id = null)
    {

        if (!\$setting_id = Settings::instance()->getId('${EXTENSION_NAME}_tpl_data', '')) {

            \$setting_id = Settings::instance()->update(array(
                'name' =>           '${EXTENSION_NAME}_tpl_data',
                'section_id' =>     0,
                'section_tab_id' => 0,
                'type' =>           'A',
                'position' =>       0,
                'is_global' =>      'N',
                'handler' =>        ''
            ));
        }

        Settings::instance()->updateValueById(\$setting_id, serialize(\$_data), \$company_id);
    }

    /**
     * getSettingsData
     *
     * @param  mixed \$company_id
     * @return array
     */
    public function getSettingsData(\$company_id = null)
    {

        static \$cache;
        if (empty(\$cache['settings_' . \$company_id])) {

            \$settings = Settings::instance()->getValue('${EXTENSION_NAME}_tpl_data', '', \$company_id);
            \$settings = unserialize(\$settings);
            if (empty(\$settings)) {
                \$settings = array();
            }
            \$cache['settings_' . \$company_id] = \$settings;
        }
        return \$cache['settings_' . \$company_id];
    }
}

EOF
        if [ -f "$ADMIN_PATH/$EXTENSION_NAME/${CLASS_NAME}Models/${CLASS_NAME}Model.php" ]; then
            print_success "Created:: $ADMIN_PATH/$EXTENSION_NAME/${CLASS_NAME}Models/${CLASS_NAME}Model.php"
        else
            print_error "Failed:: $ADMIN_PATH/$EXTENSION_NAME/${CLASS_NAME}Models/${CLASS_NAME}Model.php"
        fi

        cat <<EOF >>var/langs/en/addons/$EXTENSION_NAME.po
msgid ""
msgstr "Project-Id-Version: tygh\n"
"Content-Type: text/plain; charset=UTF-8\n"
"Language-Team: English\n"
"Language: en_US"

msgctxt "Addons::name::$EXTENSION_NAME"
msgid "$CLASS_NAME"
msgstr "$CLASS_NAME"

msgctxt "Addons::description::$EXTENSION_NAME"
msgid "$CLASS_NAME"
msgstr "$CLASS_NAME""

msgctxt "Languages::$EXTENSION_NAME"
msgid "$CLASS_NAME"
msgstr "$CLASS_NAME"

msgctxt "Languages::$EXTENSION_NAME'.addon_name"
msgid "$CLASS_NAME"
msgstr "$CLASS_NAME"

msgctxt "Languages::$EXTENSION_NAME.well_done"
msgid "Well done"
msgstr "Well done"

msgctxt "Languages::$EXTENSION_NAME.user_guide_content"
msgid "Addon successfully installed <br>[support_link]<br>[user_guide]<br>[addon_name]"
msgstr "Addon successfully installed <br>[support_link]<br>[user_guide]<br>[addon_name]"

EOF

        if [ -f "var/langs/en/addons/$EXTENSION_NAME.po" ]; then
            print_success "Created:: var/langs/en/addons/$EXTENSION_NAME.po"
        else
            print_error "Failed:: var/langs/en/addons/$EXTENSION_NAME.po"
        fi

    else
        print_error "Failed:: $ADMIN_PATH/$EXTENSION_NAME/addons.xml"
    fi

}

# Function to check if Composer is installed
check_composer() {
    if ! command -v composer &>/dev/null; then
        print_error "Composer is not installed or not in PATH."
        exit 1
    fi
}

# install validation library
install_validation_library() {
    check_composer

    composer require code-corner/validation:dev-master
}

# Handle command line arguments
case "$1" in
create-addon)
    shift
    # echo "Enter extension name?: "
    # read name

    if [[ ! "$1" =~ ^[a-zA-Z_]+$ ]]; then
        print_error "Invalid: $1 addon name."
        exit 1
    fi

    # echo "Want to include catalog extension (y): "
    # read both

    # Call function to create extension with provided name
    create_extension "$1" "$2"
    ;;
install-validation-library)
    shift
    install_validation_library
    ;;
delete)
    shift
    prompt_delete_addon "$1"
    ;;
create-addon-zip)
    shift
    prompt_addon_zip "$1" "$2"
    ;;
*)
    print "Usage: opencart.sh {create-addon <name>|install-validation-library|create-addon-zip <addon-name> [-z] <zip>|delete <addon-name>}"
    exit 1
    ;;
esac
