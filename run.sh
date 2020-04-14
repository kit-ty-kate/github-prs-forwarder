#!/bin/bash -ex

copy_prs() {
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

        git switch -c "$branch_name" master
        curl -sL "$diff_url" | patch -p1
        git add *
        git commit -m 'test'
        git push origin "$branch_name"
    done
}

git clone git@github.com:kit-ty-kate/opam-repository.git
cd opam-repository

copy_prs || true

cd ..
rm -rf opam-repository
