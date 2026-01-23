#!/bin/bash
############################################################################################################
# 
############################################################################################################

# NODE_INSPECTOR_ENABLE=true
# NODE_RESTREAMER_ENABLE=true
# NODE_SOCIALPUSHER_ENABLE=true
# NODE_SUPPRESSOR_ENABLE=true
# NODE_HLS_ENABLE=true
# NODE_HLS_OUTPUT_FORMAT=TS     #(TS,FMP4,SMP4)
# NODE_HLS_DVR_PLAYLIST=true

# NODE_WEBHOOKS_ENABLE=true
# NODE_WEBHOOKS_ENDPOINT="https://test.webhook.app/api/v1/broadcast/webhook"

# NODE_ROUND_TRIP_AUTH_ENABLE=true
# NODE_ROUND_TRIP_AUTH_HOST=round-trip-auth.example.com
# NODE_ROUND_TRIP_AUTH_PORT=443
# NODE_ROUND_TRIP_AUTH_PROTOCOL=https
# NODE_ROUND_TRIP_AUTH_ENDPOINT_VALIDATE="/validateCredentials"
# NODE_ROUND_TRIP_AUTH_ENDPOINT_INVALIDATE="/invalidateCredentials"

RED5_HOME="/usr/local/red5pro"

log_i() {
    log
    printf "\033[0;32m [INFO]  --- %s \033[0m\n" "${@}"
}
log_d() {
    log
    printf "\033[0;33m [INFO]  --- %s \033[0m\n" "${@}"
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

config_node_apps_plugins(){
    log_i "Clean unnecessary apps and plugins"

    ### Streammanager
    if [ -d "$RED5_HOME/webapps/streammanager" ]; then
        rm -r $RED5_HOME/webapps/streammanager
    fi
    ### Template
    if [ -d "$RED5_HOME/webapps/template" ]; then
        rm -r $RED5_HOME/webapps/template
    fi
    ### Videobandwidth
    if [ -d "$RED5_HOME/webapps/videobandwidth" ]; then
        rm -r $RED5_HOME/webapps/videobandwidth
    fi

    ### Inspector
    if [[ "$NODE_INSPECTOR_ENABLE" == "true" ]]; then
        log_i "Red5Pro WEBAPP INSPECTOR - enable"
    else
        log_d "Red5Pro WEBAPP INSPECTOR - disable"
        if [ -d "$RED5_HOME/webapps/inspector" ]; then
            rm -r $RED5_HOME/webapps/inspector
        fi
        if [ -f "$RED5_HOME/plugins/inspector.jar" ]; then
            rm $RED5_HOME/plugins/inspector.jar
        fi
    fi
    ### Red5Pro HLS
    if [[ "$NODE_HLS_ENABLE" == "true" ]]; then
        log_i "Red5Pro HLS - enable. Output format: $NODE_HLS_OUTPUT_FORMAT, DVR playlist: $NODE_HLS_DVR_PLAYLIST"

        hls_output_format='<property name="outputFormat" value="TS"/>'
        hls_output_format_new='<property name="outputFormat" value="'$NODE_HLS_OUTPUT_FORMAT'"/>'

        hls_dvr_playlist='<property name="dvrPlaylist" value="false"/>'
        hls_dvr_playlist_new='<property name="dvrPlaylist" value="'$NODE_HLS_DVR_PLAYLIST'"/>'
        sed -i -e "s|$hls_output_format|$hls_output_format_new|" -e "s|$hls_dvr_playlist|$hls_dvr_playlist_new|" "$RED5_HOME/conf/hlsconfig.xml"
    else
        log_d "Red5Pro HLS - disable"
        if ls $RED5_HOME/plugins/red5pro-mpegts-plugin* >/dev/null 2>&1; then
            rm $RED5_HOME/plugins/red5pro-mpegts-plugin*
        fi
    fi
    if [[ "$NODE_CLOUDSTORAGE_ENABLE" == "true" ]]; then
        log_i "Red5Pro Azure Cloudstorage plugin - enable"
        if [ -z "$NODE_CLOUDSTORAGE_AZURE_STORAGE_ACCOUNT_NAME" ]; then
            log_e "Parameter NODE_CLOUDSTORAGE_AZURE_STORAGE_ACCOUNT_NAME is empty. EXIT."
            exit 1
        fi
        if [ -z "$NODE_CLOUDSTORAGE_AZURE_STORAGE_ACCOUNT_KEY" ]; then
            log_e "Parameter NODE_CLOUDSTORAGE_AZURE_STORAGE_ACCOUNT_KEY is empty. EXIT."
            exit 1
        fi
        if [ -z "$NODE_CLOUDSTORAGE_AZURE_STORAGE_ACCOUNT_CONTAINER_NAME" ]; then
            log_e "Parameter NODE_CLOUDSTORAGE_AZURE_STORAGE_ACCOUNT_CONTAINER_NAME is empty. EXIT."
            exit 1
        fi

        log_i "Config Azure Cloudstorage plugin: $RED5_HOME/conf/cloudstorage-plugin.properties"
        azure_service="#services=com.red5pro.media.storage.azure.AzureUploader,com.red5pro.media.storage.azure.AzureContainerLister"
        azure_service_new="services=com.red5pro.media.storage.azure.AzureUploader,com.red5pro.media.storage.azure.AzureContainerLister"
        max_transcode_min="max.transcode.minutes=.*"
        max_transcode_min_new="max.transcode.minutes=30"

        azure_account_name="azure.account.name=.*"
        azure_account_name_new="azure.account.name=${NODE_CLOUDSTORAGE_AZURE_STORAGE_ACCOUNT_NAME}"
        azure_account_key="azure.account.key=.*"
        azure_account_key_new="azure.account.key=${NODE_CLOUDSTORAGE_AZURE_STORAGE_ACCOUNT_KEY}"
        azure_container_name="azure.container.name=.*"
        azure_container_name_new="azure.container.name=${NODE_CLOUDSTORAGE_AZURE_STORAGE_ACCOUNT_CONTAINER_NAME}"

        stream_dir="streams.dir=.*"
        stream_dir_new="streams.dir=$RED5_HOME/webapps/"

        sed -i -e "s|$azure_service|$azure_service_new|" -e "s|$stream_dir|$stream_dir_new|" -e "s|$max_transcode_min|$max_transcode_min_new|" -e "s|$azure_account_name|$azure_account_name_new|" -e "s|$azure_account_key|$azure_account_key_new|" -e "s|$azure_container_name|$azure_container_name_new|" "$RED5_HOME/conf/cloudstorage-plugin.properties"

        if [[ "$NODE_CLOUDSTORAGE_POSTPROCESSOR_ENABLE" == "true" ]]; then
            log_i "Config Azure Cloudstorage plugin - PostProcessor to FLV: $RED5_HOME/conf/red5-common.xml"

            STR1='<property name="writerPostProcessors">\n<set>\n<value>com.red5pro.media.processor.AzureUploaderPostProcessor</value>\n</set>\n</property>'
            sed -i "/Writer post-process example/i $STR1" "$RED5_HOME/conf/red5-common.xml"
        fi

        log_i "Config Azure Cloudstorage plugin - Live app AzureFilenameGenerator in: $RED5_HOME/webapps/live/WEB-INF/red5-web.xml ..."

        local filenamegenerator='<bean id="streamFilenameGenerator" class="com.red5pro.media.storage.azure.AzureFilenameGenerator"/>'
        local filenamegenerator_new='-->\n<bean id="streamFilenameGenerator" class="com.red5pro.media.storage.azure.AzureFilenameGenerator"/>\n<!--'
        sed -i -e "s|$filenamegenerator|$filenamegenerator_new|" "$RED5_HOME/webapps/live/WEB-INF/red5-web.xml"
    else
        log_d "Red5Pro Azure Cloudstorage plugin - disable"
    fi
    ### Red5Pro Stream Auto Record
    if [[ "$NODE_STREAM_AUTO_RECORD_ENABLE" == "true" ]]; then
        log_i "Red5Pro Broadcas Stream Auto Record - enable"

        stream_auto_record="broadcaststream.auto.record=.*"
        stream_auto_record_new="broadcaststream.auto.record=true"
        sed -i -e "s|$stream_auto_record|$stream_auto_record_new|" "$RED5_HOME/conf/red5.properties"
    else
        log_d "Red5Pro Broadcas Stream Auto Record - disable"
    fi
    ### Red5Pro Restreamer
    if [[ "$NODE_RESTREAMER_ENABLE" == "true" ]]; then
        log_i "Red5Pro Restreamer - enable"
        
        # In new version of Red5Pro 13.0.0 and above, it is enabled by default in the red5-web.xml
        # log_i "Enable Restreamer Servlet in $RED5_HOME/webapps/live/WEB-INF/web.xml"
        # restreamer_servlet="<servlet>\n<servlet-name>RestreamerServlet</servlet-name>\n<servlet-class>com.red5pro.restreamer.servlet.RestreamerServlet</servlet-class>\n</servlet>\n<servlet-mapping>\n<servlet-name>RestreamerServlet</servlet-name>\n<url-pattern>/restream</url-pattern>\n</servlet-mapping>"
        # sed -i "/<\/web-app>/i $restreamer_servlet"  "$RED5_HOME/webapps/live/WEB-INF/web.xml"

        log_i "Set enable.srtingest=true in $RED5_HOME/conf/restreamer-plugin.properties"
        enable_srtingest="enable.srtingest=.*"
        enable_srtingest_new="enable.srtingest=true"
        sed -i -e "s|$enable_srtingest|$enable_srtingest_new|" "$RED5_HOME/conf/restreamer-plugin.properties"
    else
        log_d "Red5Pro Restreamer - disable"
        if ls $RED5_HOME/plugins/red5pro-restreamer-plugin* >/dev/null 2>&1; then
            rm $RED5_HOME/plugins/red5pro-restreamer-plugin*
        fi
    fi
    ### Red5Pro Socialpusher
    if [[ "$NODE_SOCIALPUSHER_ENABLE" == "true" ]]; then
        log_i "Red5Pro Socialpusher - enable"
        log_i "HERE need to add Socialpusher configuration!!!"
    else
        log_d "Red5Pro Socialpusher - disable"
        if ls $RED5_HOME/plugins/red5pro-socialpusher-plugin* >/dev/null 2>&1; then
            rm $RED5_HOME/plugins/red5pro-socialpusher-plugin*
        fi
    fi
    ### Red5Pro Client-suppressor
    if [[ "$NODE_SUPPRESSOR_ENABLE" == "true" ]]; then
        log_i "Red5Pro client-suppressor - enable"
        log_i "HERE need to add Client-suppressor configuration!!!"
    else
        log_d "Red5Pro client-suppressor - disable"
        if ls $RED5_HOME/plugins/red5pro-client-suppressor* >/dev/null 2>&1; then
            rm $RED5_HOME/plugins/red5pro-client-suppressor*
        fi
    fi
    ### Red5Pro Webhooks
    if [[ "$NODE_WEBHOOKS_ENABLE" == "true" ]]; then
        log_i "Red5Pro Webhooks - enable"
        if [ -z "$NODE_WEBHOOKS_ENDPOINT" ]; then
            log_e "Parameter NODE_WEBHOOKS_ENDPOINT is empty. EXIT."
            exit 1
        fi
        echo "" >> $RED5_HOME/webapps/live/WEB-INF/red5-web.properties
        echo "webhooks.endpoint=$NODE_WEBHOOKS_ENDPOINT" >> $RED5_HOME/webapps/live/WEB-INF/red5-web.properties
    fi
    ### Red5Pro Round-trip-auth
    if [[ "$NODE_ROUND_TRIP_AUTH_ENABLE" == "true" ]]; then
        log_i "Red5Pro Round-trip-auth - enable"
        if [ -z "$NODE_ROUND_TRIP_AUTH_HOST" ]; then
            log_e "Parameter NODE_ROUND_TRIP_AUTH_HOST is empty. EXIT."
            exit 1
        fi
        if [ -z "$NODE_ROUND_TRIP_AUTH_PORT" ]; then
            log_e "Parameter NODE_ROUND_TRIP_AUTH_PORT is empty. EXIT."
            exit 1
        fi
        if [ -z "$NODE_ROUND_TRIP_AUTH_PROTOCOL" ]; then
            log_e "Parameter NODE_ROUND_TRIP_AUTH_PROTOCOL is empty. EXIT."
            exit 1
        fi
        if [ -z "$NODE_ROUND_TRIP_AUTH_ENDPOINT_VALIDATE" ]; then
            log_e "Parameter NODE_ROUND_TRIP_AUTH_ENDPOINT_VALIDATE is empty. EXIT."
            exit 1
        fi
        if [ -z "$NODE_ROUND_TRIP_AUTH_ENDPOINT_INVALIDATE" ]; then
            log_e "Parameter NODE_ROUND_TRIP_AUTH_ENDPOINT_INVALIDATE is empty. EXIT."
            exit 1
        fi

        log_i "Configuration Live App red5-web.properties with MOCK Round trip server ..."
        {
            echo ""
            echo "server.validateCredentialsEndPoint=${NODE_ROUND_TRIP_AUTH_ENDPOINT_VALIDATE}"
            echo "server.invalidateCredentialsEndPoint=${NODE_ROUND_TRIP_AUTH_ENDPOINT_INVALIDATE}"
            echo "server.host=${NODE_ROUND_TRIP_AUTH_HOST}"
            echo "server.port=${NODE_ROUND_TRIP_AUTH_PORT}"
            echo "server.protocol=${NODE_ROUND_TRIP_AUTH_PROTOCOL}://"
        } >> $RED5_HOME/webapps/live/WEB-INF/red5-web.properties

        log_i "Uncomment Round trip auth in the Live app: red5-web.xml"
        # Delete line with <!-- after pattern <!-- uncomment below for Round Trip Authentication-->
        sed -i '/uncomment below for Round Trip Authentication/{n;d;}' "$RED5_HOME/webapps/live/WEB-INF/red5-web.xml"
        # Delete line with --> before pattern <!-- uncomment above for Round Trip Authentication-->
        sed -i '$!N;/\n.*uncomment above for Round Trip Authentication/!P;D' "$RED5_HOME/webapps/live/WEB-INF/red5-web.xml"
    else
        log_d "Red5Pro Round-trip-auth - disable"
    fi
}

config_node_apps_plugins