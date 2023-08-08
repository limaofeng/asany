#!/usr/bin/env bash
# Copyright © 2023 OpenIM open source community. All rights reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

OPENIM_ROOT=$(dirname "${BASH_SOURCE[0]}")/..
SCRIPTS_ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

source $OPENIM_ROOT/scripts/style_info.cfg
source $OPENIM_ROOT/scripts/path_info.cfg
source $OPENIM_ROOT/scripts/function.sh

#service filename
service_filename=(
 open_im_chat_api
 open_im_admin_api
  #rpc
  open_im_admin
  open_im_chat
)

#service config port name
service_port_name=(
openImChatApiPort
openImAdminApiPort
  #api port name
  openImAdminPort
  openImChatPort
)

service_prometheus_port_name=(

)

cd $SCRIPTS_ROOT

for ((i = 0; i < ${#service_filename[*]}; i++)); do
  #Check whether the service exists
  service_name="ps -aux |grep -w ${service_filename[$i]} |grep -v grep"
  count="${service_name}| wc -l"

  if [ $(eval ${count}) -gt 0 ]; then
    pid="${service_name}| awk '{print \$2}'"
    echo  "${service_filename[$i]} service has been started,pid:$(eval $pid)"
    echo  "killing the service ${service_filename[$i]} pid:$(eval $pid)"
    #kill the service that existed
    kill -9 $(eval $pid)
    sleep 0.5
  fi
  cd $OPENIM_ROOT/bin
  #Get the rpc port in the configuration file
  portList=$(cat $config_path | grep ${service_port_name[$i]} | awk -F '[:]' '{print $NF}')
  list_to_string ${portList}
  service_ports=($ports_array)


  #Start related rpc services based on the number of ports
  for ((j = 0; j < ${#service_ports[*]}; j++)); do
    #Start the service in the background
    cmd="./${service_filename[$i]} -port ${service_ports[$j]} --config_folder_path ${config_path}"
    if [ $i -eq 0 -o $i -eq 1 ]; then
      cmd="./${service_filename[$i]} -port ${service_ports[$j]} --config_folder_path ${config_path}"
    fi
    echo $cmd
    nohup $cmd >>../logs/openIM.log 2>&1 &
    sleep 1
#    pid="netstat -ntlp|grep $j |awk '{printf \$7}'|cut -d/ -f1"
#    echo -e "${GREEN_PREFIX}${service_filename[$i]} start success,port number:${service_ports[$j]} pid:$(eval $pid)$COLOR_SUFFIX"
  done
done
