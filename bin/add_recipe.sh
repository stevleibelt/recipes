#!/bin/bash
####
# @author stev leibelt <artodeto@bazzline.net>
# @since 2016-01-10
####

#begin of functions
function tear_down ()
{
    cd ${PATH_OF_THE_CURRENT_WORKING_DIRECTORY}
}
#end of functions

#begin of getops
function update_local_variables_by_parsing_the_getopts ()
{
    while getopts "dh" CURRENT_OPTION;
    do
        case ${CURRENT_OPTION} in
            d )
                IS_DRY_RUN=1
                ;;
            h )
                echo "Usage: $(basename $0) [OPTION]"
                echo "The main command to create a new recipe."
                echo ""
                echo "Optional arguments."
                echo "  -d      enable dry run - nothing will happen"
                echo "  -h      print this help"
                echo ""
                ;;
        esac
    done
}
#end of getops

#begin of user input
function update_local_variables_by_user_input ()
{
    declare -i local AT_LEAST_ONE_TEMPLATE_WAS_SELECTED=0

    read -p ":: Will this recipe include an english translation? [y/n] (no is default): " ENGLISH_TEMPLATE_SELECTED

    read -p ":: Will this recipe include a german translation? [y/n] (yes is default): " GERMAN_TEMPLATE_SELECTED

    if [[ ${GERMAN_TEMPLATE_SELECTED} != "n" ]];
    then
        GERMAN_TEMPLATE_SELECTED="y"
    fi

    if [[ ${ENGLISH_TEMPLATE_SELECTED} == "y" ]];
    then
        AT_LEAST_ONE_TEMPLATE_WAS_SELECTED=1
    fi

    if [[ ${GERMAN_TEMPLATE_SELECTED} == "y" ]];
    then
        AT_LEAST_ONE_TEMPLATE_WAS_SELECTED=1
    fi

    if [[ ${AT_LEAST_ONE_TEMPLATE_WAS_SELECTED} -eq 0 ]];
    then
        echo "::"
        echo ":: Failed!"
        echo ":: You have to include at least one translation."
        tear_down

        exit 1
    fi

    echo ":: Available categories are."
    CATEGORY_LIST_AS_STRING=""

    for CATEGORY_KEY in ${!ARRAY_OF_CATEGORIES[@]};
    do
        echo ${CATEGORY_KEY}
        CATEGORY_LIST_AS_STRING+="${CATEGORY_KEY}) ${ARRAY_OF_CATEGORIES[${CATEGORY_KEY}]}  "
    done

    while true; do
        echo "   ${CATEGORY_LIST_AS_STRING}"
        echo ":: Please select the fitting category number. "
        read -p "   " CATEGORY_KEY_SELECTED

        if [[ -z ${CATEGORY_KEY_SELECTED} ]];
        then
            echo "::"
            echo ":: Failed!"
            echo ":: Please input a valid category number."
        elif [[ ! -z ${ARRAY_OF_CATEGORIES[${CATEGORY_KEY_SELECTED}]} ]];
        then
            CATEGORY_NAME="${ARRAY_OF_CATEGORIES[${CATEGORY_KEY_SELECTED}]}"
            break;
        else
            echo "::"
            echo ":: Failed!"
            echo ":: Please input a valid category number."
        fi
    done
}
#end of user input

#begin of creating the file
function create_and_edit_recipe_file ()
{
    local PATH_OF_THE_INDEX_FILE="${PATH_OF_THE_PROJECT_ROOT}.data/index"
    local INDEX_OF_THE_NEXT_RECIPE=$(cat ${PATH_OF_THE_INDEX_FILE} | tr -cd [:digit:])

    local PATH_OF_THE_ENGLISH_TEMPLATE="${PATH_OF_THE_PROJECT_ROOT}.data/english_template.md"
    local PATH_OF_THE_GERMAN_TEMPLATE="${PATH_OF_THE_PROJECT_ROOT}.data/german_template.md"
    local PATH_OF_SELECTED_RECIPE_CATEGORY="${PATH_OF_THE_PROJECT_ROOT}${CATEGORY_NAME}"
    local PATH_OF_NEXT_RECIPE="${PATH_OF_SELECTED_RECIPE_CATEGORY}/${INDEX_OF_THE_NEXT_RECIPE}.md"

    if [[ ! -d "${PATH_OF_SELECTED_RECIPE_CATEGORY}" ]];
    then
        /usr/bin/env mkdir -p ${PATH_OF_SELECTED_RECIPE_CATEGORY}
    fi

    /usr/bin/env touch ${PATH_OF_NEXT_RECIPE}

    if [[ ${ENGLISH_TEMPLATE_SELECTED} == "y" ]];
    then
        /usr/bin/env cat ${PATH_OF_THE_ENGLISH_TEMPLATE} >> ${PATH_OF_NEXT_RECIPE}
        #@todo implement a smarter way
        /usr/bin/env echo "" >> ${PATH_OF_NEXT_RECIPE}
    fi

    if [[ ${GERMAN_TEMPLATE_SELECTED} == "y" ]];
    then
        /usr/bin/env cat ${PATH_OF_THE_GERMAN_TEMPLATE} >> ${PATH_OF_NEXT_RECIPE}
    fi

    ((++INDEX_OF_THE_NEXT_RECIPE))
    echo "next: ${INDEX_OF_THE_NEXT_RECIPE}" > ${PATH_OF_THE_INDEX_FILE}

    /usr/bin/env vim ${PATH_OF_NEXT_RECIPE}
}
#begin of creating the file

