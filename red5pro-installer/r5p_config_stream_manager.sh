#!/bin/bash
############################################################################################################
# Red5 Pro Stream Manager Configuration Script
############################################################################################################

# TERRA_HOST
# TERRA_API_TOKEN
# DB_HOST
# DB_PORT
# DB_USER
# DB_PASSWORD
# NODE_PREFIX_NAME
# NODE_CLUSTER_KEY
# NODE_API_KEY
# SM_API_KEY

RED5_HOME="/usr/local/red5pro"
CURRENT_DIRECTORY=$(pwd)

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

config_sm_properties_azure(){
    log_i "Start configuration Stream Manager properties for Microsoft Azure"
    
    if [ -z "$AZURE_RESOURCE_GROUP" ]; then
        log_w "Variable AZURE_RESOURCE_GROUP is empty."
        var_error=1
    fi
    if [ -z "$AZURE_REGION" ]; then
        log_w "Variable AZURE_REGION is empty."
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
    if [[ "$var_error" == "1" ]]; then
        log_e "One or more variables are empty. EXIT!"
        exit 1
    fi
    
    local azure_resource_group_pattern='#az.resourceGroupName=.*'
    local azure_resource_group_pattern_new="az.resourceGroupName=${AZURE_RESOURCE_GROUP}"

    local azure_region='#az.resourceGroupRegion=.*'
    local azure_region_new="az.resourceGroupRegion=${AZURE_REGION}"

    local azure_prefix_name='#az.resourceNamePrefix=.*'
    local azure_prefix_name_new="az.resourceNamePrefix=${AZURE_PREFIX_NAME}"

    local azure_client_id='#az.clientId=.*'
    local azure_client_id_new="az.clientId=${AZURE_CLIENT_ID}"

    local azure_client_secret='#az.clientKey=.*'
    local azure_client_secret_new="az.clientKey=${AZURE_CLIENT_SECRET}"

    local azure_tenant_id='#az.tenantId=.*'
    local azure_tenant_id_new="az.tenantId=${AZURE_TENANT_ID}"

    local azure_subscription_id='#az.subscriptionId=.*'
    local azure_subscription_id_new="az.subscriptionId=${AZURE_SUBSCRIPTION_ID}"

    local azure_virtual_machine_password='#az.vmPassword=.*'
    local azure_virtual_machine_password_new="az.vmPassword=${AZURE_VIRTUAL_MACHINE_PASSWORD}"

    local azure_vm_name='#az.vmUsername=.*'
    local azure_vm_name_new='az.vmUsername=ubuntu'

    local azure_default_subnet_name='#az.defaultSubnetName=.*'
    local azure_default_subnet_name_new='az.defaultSubnetName=default'

    local azure_operation_timeout='#az.operationTimeoutMilliseconds=.*'
    local azure_operation_timeout_new='az.operationTimeoutMilliseconds=120000'

    local azure_quick_operation_response='#az.quickOperationResponse=.*'
    local azure_quick_operation_response_new='az.quickOperationResponse=true'

    local azure_quick_operation_response_delay='#az.quickResponseCheckInitialDelay=.*'
    local azure_quick_operation_response_delay_new='az.quickResponseCheckInitialDelay=20000'

    local azure_api_log_level='#az.apiLogLevel=.*'
    local azure_api_log_level_new='az.apiLogLevel=BASIC'

    
    sed -i -e "s|$azure_resource_group_pattern|$azure_resource_group_pattern_new|" -e "s|$azure_region|$azure_region_new|" -e "s|$azure_prefix_name|$azure_prefix_name_new|" -e "s|$azure_client_id|$azure_client_id_new|" -e "s|$azure_client_secret|$azure_client_secret_new|" -e "s|$azure_tenant_id|$azure_tenant_id_new|" -e "s|$azure_subscription_id|$azure_subscription_id_new|" -e "s|$azure_virtual_machine_password|$azure_virtual_machine_password_new|" -e "s|$azure_vm_name|$azure_vm_name_new|" -e "s|$azure_default_subnet_name|$azure_default_subnet_name_new|" -e "s|$azure_operation_timeout|$azure_operation_timeout_new|" -e "s|$azure_quick_operation_response|$azure_quick_operation_response_new|" -e "s|$azure_quick_operation_response_delay|$azure_quick_operation_response_delay_new|" -e "s|$azure_api_log_level|$azure_api_log_level_new|" "$RED5_HOME/webapps/streammanager/WEB-INF/red5-web.properties"
    
}

