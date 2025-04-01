#!/usr/bin/env bash

# SPDX-FileCopyrightText: (C) 2025 Intel Corporation
# SPDX-License-Identifier: Apache-2.0

set -eu -o pipefail

DEB=0
YAML=0
ARCHIVE=0
FILES=0
JSON=0
EXCLUDE=''
REPO_NAME_OVERWRITE=''
PREFIX_VALUE=''
REPO_VERSION_OVERWRITE=''
NO_AUTH_ECR_OVERWRITE=''
NO_AUTH_ECR='edge-orch'

DEFAULT_DEPLOYMENT_PACKAGE_PATH='build/artifacts'
REPO_NAME="$(basename -s .git "$(git config --get remote.origin.url)" | awk -F'.' '{print $NF}')"

DEFAULT_REPO_VERSION=$(cat VERSION)

REGISTRY='080137407410.dkr.ecr.us-west-2.amazonaws.com/edge-orch'

while getopts "a:e:d:f:j:o:pr:s:v:y:" OPT; do
  case $OPT in
    a)
      ARCHIVE=1
      ARTIFACT_TYPE=${OPTARG}
      DEFAULT_EXCLUDE='Jenkinsfile'
      ;;
    e)
      EXCLUDE=${OPTARG}
      ;;
    d)
      DEB=1
      ARTIFACT_TYPE='deb'
      if [ -n "$OPTARG" ]; then
        DEPLOYMENT_PACKAGE_PATH=${OPTARG}
      else
        DEPLOYMENT_PACKAGE_PATH=${DEFAULT_DEPLOYMENT_PACKAGE_PATH}
      fi
      ;;
    f)
      FILES=1
      ARTIFACT_TYPE='file'
      FILE_PATH=${OPTARG}
      ;;
    j)
      JSON=1
      if [ "$#" -lt $((OPTIND)) ]; then
        echo "Error: -j option requires two arguments."
        exit 1
      fi
      ARTIFACT_TYPE=${OPTARG}
      FILE_PATH=${!OPTIND}
      ((OPTIND++))
      ;;
    o)
      REPO_NAME_OVERWRITE=${OPTARG}
      ;;
    p)
      PREFIX_VALUE='v'
      ;;
    r)
      REGISTRY=${OPTARG}
      ;;
    s)
      NO_AUTH_ECR_OVERWRITE=${OPTARG}
      ;;
    v)
      REPO_VERSION_OVERWRITE=${OPTARG}
      ;;
    y)
      YAML=1
      if [ "$#" -lt $((OPTIND)) ]; then
        echo "Error: -f option requires two arguments."
        exit 1
      fi
      ARTIFACT_SPECIFIC_NAME=${OPTARG}
      DEPLOYMENT_PACKAGE_PATH=${!OPTIND}
      ((OPTIND++))
      ;;
    *)
      echo "Usage: [-d] [-f <artifact_type> <artifact_path> <artifact_extension>] [-r <registry_url>]"
      echo "  -a in case of archiving the repository as a zip file. You also need to provide artifact type as an argument, e.g., fleet"
      echo "  -e in case of excluding certain files from the archive"
      echo "  -d in case of pushing debian packages"
      echo "  -f when pushing files. You can give one or more filepaths or a filepath with wildcard"
      echo "  -j when pushing json files. You need to give two arguments, e.g., lp-app <path_to_json>"
      echo "  -o overwrite repository name with your specific name"
      echo "  -p append v prefix to version for debian packages"
      echo "  -r <registry_url> to replace the default registry url"
      echo "  -s overwrite the no auth ecr name."
      echo "  -v <path to version file>. Version from this version file will be used for tag"
      echo "  -y in case of pushing yaml files. You also need to define the artifact type and specific name like dp /<path>/<to>/<yaml>/"
      exit 1
      ;;
  esac
done

if [ -n "$NO_AUTH_ECR_OVERWRITE" ]; then
  NO_AUTH_ECR=${NO_AUTH_ECR_OVERWRITE}
