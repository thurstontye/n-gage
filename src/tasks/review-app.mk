# The REVIEW_APP_FILE is created by the `review-app` task.
# if it exists it contains the name of the review app
# on heroku
REVIEW_APP_FILE := .review-app

tidy-review-app:
	rm -f $(REVIEW_APP_FILE)

review-app: tidy-review-app .review-app

.review-app:
	@echo 'Creating review app for $(VAULT_NAME)'

	# Configure the pipeline
	$(if $(REVIEW_APP_CONFIGURE_OVERRIDES),\
	  nht configure $(VAULT_NAME) review-app --overrides "$(REVIEW_APP_CONFIGURE_OVERRIDES)", \
	  nht configure $(VAULT_NAME) review-app --overrides NODE_ENV=branch \
	)

	@nht review-app $(VAULT_NAME) \
		--repo-name $(CIRCLE_PROJECT_REPONAME) \
		--branch $(CIRCLE_BRANCH) \
		--commit $(CIRCLE_SHA1) \
		--github-token $(GITHUB_AUTH_TOKEN) > $@

	# Configure the review app
	$(if $(REVIEW_APP_CONFIGURE_OVERRIDES),\
	  nht configure $(VAULT_NAME) $$(cat $(REVIEW_APP_FILE)) --overrides "$(REVIEW_APP_CONFIGURE_OVERRIDES)", \
	  nht configure $(VAULT_NAME) $$(cat $(REVIEW_APP_FILE)) --overrides NODE_ENV=branch \
	)

gtg-review-app: review-app
	nht gtg $$(cat $(REVIEW_APP_FILE))

# To override custom environment variables when running `nht configure`,
# add `REVIEW_APP_CONFIGURE_OVERRIDES="NODE_ENV=branch,OTHER_VAR=something" to the Makefile`
test-review-ap%: ## test-review-app: Create and test a review app on heroku
	$(MAKE) gtg-review-app
	TEST_URL="https://$$(cat $(REVIEW_APP_FILE)).herokuapp.com" \
		$(MAKE) smoke a11y
	# Destroy review app if it passes tests on the master branch
ifeq ($(CIRCLE_BRANCH),master)
	heroku destroy -a $$(cat $(REVIEW_APP_FILE)) --confirm $$(cat $(REVIEW_APP_FILE))
endif
	@$(DONE)