config_sm_properties_main(){
    log_i "Start configuration Stream Manager properties - MAIN"

    if [ -z "$DB_HOST" ]; then
        log_w "Variable DB_HOST is empty."
        var_error=1
    fi
    if [ -z "$DB_PORT" ]; then
        log_w "Variable DB_PORT is empty."
        var_error=1
    fi
    if [ -z "$DB_USER" ]; then
        log_w "Variable DB_USER is empty."
        var_error=1
    fi
    if [ -z "$DB_PASSWORD" ]; then
        log_w "Variable DB_PASSWORD is empty."
        var_error=1
    fi
    if [ -z "$NODE_PREFIX_NAME" ]; then
        log_w "Variable NODE_PREFIX_NAME is empty."
        var_error=1
    fi
    if [ -z "$NODE_CLUSTER_KEY" ]; then
        log_w "Variable NODE_CLUSTER_KEY is empty."
        var_error=1
    fi
    if [ -z "$NODE_API_KEY" ]; then
        log_w "Variable NODE_API_KEY is empty."
        var_error=1
    fi
    if [ -z "$SM_API_KEY" ]; then
        log_w "Variable SM_API_KEY is empty."
        var_error=1
    fi

    if [[ "$var_error" == "1" ]]; then
        log_e "One or more variables are empty. EXIT!"

    fi

    local db_host_pattern='config.dbHost={host}'
    local db_host_new="config.dbHost=${DB_HOST}"

    local db_port_pattern='config.dbPort=3306'
    local db_port_new="config.dbPort=${DB_PORT}"

    local db_user_pattern='config.dbUser={username}'
    local db_user_new="config.dbUser=${DB_USER}"

    local db_pass_pattern='config.dbPass={password}'
    local db_pass_new="config.dbPass=${DB_PASSWORD}"

    local node_prefix_pattern='instancecontroller.instanceNamePrefix={unique-value}'
    local node_prefix_new="instancecontroller.instanceNamePrefix=${NODE_PREFIX_NAME}"

    local node_cluster_password_pattern='cluster.password=changeme'
    local node_cluster_password_new="cluster.password=${NODE_CLUSTER_KEY}"

    local node_api_token_pattern='serverapi.accessToken={node api security token}'
    local node_api_token_new="serverapi.accessToken=${NODE_API_KEY}"

    local sm_rest_token_pattern='rest.administratorToken='
    local sm_rest_token_new="rest.administratorToken=${SM_API_KEY}"

    local sm_proxy_enabled_pattern='proxy.enabled=false'
    local sm_proxy_enabled_new='proxy.enabled=true'

    sudo sed -i -e "s|$db_host_pattern|$db_host_new|" -e "s|$db_port_pattern|$db_port_new|" -e "s|$db_user_pattern|$db_user_new|" -e "s|$db_pass_pattern|$db_pass_new|" -e "s|$node_prefix_pattern|$node_prefix_new|" -e "s|$node_cluster_password_pattern|$node_cluster_password_new|" -e "s|$node_api_token_pattern|$node_api_token_new|" -e "s|$sm_rest_token_pattern|$sm_rest_token_new|" -e "s|$sm_proxy_enabled_pattern|$sm_proxy_enabled_new|" "$RED5_HOME/webapps/streammanager/WEB-INF/red5-web.properties"
}


