# Add project test code in this directory

## Test docker related implementation

To validate docker compose configuration and `.env` related logic, execute the following

```shell
bash run_all_docker_dryrun_and_config_tests.bash
```

To assess dockerfile implementation, execute the following

```shell
bash run_all_docker_build_tests.bash
```

Both scripts will iterate over each `.bash` file that are prefixed by either `dryrun_` or `test_`
in the `tests_docker_dryrun_and_config` directory and execute each one that match those conditions.

## Test shell script implementation
Execute 'norlab-build-system' repo shell script test via 'norlab-shell-script-tools' library

Usage:
```shell
bash run_bats_core_test_in_n2st.bash ['<test-directory>[/<this-bats-test-file.bats>]' ['<image-distro>']]
```
Arguments:
  - `['<test-directory>']`        The directory from which to start test, default to 'tests'
  - `['/<this-bats-test-file.bats>']`  A specific bats file to run, default will run all bats file in the test directory

---

### Bats shell script testing framework references

- [bats-core on github](https://github.com/bats-core/bats-core)
- [bats-core on readthedocs.io](https://bats-core.readthedocs.io)
- `bats` helper library (pre-installed in `norlab-shell-script-tools` testing containers in
  the `tests/` dir)
    - [bats-assert](https://github.com/bats-core/bats-assert)
    - [bats-file](https://github.com/bats-core/bats-file)
    - [bats-support](https://github.com/bats-core/bats-support)
- Quick intro:
    - [testing bash scripts with bats](https://www.baeldung.com/linux/testing-bash-scripts-bats)

