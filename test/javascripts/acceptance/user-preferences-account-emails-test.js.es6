import { acceptance } from "helpers/qunit-helpers"
import user_fixtures from "fixtures/user_fixtures"

acceptance("Mozilla IAM - User Preferences Account Emails", {
  loggedIn: true
})

const responseWithEmails = (primary, secondary) => {
  var json = Object(user_fixtures["/u/eviltrout.json"])
  json.user.can_edit = true
  if (primary) {
    json.user.email = "eviltrout@example.com"
  } else {
    json.user.email = null
  }
  json.user.secondary_emails = secondary
  return [
    200,
    { "Content-Type": "application/json" },
    json
  ]
}

const assertPrimary = assert => {
  assert.equal(
    find(".pref-mozilla-iam-primary-email .value").text().trim(),
    "eviltrout@example.com",
    "it should display the primary email"
  )
}

const assertSecondary = (assert, secondary) => {
  if (secondary.length) {
    assert.equal(
      find(".pref-mozilla-iam-secondary-emails .value li:first-of-type").text().trim(),
      secondary[0],
      "displays first secondary email"
    )
    assert.equal(
      find(".pref-mozilla-iam-secondary-emails .value li:last-of-type").text().trim(),
      secondary[1],
      "displays second secondary email"
    )
  } else {
    assert.equal(
      find(".pref-mozilla-iam-secondary-emails .value").text().trim(),
      "No secondary addresses",
      "it should not display secondary emails"
    )
  }
}

const assertShowEmailButton = assert => {
  assert.ok(
    exists(".pref-mozilla-iam-check-email"),
    "shows check email button"
  )

  assert.notOk(
    exists(".pref-mozilla-iam-primary-email"),
    "doesn't show primary email"
  )

  assert.notOk(
    exists(".pref-mozilla-iam-secondary-email"),
    "doesn't show secondary email"
  )
}

QUnit.test("viewing self without secondary emails", async assert => {
  server.get("/u/eviltrout.json", () => {
    return responseWithEmails(true, [])
  })

  await visit("/u/eviltrout/preferences/account")

  assertPrimary(assert)

  assertSecondary(assert, [])

  await click(".pref-mozilla-iam-primary-email .btn")

  assert.ok(
    exists("#change-email"),
    "shows change email input"
  )
})

QUnit.test("viewing self with secondary emails", async assert => {
  var secondary = [
    "eviltrout1@example.com",
    "eviltrout2@example.com",
  ]

  server.get("/u/eviltrout.json", () => {
    return responseWithEmails(true, secondary)
  })

  await visit("/u/eviltrout/preferences/account")

  assertPrimary(assert)

  assertSecondary(assert, secondary)
})

QUnit.test("viewing another user without secondary email", async assert => {
  server.get("/u/eviltrout.json", () => {
    return responseWithEmails(false, [])
  })

  await visit("/u/eviltrout/preferences/account")

  assertShowEmailButton(assert)

  await click(".pref-mozilla-iam-check-email button")

  assertPrimary(assert)
  assertSecondary(assert, [])
})

QUnit.test("viewing another user with secondary emails", async assert => {
  var secondary = ["eviltrout1@example.com", "eviltrout2@example.com"]

  server.get("/u/eviltrout.json", () => {
    return responseWithEmails(false, [])
  })

  server.get("/u/eviltrout/emails.json", () => {
    return [
      200,
      { "Content-Type": "application/json" },
      {
        email: "eviltrout@example.com",
        secondary_emails: secondary
      }
    ]
  })

  await visit("/u/eviltrout/preferences/account")

  assertShowEmailButton(assert)

  await click(".pref-mozilla-iam-check-email button")

  assertPrimary(assert)
  assertSecondary(assert, secondary)
})
