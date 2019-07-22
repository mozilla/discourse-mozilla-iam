import { acceptance } from "helpers/qunit-helpers"
import user_fixtures from "fixtures/user_fixtures"
import SignUpController from "discourse/plugins/mozilla-iam/discourse/controllers/dinopark-sign-up"

acceptance("Mozilla IAM - Sign Up")

// prevent redirecting out of tests
SignUpController.reopen({
  redirect(url) {}
})

const data = {
  auth_provider: "auth0",
  destination_url: "/",
  email: "eviltrout@mozilla.com",
  email_valid: true,
  name: "Eviltrout",
  omit_username: false,
  username: "eviltrout"
}

const dinopark_data = Object.assign(
  {
    dinopark_profile: {
      description: "A rather nasty [fish](example.com)",
      full_name: "Evil Trout",
      fun_title: "Ember Supremo",
      location: "The Ocean",
      pronouns: "fi/sh",
      username: "evil_trout"
    }
  },
  data
)

const assertNormalModal = assert => {
  assert.ok(
    exists(".modal .create-account"),
    "opens normal create account modal"
  )

  assert.equal(
    find("#new-account-email").val(),
    "eviltrout@mozilla.com",
    "email is filled in correctly"
  )

  assert.equal(
    find("#new-account-username").val(),
    "eviltrout",
    "username is filled in correctly"
  )

  assert.equal(
    find("#new-account-name").val(),
    "Eviltrout",
    "name is filled in correctly"
  )
}

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
    "opens normal create account modal"
  )

  await click(".modal-footer .btn:not(.btn-primary)")

  assertNormalModal(assert)
})

QUnit.test("sign up with dinopark enabled", async assert => {
  await visit("/");

  Discourse.authenticationComplete(dinopark_data)
  await new Promise(r => setTimeout(r, 0))

  assert.ok(
    exists(".modal .dinopark-sign-up"),
    "opens normal create account modal"
  )

  assert.ok(
    exists(".modal-footer .btn-primary:disabled"),
    "continue button is disabled"
  )

  await click("#tos-checkbox")

  await click(".modal-footer .btn-primary")

  assert.equal(
    find(".dinopark-fields .value-username").text(),
    "evil_trout",
    "dinopark username is filled in"
  )

  assert.equal(
    find(".dinopark-fields .value-name").text(),
    "Evil Trout",
    "dinopark name is filled in"
  )

  assert.equal(
    find(".dinopark-fields .value-pronouns").text(),
    "fi/sh",
    "dinopark pronouns is filled in"
  )

  assert.equal(
    find(".dinopark-fields .value-title").text(),
    "Ember Supremo",
    "dinopark title is filled in"
  )

  assert.equal(
    find(".dinopark-fields .value-location").text(),
    "The Ocean",
    "dinopark location is filled in"
  )

  assert.equal(
    find(".dinopark-fields .value-bio").text().trim(),
    "A rather nasty fish",
    "dinopark bio is filled in"
  )

  await click("#tos-checkbox")

  assert.ok(
    exists(".modal-footer .btn-primary:disabled"),
    "confirm button is disabled"
  )

  await click("#tos-checkbox")

  await click(".modal-footer .btn-primary")

  assert.notOk(
    exists(".modal-footer .btn"),
    "buttons are hidden"
  )

  assert.ok(
    exists(".modal-footer .spinner"),
    "spinner is shown"
  )
})