fi

if [ -n "$REPO_NAME_OVERWRITE" ]; then
  REPO_NAME=${REPO_NAME_OVERWRITE}
fi

if [ -n "$REPO_VERSION_OVERWRITE" ]; then
  LOCAL_REPO_VERSION=$(cat "${REPO_VERSION_OVERWRITE}")
  DEFAULT_REPO_VERSION=${LOCAL_REPO_VERSION}
fi

if [[ ${DEB} != 0 || ${YAML} != 0 ]]; then
  cd "$DEPLOYMENT_PACKAGE_PATH"
fi


if [ ${DEB} != 0 ]; then
    for DEB_PKG in *.deb; do
        PKG_VER=$(dpkg-deb -f "${DEB_PKG}" Version)
        PKG_NAME=$(dpkg-deb -f "${DEB_PKG}" Package)

        if [[ "${PKG_VER}" =~ .*-dev$ ]]; then
            TAG="${PKG_VER}-$(git rev-parse --short HEAD),latest-$BRANCH_NAME-dev,${PREFIX_VALUE}${PKG_VER}-$(git rev-parse --short HEAD)"
        elif [[ "${PKG_VER}" =~ .*-dev- ]]; then
            TAG="${PREFIX_VALUE}${PKG_VER},latest-$BRANCH_NAME-dev,${PREFIX_VALUE}${PKG_VER}-$(git rev-parse --short HEAD)"
        else
            TAG="${PREFIX_VALUE}${PKG_VER},latest-$BRANCH_NAME"
        fi
        #see if this fixues the random issue with blob upload unknown to registry: map[]
        sleep 5
        aws ecr create-repository --region us-west-2 --repository-name  "${NO_AUTH_ECR}"/"${ARTIFACT_TYPE}"/"${PKG_NAME}" || true
        oras push "${REGISTRY}"/"${NO_AUTH_ECR}"/"${ARTIFACT_TYPE}"/"${PKG_NAME}":"${TAG}" \
        --artifact-type application/vnd.intel.orch."${ARTIFACT_TYPE}" ./"${DEB_PKG}"

    done
fi

