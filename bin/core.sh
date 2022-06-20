#!/bin/bash
####
# @author stev leibelt <artodeto@bazzline.net>
# @since 2016-09-07
####

####
# declares constant core_setup_global_list_of_categories
####
function core_setup_global_list_of_categories ()
{
    FILE_PATH="${GLOBAL_PATH_OF_THE_PROJECT_ROOT}.data/categories"
    readarray -t GLOBAL_LIST_OF_CATEGORIES < "${FILE_PATH}"
    export GLOBAL_LIST_OF_CATEGORIES
}

####
# declares constant GLOBAL_PATH_OF_THE_CURRENT_WORKING_DIRECTORY
####
function core_setup_global_path_of_current_working_directory ()
{
    export GLOBAL_PATH_OF_THE_CURRENT_WORKING_DIRECTORY=$(pwd)
}

####
# declares constant PATH_OF_THE_CURRENT_SCRIPT
####
function core_setup_global_path_of_the_project_root ()
{
    local PATH_OF_THE_CURRENT_SCRIPT=$(cd $(dirname "${BASH_SOURCE[0]}"); pwd)

    export GLOBAL_PATH_OF_THE_PROJECT_ROOT=${PATH_OF_THE_CURRENT_SCRIPT}/../
}

####
# calling functions
#   core_setup_global_path_of_the_project_root
#   core_setup_global_path_of_the_current_working_directory
#   core_setup_global_list_of_categories
####
function core_main ()
{
    core_setup_global_path_of_current_working_directory
    core_setup_global_path_of_the_project_root
    core_setup_global_list_of_categories
}
