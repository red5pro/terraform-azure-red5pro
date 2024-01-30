#!/bin/bash
##############################################################################################################
# Install and configure Terraform service for DO
# Before start this script you need copy terraform-service-build.zip into the same folder with this script!!!
##############################################################################################################

# TERRA_API_KEY="abc123"
# TERRA_PARALLELISM="20"
# AZURE_RESOURCE_GROUP=""
# AZURE_PREFIX_NAME=""
# AZURE_CLIENT_ID=""
# AZURE_CLIENT_SECRET=""
# AZURE_TENANT_ID=""
# AZURE_SUBSCRIPTION_ID=""
# AZURE_VIRTUAL_MACHINE_PASSWORD=""
# DB_HOST="test.com"
# DB_PORT="25060"
# DB_USER="smuser"
# DB_PASSWORD="abc123"

TERRA_FOLDER="/usr/local/red5service"
CURRENT_DIRECTORY=$(pwd)
PACKAGES=(default-jre unzip ntp)

log_i() {
    log
    printf "\033[0;32m [INFO]  --- %s \033[0m\n" "${@}"
}
log_w() {
    log
    printf "\033[0;35m [WARN] --- %s \033[0m\n" "${@}"
}
log_e() {
    log
    printf "\033[0;31m [ERROR]  --- %s \033[0m\n" "${@}"
}
log() {
    echo -n "[$(date '+%Y-%m-%d %H:%M:%S')]"
}

check_terraform_variables(){
    log_i "Check TERRAFORM variables..."
    
    if [ -z "$TERRA_API_KEY" ]; then
        log_w "Variable TERRA_API_KEY is empty."
        var_error=1
    fi
    if [ -z "$TERRA_PARALLELISM" ]; then
        log_w "Variable TERRA_PARALLELISM is empty."
        var_error=1
    fi
    if [ -z "$AZURE_RESOURCE_GROUP" ]; then
        log_w "Variable AZURE_RESOURCE_GROUP is empty."
        var_error=1
    fi
    if [ -z "$AZURE_PREFIX_NAME" ]; then
        log_w "Variable AZURE_PREFIX_NAME is empty."
        var_error=1
    fi
    if [ -z "$AZURE_CLIENT_ID" ]; then
        log_w "Variable AZURE_CLIENT_ID is empty."
        var_error=1
    fi
    if [ -z "$AZURE_CLIENT_SECRET" ]; then
        log_w "Variable AZURE_CLIENT_SECRET is empty."
        var_error=1
    fi
    if [ -z "$AZURE_TENANT_ID" ]; then
        log_w "Variable AZURE_TENANT_ID is empty."
        var_error=1
    fi
    if [ -z "$AZURE_SUBSCRIPTION_ID" ]; then
        log_w "Variable AZURE_SUBSCRIPTION_ID is empty."
        var_error=1
    fi
    if [ -z "$AZURE_VIRTUAL_MACHINE_PASSWORD" ]; then
        log_w "Variable AZURE_VIRTUAL_MACHINE_PASSWORD is empty."
        var_error=1
    fi
    if [ -z "$DB_HOST" ]; then
        log_w "Variable DB_HOST is empty."
        var_error=1
    fi
    if [ -z "$DB_PORT" ]; then
        log_w "Variable DB_PORT is empty."
        var_error=1
    fi
    if [ -z "$DB_USER" ]; then
        log_w "Variable DB_PORT is empty."
        var_error=1
    fi
    if [ -z "$DB_PASSWORD" ]; then
        log_w "Variable DB_PASSWORD is empty."
        var_error=1
    fi
    if [[ "$var_error" == "1" ]]; then
        log_e "One or more variables are empty. EXIT!"
        exit 1
    fi
}

install_pkg(){
    
    for i in {1..5};
    do
        
        local install_issuse=0;
        apt-get -y update --fix-missing &> /dev/null
        
        for index in ${!PACKAGES[*]}
        do
            log_i "Install utility ${PACKAGES[$index]}"
            apt-get install -y ${PACKAGES[$index]} &> /dev/null
        done
        
        for index in ${!PACKAGES[*]}
        do
            PKG_OK=$(dpkg-query -W --showformat='${Status}\n' ${PACKAGES[$index]}|grep "install ok installed")
            if [ -z "$PKG_OK" ]; then
                log_i "${PACKAGES[$index]} utility didn't install, didn't find MIRROR !!! "
                install_issuse=$(($install_issuse+1));
            else
                log_i "${PACKAGES[$index]} utility installed"
            fi
        done
        
        if [ $install_issuse -eq 0 ]; then
            break
        fi
        if [ $i -ge 5 ]; then
            log_e "Something wrong with packages installation!!! Exit."
            exit 1
        fi
        sleep 20
    done
}

