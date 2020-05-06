import { acceptance } from "helpers/qunit-helpers"
import user_fixtures from "fixtures/user_fixtures"

acceptance("Mozilla IAM - User Preferences Profile", {
  loggedIn: true
})

const response = (server, mozilla_iam) => {
  server.get("/u/eviltrout.json", () => {
    var json = Object(user_fixtures["/u/eviltrout.json"])
    Object.assign(json.user, {
      can_edit: true,
      can_change_bio: true,
      can_change_website: true,
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

const getDisplay = selector => {
  return window.getComputedStyle(find(selector)[0]).getPropertyValue("display")
}

QUnit.test("viewing self without dinopark enabled", async assert => {
  response(server, {})

  await visit("/u/eviltrout/preferences/profile")

  assert.equal(
    getDisplay(".pref-bio:not(.pref-dinopark-bio)"),
    "block",
    "normal bio pref is shown"
  )

  assert.notOk(
    exists(".pref-dinopark-bio"),
    "dinopark bio pref isn't shown"
  )

  assert.equal(
    getDisplay(".pref-location:not(.pref-dinopark-location)"),
    "block",
    "normal location pref is shown"
  )

  assert.notOk(
    exists(".pref-dinopark-location"),
    "dinopark location pref isn't shown"
  )

  assert.equal(
    getDisplay(".pref-website:not(.pref-dinopark-website)"),
    "block",
    "normal website pref is shown"
  )

  assert.notOk(
    exists(".pref-dinopark-website"),
    "dinopark website pref isn't shown"
  )
})

QUnit.test("viewing self with dinopark enabled", async assert => {
  response(server, { dinopark_enabled: true })

  await visit("/u/eviltrout/preferences/profile")

  assert.equal(
    getDisplay(".pref-bio:not(.pref-dinopark-bio)"),
    "none",
    "normal bio pref is hidden"
  )

  assert.equal(
    getDisplay(".pref-dinopark-bio"),
    "block",
    "dinopark bio pref is shown"
  )

  assert.equal(
    getDisplay(".pref-location:not(.pref-dinopark-location)"),
    "none",
    "normal location pref is hidden"
  )

  assert.equal(
    getDisplay(".pref-dinopark-location"),
    "block",
    "dinopark location pref is shown"
  )

  assert.equal(
    getDisplay(".pref-website:not(.pref-dinopark-website)"),
    "none",
    "normal website pref is hidden"
  )

  assert.equal(
    getDisplay(".pref-dinopark-website"),
    "block",
    "dinopark website pref is shown"
  )
})
