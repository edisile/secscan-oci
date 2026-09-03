#!/bin/bash

if [ -z "$1" ]; then
    echo "Usage $0 /path/to/project [--rock]"
    echo ""
    exit 1
fi


SECSCAN=$(which secscan-client)
PROJECT_PATH="${1}"
IS_ROCK=""
if [ ! -z ${2} ] && [ ${2} = "--rock" ]; then
    IS_ROCK="1"
fi


if [ -z $SECSCAN ]; then
    echo "secscan-client not found. You can install it with:"
    echo "  snap install canonical-secscan-client"
    echo ""
    echo "Once installed connect your home directory:"
    echo "  snap connect canonical-secscan-client:home"
    echo ""
    echo "Now you can run this script again <3"
    echo ""
    exit 1
fi

step_header () {
    echo "> Step ${1} <"
    echo "----"
    echo ""
}


run_docker () {
    step_header "1: Build docker image"
    docker build --tag "webteam:${PROJECT}" "${PROJECT_PATH}"

    step_header "2: Saving OCI image to ${OUTPUT}"
    docker save -o "${OUTPUT}" "webteam:${PROJECT}"

    step_header "3: Submitting OCI image via secscan-client"
    secscan-client submit --scanner blackduck --type container-image --format oci "${OUTPUT}" --token "${PROJECT_PATH}/${PROJECT}.token"
}

run_rockcraft () {
    step_header "1: Build rock image"
    cd ${PROJECT_PATH} && rockcraft pack

    step_header "2: Submitting rock image via secscan-client"
    secscan-client submit --scanner blackduck --type container-image --format oci "${OUTPUT}" --token "${PROJECT_PATH}/${PROJECT}.token"
}

if [ -z $IS_ROCK ]; then
    # it's a docker image
    DOCKER=$(which docker)
    PROJECT=(${PROJECT_PATH//// })
    PROJECT=${PROJECT[-1]}
    OUTPUT="${PROJECT_PATH}/${PROJECT}.tar"

    if [ -z $DOCKER ]; then
        echo "Docker not found. Please install and set up Docker, then run this script again."
        exit 1
    fi

    if [ ! -f "${PROJECT_PATH}/Dockerfile" ]; then
        echo "Dockerfile file not found. Are you pointing to the correct project path?"
        exit 1
    fi

    run_docker
else
    # it's a rock
    YQ=$(which yq)
    ROCKCRAFT=$(which rockcraft)

    if [ -z $YQ ]; then
        echo "yq not found. Please install and set up yq, then run this script again."
        exit 1
    fi

    if [ -z $ROCKCRAFT ]; then
        echo "Rockcraft not found. Please install and set up Rockcraft, then run this script again."
        exit 1
    fi

    if [ ! -f "${PROJECT_PATH}/rockcraft.yaml" ]; then
        echo "rockcraft.yaml file not found. Are you pointing to the correct project path?"
        exit 1
    fi

    cd ${PROJECT_PATH}

    ROCKCRAFT_YAML="${PROJECT_PATH}/rockcraft.yaml"
    PROJECT=$(yq '.name' ${ROCKCRAFT_YAML})
    VERSION=$(yq '.version' ${ROCKCRAFT_YAML})
    ARCH=$(dpkg --print-architecture)

    OUTPUT="${NAME}_${VERSION}_${PLATFORM}.rock"

    run_rockcraft
fi


echo "To check on the status of the request you can use the following command:"
echo "  secscan-client status --token ${PROJECT_PATH}/${PROJECT}.token"
echo ""
echo "Thanks <3"