install_terraform_service(){
    log_i "Install TERRAFORM SERVICE"
    
    TERRA_RCHIVE=$(ls $CURRENT_DIRECTORY/terraform-service*.zip | xargs -n 1 basename);
    
    if [ ! -f "$TERRA_RCHIVE" ]; then
        log_e "Terraform service archive was not found: $TERRA_RCHIVE. EXIT..."
        exit 1
    fi
    
    unzip -q "$CURRENT_DIRECTORY/$TERRA_RCHIVE" -d /usr/local/
    
    rm $TERRA_FOLDER/*_do*.tf
    rm $TERRA_FOLDER/*_linode*.tf
    rm $TERRA_FOLDER/*_vsphere*.tf
    rm -rf $TERRA_FOLDER/cloud_controller_oracle/

    cp $TERRA_FOLDER/red5proterraform.service /lib/systemd/system/
    chmod +x $TERRA_FOLDER/red5terra.sh $TERRA_FOLDER/terraform
    chmod 644 /lib/systemd/system/red5proterraform.service
    systemctl daemon-reload
    systemctl enable red5proterraform.service
}

config_terraform_service(){
    log_i "TERRAFORM SERVICE CONFIGURATION"

    local terraform_api_key_pattern='api.accessToken=.*'
    local terraform_api_key_new="api.accessToken=${TERRA_API_KEY}"
    
    local terra_parallelism_pattern='terra.parallelism=.*'
    local terra_parallelism_new="terra.parallelism=${TERRA_PARALLELISM}"

    local azure_resource_group_pattern='# cloud.az_resource_group_name=.*'
    local azure_resource_group_pattern_new="cloud.az_resource_group_name=${AZURE_RESOURCE_GROUP}"

    local azure_prefix_name='# cloud.az_resource_prefix_name=.*'
    local azure_prefix_name_new="cloud.az_resource_prefix_name=${AZURE_PREFIX_NAME}"

    local azure_client_id='# cloud.az_client_id=.*'
    local azure_client_id_new="cloud.az_client_id=${AZURE_CLIENT_ID}"

    local azure_client_secret='# cloud.az_client_secret=.*'
    local azure_client_secret_new="cloud.az_client_secret=${AZURE_CLIENT_SECRET}"

    local azure_tenant_id='# cloud.az_tenant_id=.*'
    local azure_tenant_id_new="cloud.az_tenant_id=${AZURE_TENANT_ID}"

    local azure_subscription_id='# cloud.az_subscription_id=.*'
    local azure_subscription_id_new="cloud.az_subscription_id=${AZURE_SUBSCRIPTION_ID}"

    local azure_virtual_machine_password='# cloud.az_ssh_user_password=.*'
    local azure_virtual_machine_password_new="cloud.az_ssh_user_password=${AZURE_VIRTUAL_MACHINE_PASSWORD}"

    local azure_virtual_machine_username='# cloud.az_ssh_user_name=.*'
    local azure_virtual_machine_username_new='cloud.az_ssh_user_name=ubuntu'
    
    local db_host_pattern='config.dbHost=.*'
    local db_host_new="config.dbHost=${DB_HOST}"
    
    local db_port_pattern='config.dbPort=.*'
    local db_port_new="config.dbPort=${DB_PORT}"
    
    local db_user_pattern='config.dbUser=.*'
    local db_user_new="config.dbUser=${DB_USER}"
    
    local db_password_pattern='config.dbPass=.*'
    local db_password_new="config.dbPass=${DB_PASSWORD}"

    local do_api_token_pattern='cloud.do_api_token=.*'
    local do_api_token_pattern_new='#cloud.do_api_token=.*'

    local do_ssh_key_pattern='cloud.do_ssh_key_name=.*'
    local do_ssh_key_pattern_new='#cloud.do_ssh_key_name=.*'
    
    sed -i -e "s|$terraform_api_key_pattern|$terraform_api_key_new|" -e "s|$terra_parallelism_pattern|$terra_parallelism_new|" -e "s|$azure_resource_group_pattern|$azure_resource_group_pattern_new|" -e "s|$azure_prefix_name|$azure_prefix_name_new|" -e "s|$azure_client_id|$azure_client_id_new|" -e "s|$azure_client_secret|$azure_client_secret_new|" -e "s|$azure_tenant_id|$azure_tenant_id_new|" -e "s|$azure_subscription_id|$azure_subscription_id_new|" -e "s|$azure_virtual_machine_password|$azure_virtual_machine_password_new|" -e "s|$azure_virtual_machine_username|$azure_virtual_machine_username_new|" -e "s|$db_host_pattern|$db_host_new|" -e "s|$db_port_pattern|$db_port_new|" -e "s|$db_user_pattern|$db_user_new|" -e "s|$db_password_pattern|$db_password_new|" -e "s|$do_api_token_pattern|$do_api_token_pattern_new|" -e "s|$do_ssh_key_pattern|$do_ssh_key_pattern_new|" "$TERRA_FOLDER/application.properties"
}

start_terraform_service(){
    log_i "STARTING TERRAFORM SERVICE"
    systemctl restart red5proterraform.service
    
    if [ "0" -eq $? ]; then
        log_i "TERRAFORM SERVICE started!"
    else
        log_e "TERRAFORM SERVICE didn't start!!!"
        exit 1
    fi
    
}

if [[ "$TF_SVC_ENABLE" == true ]]; then
    log_i "TF_SVC_ENABLE is set to true, Installing Red5 Pro Terraform Service..."
    export LC_ALL="en_US.UTF-8"
    export LC_CTYPE="en_US.UTF-8"

    check_terraform_variables
    install_pkg
    install_terraform_service
    config_terraform_service
    start_terraform_service
else
    log_i "SKIP Red5 Pro Terraform Service installation."
fi