if [ ${YAML} != 0 ]; then
  if [[ "$DEFAULT_REPO_VERSION" =~ .*-dev ]]; then
    TAG="${DEFAULT_REPO_VERSION}-$(git rev-parse --short HEAD),latest-$BRANCH_NAME-dev,v${DEFAULT_REPO_VERSION}-$(git rev-parse --short HEAD)"
  else
    TAG="${DEFAULT_REPO_VERSION},latest-$BRANCH_NAME,v${DEFAULT_REPO_VERSION}"
  fi

  aws ecr create-repository --region us-west-2 --repository-name  "${NO_AUTH_ECR}"/"${ARTIFACT_SPECIFIC_NAME}"/"${REPO_NAME}" || true
  oras push "${REGISTRY}"/"${NO_AUTH_ECR}"/"${ARTIFACT_SPECIFIC_NAME}"/"${REPO_NAME}":"${TAG}" \
        --artifact-type application/vnd.intel.orch."${ARTIFACT_SPECIFIC_NAME}" ./*.yaml
fi

if [ ${ARCHIVE} != 0 ]; then
  if [[ "$DEFAULT_REPO_VERSION" =~ .*-dev ]]; then
    TAG="${DEFAULT_REPO_VERSION}-$(git rev-parse --short HEAD),latest-$BRANCH_NAME-dev,v${DEFAULT_REPO_VERSION}-$(git rev-parse --short HEAD)"
  else
    TAG="${DEFAULT_REPO_VERSION},latest-$BRANCH_NAME,v${DEFAULT_REPO_VERSION}"
  fi
  zip -r "${REPO_NAME}".zip ./* -x "${DEFAULT_EXCLUDE}" "${EXCLUDE}"
  
  aws ecr create-repository --region us-west-2 --repository-name  "${NO_AUTH_ECR}"/"${ARTIFACT_TYPE}"/"${REPO_NAME}" || true
  oras push "${REGISTRY}"/"${NO_AUTH_ECR}"/"${ARTIFACT_TYPE}"/"${REPO_NAME}":"${TAG}" \
  --artifact-type application/vnd.intel.orch."${ARTIFACT_TYPE}" ./"${REPO_NAME}".zip
fi

if [ ${FILES} != 0 ]; then
  if [[ "$DEFAULT_REPO_VERSION" =~ .*-dev ]]; then
    TAG="${DEFAULT_REPO_VERSION}-$(git rev-parse --short HEAD),latest-$BRANCH_NAME-dev,v${DEFAULT_REPO_VERSION}-$(git rev-parse --short HEAD)"
  else
    TAG="${DEFAULT_REPO_VERSION},latest-$BRANCH_NAME,v${DEFAULT_REPO_VERSION}"
  fi
  # separate multiple paths
  IFS=' ' read -ra FILE_PATH_ARRAY <<< "${FILE_PATH}"
  file_list=() # Initialize an empty array to hold file paths
  for path in "${FILE_PATH_ARRAY[@]}"; do
      echo "$path"
      if [ -d "$path" ]; then
        # if  directory add its files to the aray
        for file in "$path"/*; do
            file_list+=("$file")
        done
      elif [ -f "$path" ]; then
        file_list+=("$path")
      else
        # treat use case where path has wildcards
        for file in $path; do
            file_list+=("$file") 
        done
      fi
  done
  # push all files in the array as a list and change directory to it
  if [ ${#file_list[@]} -gt 0 ]; then
    echo "Pushing files: ${file_list[*]}"
    temp_dir=$(mktemp -d)
    for file in "${file_list[@]}"; do
      cp -r "$file" "$temp_dir"
    done
    aws ecr create-repository --region us-west-2 --repository-name  "${NO_AUTH_ECR}"/"${ARTIFACT_TYPE}"/"${REPO_NAME}" || true
    cd "$temp_dir"
    oras push "${REGISTRY}"/"${NO_AUTH_ECR}"/"${ARTIFACT_TYPE}"/"${REPO_NAME}":"${TAG}" \
      --artifact-type application/vnd.intel.orch."${ARTIFACT_TYPE}" ./*
  fi
fi

if [ ${JSON} != 0 ]; then
  if [[ "$DEFAULT_REPO_VERSION" =~ .*-dev ]]; then
    TAG="${DEFAULT_REPO_VERSION}-$(git rev-parse --short HEAD),latest-$BRANCH_NAME-dev"
  else
    TAG="${DEFAULT_REPO_VERSION},latest-$BRANCH_NAME"
  fi
  # separate multiple paths
  IFS=' ' read -ra FILE_PATH_ARRAY <<< "${FILE_PATH}"
  file_list=() 
  for path in "${FILE_PATH_ARRAY[@]}"; do
      echo "$path"
      if [ -d "$path" ]; then
        # if  directory add its files to the aray
        for file in "$path"/*; do
            file_list+=("$file")
        done
      elif [ -f "$path" ]; then
        file_list+=("$path")
      else
        # treat use case where path has wildcards
        for file in $path; do
            file_list+=("$file")
        done
      fi
  done
  # push all files in the array as a list and change directory to it
  if [ ${#file_list[@]} -gt 0 ]; then
    echo "Pushing files: ${file_list[*]}"
    temp_dir=$(mktemp -d)
    for file in "${file_list[@]}"; do
      cp -r "$file" "$temp_dir"
    done
    aws ecr create-repository --region us-west-2 --repository-name  "${NO_AUTH_ECR}"/tmpl/"${ARTIFACT_TYPE}" || true
    cd "$temp_dir"
    oras push "${REGISTRY}"/"${NO_AUTH_ECR}"/tmpl/"${ARTIFACT_TYPE}":"${TAG}" \
      --artifact-type application/vnd.intel.orch."${ARTIFACT_TYPE}" ./*
  fi
fi
