# N2ST testing tools for shell script development

## Setup

1. Copy the `norlab-shell-script-tools/tests/tests_template/` directory in your main project top
   directory and rename it, e.g. `tests_template/` → `tests_shell/` ( recommand using the
   convention `tests/`);
2. Add project test code in this new test directory.

    - See `test_template.bats` for bats test implementation examples;
    - Usage: duplicate `test_template.bats` and rename it using the
      convention `test_<logic_or_script_name>.bats`;
    - Note: That file is pre-configured to work out of the box, just missing your test logic.

3. Use the copied script `run_bats_core_test_in_n2st.bash` to execute your tests.
   They will be executed in isolation in a docker container tailormade for testing shell script or
   command level logic in your codebase.

- Note: test directory nesting is suported
- By default, it will search for the `tests/` directory. Pass your test directory name as an
  argument otherwise.

Assuming that the superproject (i.e. the project which have cloned `N2ST` as a
submodule) as the following structure, `tests/` would be containing all the `.bats` files

```shell
myCoolSuperProject
┣━━ src/
┣━━ tests/
┃   ┣━━ run_bats_core_test_in_n2st.bash
┃   ┣━━ test_pew_poo_poo.bats
┃   ┗━━ tests_those/
┃       ┣━━ test_poo_po_pew_pow.bats
┃       ┗━━ test_poooow_pew_poo.bats
┣━━ utilities/
┃   ┗━━ norlab-shell-script-tools/
┃       ┣━━ src/
┃       ┣━━ tests/
┃       ┃    ┣━━ bats_testing_tools/
┃       ┃    ┣━━ tests_template/
┃       ┃    ┗━━ ...
┃       ┗━━ ...
┣━━ .env.my_superproject
┣━━ .git
┣━━ .gitmodules
┗━━ README.md
```

## To execute your superproject shell script tests

To execute your superproject shell scripts `bats` test via 'norlab-shell-script-tools' library,
just run the following from your repository root

```shell
cd "<path/to/superproject>/tests"
bash run_bats_core_test_in_n2st.bash ['<test-directory>[/<this-bats-test-file.bats>]' ['<image-distro>']]
```

Arguments:

- `['<test-directory>']`            The directory from which to start test, default to 'tests'
- `['/<this-bats-test-file.bats>']`  A specific bats file to run, default will run all bats file in
  the test directory

See `tests/tests_template/run_bats_core_test_in_n2st.bash` for details.

---

## Bats shell script testing framework references

- [bats-core on github](https://github.com/bats-core/bats-core)
- [bats-core on readthedocs.io](https://bats-core.readthedocs.io)
- `bats` helper library (pre-installed in `norlab-shell-script-tools` testing containers in
  the `tests/` dir)
    - [bats-assert](https://github.com/bats-core/bats-assert)
    - [bats-file](https://github.com/bats-core/bats-file)
    - [bats-support](https://github.com/bats-core/bats-support)
- Quick intro:
    - [testing bash scripts with bats](https://www.baeldung.com/linux/testing-bash-scripts-bats)

