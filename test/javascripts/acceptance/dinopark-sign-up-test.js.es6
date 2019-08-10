import { acceptance } from "helpers/qunit-helpers"
import user_fixtures from "fixtures/user_fixtures"
import SignUpController from "discourse/plugins/mozilla-iam/discourse/controllers/dinopark-sign-up"
import { data, dinopark_data, assertNormalModal, assertDinoparkModal } from "discourse/plugins/mozilla-iam/helpers/dinopark-prompt"

acceptance("Mozilla IAM - Sign Up")

// prevent redirecting out of tests
SignUpController.reopen({
  redirect(url) {}
})

QUnit.test("sign up without dinopark enabled", async assert => {
  await visit("/");

  Discourse.authenticationComplete(data)
  await new Promise(r => setTimeout(r, 0))

  assertNormalModal(assert)
})

QUnit.test("sign up with dinopark enabled, clicking not right now", async assert => {
  await visit("/");

  Discourse.authenticationComplete(dinopark_data)
  await new Promise(r => setTimeout(r, 0))

  assert.ok(
    exists(".modal .dinopark-sign-up"),
    "opens dinopark link modal"
  )

  await click(".modal-footer .btn:not(.btn-primary)")

  assertNormalModal(assert)
})

QUnit.test("sign up with dinopark enabled", async assert => {
  await visit("/");

  Discourse.authenticationComplete(dinopark_data)
  await new Promise(r => setTimeout(r, 0))

  await assertDinoparkModal(assert)
})