install_sm(){
    log_i "Delete unnecessary apps..."

    if [ -d "$RED5_HOME/webapps/api" ]; then
        rm -r $RED5_HOME/webapps/api
    fi
    if [ -d "$RED5_HOME/webapps/inspector" ]; then
        rm -r $RED5_HOME/webapps/inspector
    fi
    if [ -d "$RED5_HOME/webapps/template" ]; then
        rm -r $RED5_HOME/webapps/template
    fi
    if [ -d "$RED5_HOME/webapps/videobandwidth" ]; then
        rm -r $RED5_HOME/webapps/videobandwidth
    fi
    if [ -f "$RED5_HOME/conf/autoscale.xml" ]; then
        rm $RED5_HOME/conf/autoscale.xml
    fi
    if [ -f "$RED5_HOME/plugins/inspector.jar" ]; then
        rm $RED5_HOME/plugins/inspector.jar
    fi
    if ls $RED5_HOME/plugins/red5pro-autoscale-plugin-* >/dev/null 2>&1; then
        rm $RED5_HOME/plugins/red5pro-autoscale-plugin-*
    fi
    if ls $RED5_HOME/plugins/red5pro-webrtc-plugin-* >/dev/null 2>&1; then
        rm $RED5_HOME/plugins/red5pro-webrtc-plugin-*
    fi
    if ls $RED5_HOME/plugins/red5pro-mpegts-plugin* >/dev/null 2>&1; then
        rm $RED5_HOME/plugins/red5pro-mpegts-plugin*
    fi
    if ls $RED5_HOME/plugins/red5pro-restreamer-plugin* >/dev/null 2>&1; then
        rm $RED5_HOME/plugins/red5pro-restreamer-plugin*
    fi
    if ls $RED5_HOME/plugins/red5pro-socialpusher-plugin* >/dev/null 2>&1; then
        rm $RED5_HOME/plugins/red5pro-socialpusher-plugin*
    fi
    if ls $RED5_HOME/plugins/red5pro-client-suppressor* >/dev/null 2>&1; then
        rm $RED5_HOME/plugins/red5pro-client-suppressor*
    fi
    
    if ls $CURRENT_DIRECTORY/*-cloud-controller-* >/dev/null 2>&1; then
        if cp $CURRENT_DIRECTORY/*-cloud-controller-* $RED5_HOME/webapps/streammanager/WEB-INF/lib/; then 
            log_i "Copy Stream Manager cloud controller - DONE :)"
        else
            log_e "Copy Stream Manager cloud controller - FAIL :("
            exit 1
        fi
    fi
}

config_sm_applicationContext(){
    log_i "Set terraform-cloud-controller in $RED5_HOME/webapps/streammanager/WEB-INF/applicationContext.xml"
    
    local def_controller='<!-- Default CONTROLLER -->'
    local def_controller_new='<!-- Disabled: Default CONTROLLER --> <!--'

    local azure_controller='<!-- AWS CONTROLLER -->'
    local azure_controller_new='--> <!-- AWS CONTROLLER -->'

    local azure_controller_in='<!-- <bean id="apiBridge" class="com.red5pro.services.cloud.microsoft.component.AzureComputeController"'
    local azure_controller_in_new='<bean id="apiBridge" class="com.red5pro.services.cloud.microsoft.component.AzureComputeController"'

    local azure_controller_out='<property name="apiLogLevel" value="${az.apiLogLevel}"/> </bean> -->'
    local azure_controller_out_new='<property name="apiLogLevel" value="${az.apiLogLevel}"/> </bean>'

    sed -i -e "s|$def_controller|$def_controller_new|" -e "s|$azure_controller|$azure_controller_new|" -e "s|$azure_controller_in|$azure_controller_in_new|" -e "s|$azure_controller_out|$azure_controller_out_new|" "$RED5_HOME/webapps/streammanager/WEB-INF/applicationContext.xml"
}

config_sm_cors(){
    log_i "Set CORS * in $RED5_HOME/webapps/streammanager/WEB-INF/web.xml"

    local STR1="<filter>\n<filter-name>CorsFilter</filter-name>\n<filter-class>org.apache.catalina.filters.CorsFilter</filter-class>\n<init-param>\n<param-name>cors.allowed.origins</param-name>\n<param-value>*</param-value>\n</init-param>\n<init-param>\n<param-name>cors.exposed.headers</param-name>\n<param-value>Access-Control-Allow-Origin</param-value>\n</init-param>\n<init-param>\n<param-name>cors.allowed.methods</param-name>\n<param-value>GET, POST, PUT, DELETE</param-value>\n</init-param>\n<async-supported>true</async-supported>\n</filter>"
    local STR2="\n<filter-mapping>\n<filter-name>CorsFilter</filter-name>\n<url-pattern>/api/*</url-pattern>\n</filter-mapping>"
    
    sed -i "/<\/web-app>/i $STR1 $STR2" "$RED5_HOME/webapps/streammanager/WEB-INF/web.xml"
}

config_whip_whep(){
    log_i "Start Whip/Whep configuration"

    live_web_config="$RED5_HOME/webapps/live/WEB-INF/web.xml"

    if grep "com.red5pro.whip.servlet.WhipEndpoint" $live_web_config &> /dev/null
    then
        log_i "Change from: com.red5pro.whip.servlet.WhipEndpoint to com.red5pro.whip.servlet.WHProxy"
        local servlet_whipendpoint='com.red5pro.whip.servlet.WhipEndpoint'
        local servlet_whipendpoint_new="com.red5pro.whip.servlet.WHProxy"
        sudo sed -i -e "s|$servlet_whipendpoint|$servlet_whipendpoint_new|" "$live_web_config"
    fi

    if grep "com.red5pro.whip.servlet.WhepEndpoint" $live_web_config &> /dev/null
    then
        log_i "Changed from: com.red5pro.whip.servlet.WhepEndpoint to com.red5pro.whip.servlet.WHProxy"
        local servlet_whipendpoint='com.red5pro.whip.servlet.WhepEndpoint'
        local servlet_whipendpoint_new="com.red5pro.whip.servlet.WHProxy"
        sudo sed -i -e "s|$servlet_whipendpoint|$servlet_whipendpoint_new|" "$live_web_config"
    fi
}

config_mysql(){
    log_i "Check MySQL Database cluster configuration.."
    RESULT=$(mysqlshow -h $DB_HOST -P $DB_PORT -u $DB_USER -p$DB_PASSWORD | grep -o cluster)
    if [ "$RESULT" != "cluster" ]; then
        log_i "Start MySQL DB config ..."
        log_i "Creating DB cluster ..."
        mysql -h $DB_HOST -P $DB_PORT -u $DB_USER -p$DB_PASSWORD -e "CREATE DATABASE cluster;"
        log_i "Importing sql script to DB cluster ..."
        mysql -h $DB_HOST -P $DB_PORT -u $DB_USER -p${DB_PASSWORD} cluster < $RED5_HOME/webapps/streammanager/WEB-INF/sql/cluster.sql
    else 
        log_i "Database cluster was configured by another StreamManager. Skip."
    fi
}

install_sm
config_sm_applicationContext
config_sm_cors
config_whip_whep
config_sm_properties_main
config_sm_properties_azure
config_mysql

