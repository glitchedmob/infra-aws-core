.PHONY: help tf-init tf-plan tf-show tf-output tf-apply tf-validate tf-format tf-lint-fix

TF_DIR := tf
SHELL := bash

help:
	@echo "OpenTofu commands:"
	@echo "  Init:              make tf-init"
	@echo "  Plan:              make tf-plan"
	@echo "  Show:              make tf-show ARGS=<planfile>"
	@echo "  Output:            make tf-output [ARGS='-json']"
	@echo "  Apply:             make tf-apply"
	@echo "  Validate:          make tf-validate"
	@echo "  Format check:      make tf-format"
	@echo "  Format fix:        make tf-lint-fix"

tf-init:
	@cd $(TF_DIR) && tofu init

tf-plan:
	@cd $(TF_DIR) && tofu plan

tf-show:
	@cd $(TF_DIR) && tofu show $(ARGS)

tf-output:
	@cd $(TF_DIR) && tofu output $(ARGS)

tf-apply:
	@cd $(TF_DIR) && tofu apply

tf-validate:
	@cd $(TF_DIR) && tofu validate

tf-format:
	@cd $(TF_DIR) && tofu fmt -check -recursive

tf-lint-fix:
	@cd $(TF_DIR) && tofu fmt -recursive
