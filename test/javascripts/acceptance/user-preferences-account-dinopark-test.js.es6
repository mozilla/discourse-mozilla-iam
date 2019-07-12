import { acceptance } from "helpers/qunit-helpers"
import user_fixtures from "fixtures/user_fixtures"

acceptance("Mozilla IAM - User Preferences Account", {
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

const getDisplay = selector => {
  return window.getComputedStyle(find(selector)[0]).getPropertyValue("display")
}

QUnit.test("viewing self without dinopark enabled", async assert => {
  response(server, {})

  await visit("/u/eviltrout/preferences/account")

  assert.equal(
    getDisplay(".pref-username:not(.pref-dinopark-username)"),
    "block",
    "normal username pref is shown"
  )

  assert.notOk(
    exists(".pref-dinopark-username"),
    "dinopark username pref isn't shown"
  )

  assert.equal(
    getDisplay(".pref-name:not(.pref-dinopark-name)"),
    "block",
    "normal name pref is shown"
  )

  assert.notOk(
    exists(".pref-dinopark-name"),
    "dinopark name pref isn't shown"
  )

  assert.equal(
    getDisplay(".pref-title:not(.pref-dinopark-title)"),
    "block",
    "normal title pref is shown"
  )

  assert.notOk(
    exists(".pref-dinopark-title"),
    "dinopark title pref isn't shown"
  )
})

QUnit.test("viewing self without dinopark enabled but dinopark avatars enabled", async assert => {
  response(server, {})
  Discourse.set("SiteSettings.dinopark_avatars_enabled", true)

  await visit("/u/eviltrout/preferences/account")

  assert.equal(
    getDisplay(".pref-avatar:not(.pref-dinopark-avatar)"),
    "block",
    "normal avatar pref is shown"
  )

  assert.notOk(
    exists(".pref-dinopark-avatar"),
    "dinopark avatar pref isn't shown"
  )
})

QUnit.test("viewing self with dinopark enabled", async assert => {
  response(server, { dinopark_enabled: true })

  await visit("/u/eviltrout/preferences/account")

  assert.equal(
    getDisplay(".pref-username:not(.pref-dinopark-username)"),
    "none",
    "normal username pref is hidden"
  )

  assert.equal(
    getDisplay(".pref-dinopark-username"),
    "block",
    "dinopark username pref is shown"
  )

  assert.equal(
    getDisplay(".pref-name:not(.pref-dinopark-name)"),
    "none",
    "normal name pref is hidden"
  )

  assert.equal(
    getDisplay(".pref-dinopark-name"),
    "block",
    "dinopark name pref is shown"
  )

  assert.equal(
    getDisplay(".pref-title:not(.pref-dinopark-title)"),
    "none",
    "normal title pref is hidden"
  )

  assert.equal(
    getDisplay(".pref-dinopark-title"),
    "block",
    "dinopark title pref is shown"
  )
})

QUnit.test("viewing self with dinopark and dinopark avatars enabled", async assert => {
  response(server, { dinopark_enabled: true })
  Discourse.set("SiteSettings.dinopark_avatars_enabled", true)

  await visit("/u/eviltrout/preferences/account")

  assert.equal(
    getDisplay(".pref-avatar:not(.pref-dinopark-avatar)"),
    "none",
    "normal avatar pref is hidden"
  )

  assert.equal(
    getDisplay(".pref-dinopark-avatar"),
    "block",
    "normal avatar pref is shown"
  )
})
