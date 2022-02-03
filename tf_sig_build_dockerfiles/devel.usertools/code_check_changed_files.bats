# vim: filetype=bash
# This file is a work in progress, designed to replace the complicated test
# orchestration previously placed in TensorFlow's ci_sanity.sh.
# This is not currently in use.
setup_file() {
    cd /tf/tensorflow
    bazel version  # Start the bazel server
    # Only shows Added, Changed, Modified, Renamed, and Type-changed files
    # Note that you could generate a list of all the affected targets with e.g.:
    # bazel query $(paste -sd "+" $BATS_FILE_TMPDIR/changed_files) --keep_going
    git diff --diff-filter ACMRT --name-only origin/master > $BATS_FILE_TMPDIR/changed_files
}

# Note: this is excluded on the full code base, since any submitted code must
# have passed Google's internal style guidelines.
@test "Check buildifier formatting on BUILD files" {
    echo "buildifier formatting is recommended. Here are the suggested fixes:"
    echo "============================="
    grep -e 'BUILD' $BATS_FILE_TMPDIR/changed_files \
        | xargs buildifier -v -mode=diff -diff_command="git diff --no-index"
}

# Note: this is excluded on the full code base, since any submitted code must
# have passed Google's internal style guidelines.
@test "Check formatting for C++ files" {
    echo "clang-format is recommended. Here are the suggested changes:"
    echo "============================="
    grep -e '\.h$' -e '\.cc$' $BATS_FILE_TMPDIR/changed_files \
        | xargs -i -n1 -P $(nproc --all) \
        bash -c 'clang-format-12 --style=Google {} | git diff --no-index {} -' \
        | tee $BATS_TEST_TMPDIR/needs_help.txt
    echo "You can use clang-format --style=Google -i <file> to apply changes to a file."
    [[ ! -s $BATS_TEST_TMPDIR/needs_help.txt ]]
}

# Note: this is excluded on the full code base, since any submitted code must
# have passed Google's internal style guidelines.
@test "Check pylint for Python files" {
    echo "Python formatting is recommended. Here are the pylint errors:"
    echo "============================="
    grep -e "\.py$" $BATS_FILE_TMPDIR/changed_files \
        | xargs -n1 -P $(nproc --all) \
        python -m pylint --rcfile=tensorflow/tools/ci_build/pylintrc --score false \
        | grep -v "**** Module" \
        | tee $BATS_TEST_TMPDIR/needs_help.txt
    [[ ! -s $BATS_TEST_TMPDIR/needs_help.txt ]]
}

teardown_file() {
    bazel shutdown
}
