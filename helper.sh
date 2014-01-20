#!/bin/bash
# Created: 2013-12-18
# Author: Eugene Kirdzei
# Description: Universal script for updates

# Define some colors first:
red='\033[0;31m'
RED='\033[1;31m'
blue='\033[0;34m'
BLUE='\033[1;34m'
cayan='\033[0;36m'
CAYAN='\033[1;36m'
green='\033[0;32m'
GREEN='\033[1;32m'
NC='\033[0m' # No Color
# --> Nice. 

if [ -f config.cfg ]; then
    . config.cfg
  else
  if [ -r helper/config.cfg ]; then
    . helper/config.cfg
  else
    echo -e "${RED}Конфигурационный файл не найден!${NC}"
    exit 0
  fi
fi

check_folder config

clear

function _exit() {
clear
echo -e "${RED}Hasta la vista, baby${NC}"
}
trap _exit 0

echo "Deployement script"

function operations() {
#clear
echo
echo -e "${RED}Please choose an action?
------------------------------
${GREEN}1. Deploy
${RED}=========
${GREEN}
93. Run queue
94. Stop all queues
95. Swith all projects to master
96. Change permissions
97. Check disc space
98. Clear screen
99. Exit
${RED}------------------------------
${BLUE}Press Ctrl+C or type 'exit' for exit${NC}"

read -p '=> ' op

KEY=$(date +%y-%m-%d_%H-%M)

case $op in
    "1" )
        echo "What project to deploy?"
        read -r -p '<l> for list=> ' action

        case $action in
            "l" )
            projects_list
            read -p '=> ' action
            ;;&
            * )
              if [ -r $script_path/config/$action.cfg ]; then
                #Load config
                . $script_path/config/$action.cfg

                read -r -p "Which branch? [master] (<l> for list) => " branch

                case $branch in
                    "l" )
                        cd $project_path
                        git ls-remote --heads origin  | sed 's?.*refs/heads/??'
                        read -p '=> ' branch
                    ;;&
                    * )
                        if [ "$branch" == '' ]; then
                            branch='master'
                        fi

                        cd $project_path && git fetch -p && git checkout -f $branch

                        read -r -p "Update composer? [y/N] => " response
                        response=${response,,}
                        if [[ $response =~ ^(yes|y)$ ]]; then
                            if hash composer 2> /dev/null; then
                              composer --no-dev update
                            else
                              php composer.phar --no-dev update
                            fi
                        fi
                    ;;
                esac
              else
                    #pwd
                  echo -e "${RED}Конфигурационный файл для проекта $action не найден!${NC}"
              fi
            ;;
        esac
        cd $script_path
    ;;
    "93" )
	if [ -f $script_path/config/$queue_project.cfg ] 
	then
	    . $script_path/config/$queue_project.cfg
	else
	    echo "Config file for projects libb2b or b2b-acp not found"
	fi
	
	if [ $project_path ] 
	then
	    read -r -p "Processes count [1] => " threads_count
	    if [ "$threads_count" == '' ]; then
		threads_count=1;
	    fi
	    echo "Starting $threads_count queue(s) at $project_path/vendor/bin/resque"
	    QUEUE=* COUNT=$threads_count php $project_path/vendor/bin/resque > /dev/null &
       	fi
    ;;
    "94" )
	pkill -f "bin/resque"
    ;;
    "95" )
            cd $script_path/config/
            for i in *.cfg; do
                . $i
                echo "Switch project" ${i%\.*}
                cd $project_path
                git checkout -f master
                composer --no-dev update
            done
    ;;
    "96" )
        echo "Change premissions"
        cd $project_path
        sudo chmod -R g+rw ./
        echo
    ;;
    "97" )
        df -h
    ;;
    "98" )
        clear
    ;;
    "99"|exit )
        exit 0
    ;;
esac
operations
}

check_folder() {
    if [ -z "$1" ]
        then
        echo "Folder name is not specified"
        return 0
    fi
    
    if [ -d "$1" ]
        then
            echo -n "The folder $1 exists"
            echo
        else
            echo -n "Trying to create a folder $1"
            echo
            mkdir $1
            check_folder $1
    fi

    return 0
}

projects_list() {
  cd config/;
  echo -e "${BLUE}Available projects:${GREEN}"
  for i in *.cfg; do
    echo ${i%\.*};
  done
  echo -e ${NC}
}

operations
echo
exit 0

