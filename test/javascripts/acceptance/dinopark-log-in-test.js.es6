import { acceptance } from "helpers/qunit-helpers"
import user_fixtures from "fixtures/user_fixtures"
import ModalController from "discourse/plugins/mozilla-iam/discourse/controllers/dinopark-link-modal"
import { data, dinopark_data, assertDinoparkModal } from "discourse/plugins/mozilla-iam/helpers/dinopark-prompt"

acceptance("Mozilla IAM - Log In", {
  loggedIn: true
})

// prevent redirecting out of tests
ModalController.reopen({
  redirect(url) {}
})

QUnit.test("log in without dinopark enabled", async assert => {
  $.cookie("authentication_data", JSON.stringify(data))
  await visit("/")

  assert.notOk(
    exists(".modal .dinopark-link-modal"),
    "doesn't open modal"
  )

  assert.equal(
    $.cookie("authentication_data"),
    undefined,
    "removes authentication_data cookie"
  )
})

QUnit.test("log in with dinopark enabled", async assert => {
  server.post("/mozilla_iam/dinopark_link.json", () => [
    200,
    { "Content-Type": "application/json" },
    { success: true }
  ])

  $.cookie("authentication_data", JSON.stringify(dinopark_data))
  await visit("/")

  await assertDinoparkModal(assert)

  assert.equal(
    $.cookie("authentication_data"),
    undefined,
    "removes authentication_data cookie"
  )
})

QUnit.test("log in with dinopark enabled - clicking not right now", async assert => {
  $.cookie("authentication_data", JSON.stringify(dinopark_data))
  await visit("/")

  assert.ok(
    exists(".modal .dinopark-link-modal"),
    "opens modal"
  )

  await click(".modal-footer .btn:not(.btn-primary)")

  assert.notOk(
    exists(".modal .dinopark-link-modal"),
    "closes modal"
  )

  assert.equal(
    $.cookie("authentication_data"),
    undefined,
    "removes authentication_data cookie"
  )
})

QUnit.test("log in with dinopark enabled - clicking don't show this again", async assert => {
  assert.expect(4)
  server.post("/mozilla_iam/dinopark_link/dont_show.json", () => {
    assert.ok(true, "sends POST to dinopark_link/dont_show")
    return [
      200,
      { "Content-Type": "application/json" },
      { success: true }
    ]
  })

  $.cookie("authentication_data", JSON.stringify(dinopark_data))
  await visit("/")

  assert.ok(
    exists(".modal .dinopark-link-modal"),
    "opens modal"
  )

  await click(".modal-footer .d-modal-cancel")

  assert.notOk(
    exists(".modal .dinopark-link-modal"),
    "closes modal"
  )

  assert.equal(
    $.cookie("authentication_data"),
    undefined,
    "removes authentication_data cookie"
  )
})

QUnit.test("log in with dinopark enabled - failure", async assert => {
  server.post("/mozilla_iam/dinopark_link.json", () => [
    200,
    { "Content-Type": "application/json" },
    {}
  ])

  $.cookie("authentication_data", JSON.stringify(dinopark_data))
  await visit("/")

  await assertDinoparkModal(assert, true)

  assert.equal(
    find(".modal .alert-error").text().trim(),
    "Something went wrong. Please try again.",
    "shows error message"
  )

  assert.equal(
    $.cookie("authentication_data"),
    undefined,
    "removes authentication_data cookie"
  )
})
