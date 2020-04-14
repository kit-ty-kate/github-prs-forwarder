#!/bin/bash -e

git clone git@github.com:kit-ty-kate/opam-repository.git
cd opam-repository
trap 'cd .. && rm -rf opam-repository && exit' EXIT

git remote add upstream git://github.com/ocaml/opam-repository.git
git pull --ff-only upstream master
git push origin master

prs=$(curl -sL 'https://api.github.com/repos/ocaml/opam-repository/pulls?state=open')
len=$(echo "$prs" | jq 'length')

for i in $(seq "$len"); do
    i=$(echo "$i - 1" | bc)
    pr=$(echo "$prs" | jq ".[$i]")
    pr_number=$(echo "$pr" | jq '.number')
    diff_url=$(echo "$pr" | jq -r '.diff_url')
    branch_name="github_pr_autocopy__${pr_number}"

    if git branch -r | grep -q "$branch_name"; then
        git switch "$branch_name"
    else
        git switch -c "$branch_name" master
    fi
    if curl -sL "$diff_url" | patch -p1 -N; then
        git add *
        git commit -m 'test'
        git push origin "$branch_name"
    else
        echo PR already up-to-date
    fi
done