#begin of creating dynamic content for the readme
function scan_recipe_files_and_create_language_based_index ()
{
    for RECIPE_CATEGORY in "${ARRAY_OF_CATEGORIES[@]}";
    do
        if [[ -d ${RECIPE_CATEGORY}/ ]];
        then
            for RECIPE_FILENAME in $(ls ${RECIPE_CATEGORY}/);
            do
                local RECIPE_GERMAN_TITLE=""
                local RECIPE_ENGLISH_TITLE=""
                local NEXT_NOT_EMPTY_LINE_IS_THE_GERMAN_RECIPE_TITLE=0
                local NEXT_NOT_EMPTY_LINE_IS_THE_ENGLISH_RECIPE_TITLE=0

                while read -r CURRENT_RECIPE_CONTENT_LINE;
                do
                    if [[ ${NEXT_NOT_EMPTY_LINE_IS_THE_GERMAN_RECIPE_TITLE} -eq 1 ]];
                    then
                        if [[ ${CURRENT_RECIPE_CONTENT_LINE} != "" ]];
                        then
                            RECIPE_GERMAN_TITLE="${CURRENT_RECIPE_CONTENT_LINE}"
                            NEXT_NOT_EMPTY_LINE_IS_THE_GERMAN_RECIPE_TITLE=0
                        fi
                    elif [[ ${NEXT_NOT_EMPTY_LINE_IS_THE_ENGLISH_RECIPE_TITLE} -eq 1 ]];
                    then
                        if [[ ${CURRENT_RECIPE_CONTENT_LINE} != "" ]];
                        then
                            RECIPE_ENGLISH_TITLE="${CURRENT_RECIPE_CONTENT_LINE}"
                            NEXT_NOT_EMPTY_LINE_IS_THE_ENGLISH_RECIPE_TITLE=0
                        fi
                    else
                        if [[ "${CURRENT_RECIPE_CONTENT_LINE}" == "## Title" ]];
                        then
                            NEXT_NOT_EMPTY_LINE_IS_THE_ENGLISH_RECIPE_TITLE=1
                        elif [[ "${CURRENT_RECIPE_CONTENT_LINE}" == "## Titel" ]]; 
                        then
                            NEXT_NOT_EMPTY_LINE_IS_THE_GERMAN_RECIPE_TITLE=1
                        fi
                    fi
                done < "${RECIPE_CATEGORY}/${RECIPE_FILENAME}"

                if [[ "${RECIPE_ENGLISH_TITLE}" != "" ]];
                then
                    LIST_OF_README_ENGLISH_INDEX_CONTENT_LINES+=("[${RECIPE_ENGLISH_TITLE}](https://github.com/stevleibelt/recipes/blob/master/${RECIPE_CATEGORY}/${RECIPE_FILENAME}#english)")
                fi

                if [[ "${RECIPE_GERMAN_TITLE}" != "" ]];
                then
                    LIST_OF_README_GERMAN_INDEX_CONTENT_LINES+=("[${RECIPE_GERMAN_TITLE}](https://github.com/stevleibelt/recipes/blob/master/${RECIPE_CATEGORY}/${RECIPE_FILENAME}#deutsch)")
                fi
            done
        fi
    done
}
#end of creating dynamic content for the readme

