#!/bin/bash
#
# A script to make a branch and tag in a repository with tag description
# for contributions to OpenVnmrJ
#
# Copyright 2016 Tim Burrow
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
set -o nounset
set -e

checkifgit() {
  
  local curdir=$(pwd)
  echo -e "In ${curdir}\n"
  cd "${1}"/

  if [[ $(git rev-parse --is-inside-work-tree 2>/dev/null) == "true" ]]; then
    # we are inside a git repository; perhaps an appdir clone?
    # TODO check if a fork of appdirs, if so push?
    # For now ignore and just work independently, but DO NOT COPY .git!
    echo "Directory under git control"
    local remotegit=$(git config --get remote.origin.url 2> /dev/null&)
    echo "Checking"
    if [[ -z ${remotegit:-} ]]; then
      echo "No remote"
    else
      echo "Remote is ${remotegit}"
    fi
  fi
  cd "${curdir}"
}

docopy() {
  local src="${1}"
  local dest="${2}"
  local reponame="${3}"

# first check if dest already exists
  if [[ -d "${dest}/${reponame}" ]]; then
    if (( update == 0 )); then
      echo "Directory with name ${reponame} already exists! Use -U to update"
      exit 1
    fi
      # update using rsync (/ at end of src!)
      echo "Updating ${reponame}"
      echo "rsync -av --exclude='.git*' --delete ${src}/ ${dest}"
      rsync -av --exclude='.git*' --delete "${src}/" "${dest}"
  else
  	echo "Copying ${reponame}"
    echo "rsync -av --exclude='.git*'  ${src}/ ${dest}"
    rsync -av --exclude='.git*' "${src}/" "${dest}"	
  fi
}

update=0

while getopts “s:d:U” option; do
  case "$option" in
  	s)
  		# source directory
  		echo ${OPTARG}
  		src=${OPTARG}
  		echo -e "src: ${src}"
      ;; 
    d)
      # destination directory
      dest=${OPTARG}
      echo "dest: ${dest}"
      ;;    
    U)
      # Update; otherwise fails if destination exists
      update=1
      ;;
    /?) 
    	echo -e "Invalid option: ${option}\n" 1>&2
    	exit 85 
    	;;
  esac
done


# check inputs are good
if [[ -z ${src:-} ]]; then
  echo -e "Missing src! \n"
  exit 85
fi

if [[ -z ${dest:-} ]]; then
  echo -e "Missing dest!\n"
  exit 85
fi

#remove training slashes so we can put on when needed
src=${src%/}
dest=${dest%/}
echo -e "Source Directory: ${src}"
echo -e "Destination Directory: ${dest}\n"
reponame=$(basename "${src}")

if [[ ! -d "${src}"/ ]]; then
  echo "Directory ${src} not found"
  exit 1
fi

# check state of directory; it is a clone of appdirs?
checkifgit ${src}

docopy "${src}" "${dest}" "{$reponame}"

exit 0
