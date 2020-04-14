#!/bin/bash -e

src=ocaml/opam-repository
dst=kit-ty-kate/opam-repository

git clone "git@github.com:$dst.git" repo
cd repo
trap 'cd .. && rm -rf repo && exit' EXIT

git remote add upstream "git://github.com/$src.git"
git pull --ff-only upstream master
git push origin master

prs=$(curl -sL "https://api.github.com/repos/$src/pulls?state=open")
len=$(echo "$prs" | jq 'length')
prs_to_open=

for i in $(seq "$len"); do
    i=$(echo "$i - 1" | bc)
    pr=$(echo "$prs" | jq ".[$i]")
    pr_number=$(echo "$pr" | jq '.number')
    diff_url=$(echo "$pr" | jq -r '.diff_url')
    branch_name="github_prs_forwarder__${pr_number}"

    echo
    echo
    echo "--------- PR number $pr_number -----------"
    echo

    if git branch -r | grep -q "$branch_name"; then
        git switch "$branch_name"
    else
        git switch -c "$branch_name" master
        prs_to_open="${prs_to_open:+$prs_to_open }${branch_name}"
    fi

    patch=$(curl -sL "$diff_url")

    if echo "$patch" | patch -p1 -N -s; then
        git add *
        git commit -m 'test'
        git push origin "$branch_name"
    elif echo "$patch" | patch -p1 -R -f -s --dry-run; then
        echo
        echo PR already up-to-date
    else
        git reset --hard HEAD^
        echo "$patch" | patch -p1 -N -s
        git add *
        git commit -m 'test'
        git push --force-with-lease origin "$branch_name"
    fi
done

echo
echo
echo 'The following PRs are to be opened:'

for branch in $prs_to_open; do
    echo "* https://github.com/${dst}/compare/master...${branch}?expand=1"
done