#begin of updating the readme
function update_readme ()
{
    local PATH_OF_THE_README=README.md
    local PATH_OF_THE_TEMPORARY_README=${PATH_OF_THE_README}.temporary
    local PATH_OF_THE_TEMPORARY_ENGLISH_INDEX=${PATH_OF_THE_README}.index.en
    local PATH_OF_THE_TEMPORARY_GERMAN_INDEX=${PATH_OF_THE_README}.index.de
    local PUT_NEXT_CONTENT_LINE_INTO_TEMPORARY_FILE=1

    echo "" > "${PATH_OF_THE_TEMPORARY_README}"

    while read -r CURRENT_CONTENT_LINE;
    do
        if [[ ${PUT_NEXT_CONTENT_LINE_INTO_TEMPORARY_FILE} -ne 1 ]];
        then
            FIRST_CHARACTER=${CURRENT_CONTENT_LINE:0:1}

            if [[ "${FIRST_CHARACTER}" == "#" ]];
            then
                PUT_NEXT_CONTENT_LINE_INTO_TEMPORARY_FILE=1
            fi
        fi

        if [[ ${PUT_NEXT_CONTENT_LINE_INTO_TEMPORARY_FILE} -eq 1 ]];
        then
            echo "${CURRENT_CONTENT_LINE}" >> "${PATH_OF_THE_TEMPORARY_README}"

            if [[ "${CURRENT_CONTENT_LINE}" == "## Index" ]];
            then
                PUT_NEXT_CONTENT_LINE_INTO_TEMPORARY_FILE=0
                echo "" > "${PATH_OF_THE_TEMPORARY_ENGLISH_INDEX}"
                for ENGLISH_INDEX_CONTENT_LINE in "${LIST_OF_README_ENGLISH_INDEX_CONTENT_LINES[@]}";
                do
                    echo "* ${ENGLISH_INDEX_CONTENT_LINE}" >> "${PATH_OF_THE_TEMPORARY_ENGLISH_INDEX}"
                done
                echo "" >> "${PATH_OF_THE_TEMPORARY_ENGLISH_INDEX}"

		cat "${PATH_OF_THE_TEMPORARY_ENGLISH_INDEX}" | sort >> "${PATH_OF_THE_TEMPORARY_README}"
            elif [[ "${CURRENT_CONTENT_LINE}" == "## Inhaltsverzeichnis" ]];
            then
                PUT_NEXT_CONTENT_LINE_INTO_TEMPORARY_FILE=0
                echo "" > "${PATH_OF_THE_TEMPORARY_GERMAN_INDEX}"
                for GERMAN_INDEX_CONTENT_LINE in "${LIST_OF_README_GERMAN_INDEX_CONTENT_LINES[@]}";
                do
                    echo "* ${GERMAN_INDEX_CONTENT_LINE}" >> "${PATH_OF_THE_TEMPORARY_GERMAN_INDEX}"
                done
                echo "" >> "${PATH_OF_THE_TEMPORARY_GERMAN_INDEX}"

		cat "${PATH_OF_THE_TEMPORARY_GERMAN_INDEX}" | sort >> "${PATH_OF_THE_TEMPORARY_README}"
            fi
        fi
    done < "${PATH_OF_THE_README}"

    mv ${PATH_OF_THE_TEMPORARY_README} ${PATH_OF_THE_README}
    rm "${PATH_OF_THE_TEMPORARY_ENGLISH_INDEX}"
    rm "${PATH_OF_THE_TEMPORARY_GERMAN_INDEX}"
}
#end of updating the readme

#begin of main
function _main ()
{
    #bo: local variables
    declare -i IS_DRY_RUN=0
    declare -a LIST_OF_README_ENGLISH_INDEX_CONTENT_LINES=()
    declare -a LIST_OF_README_GERMAN_INDEX_CONTENT_LINES=()
    local PATH_OF_THE_CURRENT_SCRIPT=$(cd $(dirname "${BASH_SOURCE[0]}"); pwd)

    local PATH_OF_THE_PROJECT_ROOT="${PATH_OF_THE_CURRENT_SCRIPT}/.."
    local PATH_OF_THE_CURRENT_WORKING_DIRECTORY=$(pwd)
    #eo: local variables

    #bo: setup

    local FILE_PATH="${PATH_OF_THE_PROJECT_ROOT}/.data/categories"

    if [[ -f "${FILE_PATH}" ]];
    then
        source "${FILE_PATH}"

        if [[ ${#ARRAY_OF_CATEGORIES[@]} -lt 1 ]];
        then
            echo ":: Error!"
            echo "   There are less than 1 category defined in >>${FILE_PATH}<< and >>ARRAY_OF_CATEGORIES<<."

            exit 2
        fi

    else
        echo ":: Error!"
        echo "   File not available in path >>${FILE_PATH}<<."

        exit 1
    fi

    cd ${PATH_OF_THE_PROJECT_ROOT}

    git pull
    #eo: setup

    update_local_variables_by_parsing_the_getopts ${@}
    update_local_variables_by_user_input
    create_and_edit_recipe_file
    scan_recipe_files_and_create_language_based_index
    update_readme

    tear_down
}
#end of main

####
#@todo
#<update readme>
#   sort recipies
#       by category
#       by name
#<update tag list>
#   read files per category
#   add each tag into a language based tag array (if tag is not already in)
#   create a file per tag
#   add a link to the tag file into the language based readme section
#   search in each file (per category) if this tag exist and add the title as well as the link to the file into this tag file
#<ask if you want to edit an existing recipe or create a new recipe>
####

_main ${@}
