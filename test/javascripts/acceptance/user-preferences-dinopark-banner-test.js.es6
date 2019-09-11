import { acceptance } from "helpers/qunit-helpers"
import user_fixtures from "fixtures/user_fixtures"
import ModalController from "discourse/plugins/mozilla-iam/discourse/controllers/dinopark-unlink-modal"

acceptance("Mozilla IAM - User Preferences Dinopark Banner", {
  loggedIn: true
})

const response = (server, mozilla_iam) => {
  server.get("/u/eviltrout.json", () => {
    var json = Object(user_fixtures["/u/eviltrout.json"])
    Object.assign(json.user, {
      can_edit: true,
      email: "eviltrout@example.com",
      mozilla_iam
    })
    return [
      200,
      { "Content-Type": "application/json" },
      json
    ]
  })
}

QUnit.test("viewing self without dinopark enabled", async assert => {
  response(server, {})

  await visit("/u/eviltrout/preferences/account")

  assert.notOk(
    exists(".dinopark-preferences-banner"),
    "dinopark preferences banner is hidden"
  )
})

QUnit.test("viewing self with dinopark enabled", async assert => {
  response(server, { dinopark_enabled: true })

  assert.expect(9)
  server.post("/mozilla_iam/dinopark_unlink.json", () => {
    assert.ok(true, "sends POST to dinopark_unlink.json")
    return [
      200,
      { "Content-Type": "application/json" },
      { success: true }
    ]
  })

  ModalController.reopen({
    reload() {
      assert.ok(true, "the page is refreshed")
    }
  })

  await visit("/u/eviltrout/preferences/account")

  assert.ok(
    exists(".dinopark-preferences-banner"),
    "dinopark preferences banner is shown"
  )

  assert.notOk(
    exists(".dinopark-unlink-modal"),
    "dinopark unlink modal isn't shown"
  )

  await click(".dinopark-preferences-banner .buttons .unlink")

  assert.ok(
    exists(".dinopark-unlink-modal"),
    "dinopark unlink modal is shown"
  )

  assert.equal(
    find(".dinopark-unlink-modal .value-username").text(),
    "eviltrout",
    "username is shown"
  )

  assert.equal(
    find(".dinopark-unlink-modal .value-name").text(),
    "Robin Ward",
    "name is shown"
  )

  assert.equal(
    find(".dinopark-unlink-modal .value-bio").text(),
    "Co-founder of Discourse. Previously, I created Forumwarz. Follow me on Twitter. I am @eviltrout.",
    "about me is shown"
  )

  assert.equal(
    find(".dinopark-unlink-modal .value-location").text(),
    "Toronto",
    "location is shown"
  )

  await click(".modal-footer .btn-primary")
})

QUnit.test("viewing self with dinopark enabled - opening unlink modal - clicking cancel", async assert => {
  response(server, { dinopark_enabled: true })

  assert.expect(1)
  server.post("/mozilla_iam/dinopark_unlink.json", () => {
    assert.ok(true, "sends POST to dinopark_unlink.json")
    return [
      200,
      { "Content-Type": "application/json" },
      { success: true }
    ]
  })

  await visit("/u/eviltrout/preferences/account")

  await click(".dinopark-preferences-banner .buttons .unlink")

  await click(".modal-footer .btn:not(.btn-primary)")

  assert.notOk(
    exists(".dinopark-unlink-modal"),
    "unlink modal is closed"
  )
})
