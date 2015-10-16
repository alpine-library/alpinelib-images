#!/bin/bash
set -e

cd "$(dirname "$(readlink -f "$BASH_SOURCE")")"

repos=( --all )

upstreamRepo='alpine-library/official-images'
upstreamBranch='master'

HEAD="$(git rev-parse --verify HEAD)"

git fetch -q "https://github.com/$upstreamRepo.git" "refs/heads/$upstreamBranch"
UPSTREAM="$(git rev-parse --verify FETCH_HEAD)"

if [ "$(git diff --numstat "$UPSTREAM...$HEAD" -- . | wc -l)" -ne 0 ]; then
	# changes in bashbrew/ -- keep "--all" so we test the bashbrew script changes appropriately
	echo >&2 'Changes in bashbrew/ detected!'
else
	repos=( $(git diff --numstat "$UPSTREAM...$HEAD" -- ../library | awk -F '/' '{ print $2 }') )
fi

if [ "${#repos[@]}" -eq 0 ]; then
	echo >&2 'Skipping test builds: no changes to library/ or bashbrew/ in PR'
	exit
fi

set -x
./bashbrew.sh list --namespaces="alpine-library" --uniq "${repos[@]}"
./bashbrew.sh list --namespaces="alpine-library" "${repos[@]}"
./bashbrew.sh build --namespaces="alpine-library" "${repos[@]}"
./bashbrew.sh push --namespaces="alpine-library" "${repos[@]}"
