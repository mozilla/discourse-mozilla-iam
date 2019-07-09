import { acceptance } from "helpers/qunit-helpers"

acceptance("Mozilla IAM - Dinopark Welcome Banner", {
  loggedIn: true
})

QUnit.test("loading page without show_dinopark_banner cookie set", async assert => {
  $.removeCookie("show_dinopark_banner")
  await visit("/")

  assert.notOk(
    exists(".dinopark-welcome-banner"),
    "dinopark welcome banner is not shown"
  )
})

QUnit.test("loading page with show_dinopark_banner cookie set and clicking close", async assert => {
  $.cookie("show_dinopark_banner", 1)
  await visit("/")

  assert.ok(
    exists(".dinopark-welcome-banner"),
    "dinopark welcome banner is shown"
  )

  await click(".dinopark-welcome-banner .close")

  assert.notOk(
    exists(".dinopark-welcome-banner"),
    "clicking close buttons closes banner"
  )
  assert.equal(
    $.cookie("show_dinopark_banner"),
    null,
    "clicking close buttons removes cookie"
  )

  $.removeCookie("show_dinopark_banner")
})

QUnit.skip("loading page with show_dinopark_banner cookie set and clicking link", async assert => {
  $.cookie("show_dinopark_banner", 1)
  await visit("/")

  assert.ok(
    exists(".dinopark-welcome-banner"),
    "dinopark welcome banner is shown"
  )

  await click(".dinopark-welcome-banner a") // navigates qunit away

  assert.equal(
    $.cookie("show_dinopark_banner"),
    null,
    "clicking link removes cookie"
  )
  assert.equal(
    currentRouteName(),
    "preferences.account",
    "clicking link navigates to user preferences"
  )

  $.removeCookie("show_dinopark_banner")
})

acceptance("Mozilla IAM - Dinopark Welcome Banner - Logged Out")

QUnit.test("logged out user with cookie", async assert => {
  $.cookie("show_dinopark_banner", 1)
  await visit("/")

  assert.notOk(
    exists(".dinopark-welcome-banner"),
    "dinopark welcome banner isn't shown"
  )
  assert.equal(
    $.cookie("show_dinopark_banner"),
    null,
    "cookie is removed"
  )

  $.removeCookie("show_dinopark_banner")
})
