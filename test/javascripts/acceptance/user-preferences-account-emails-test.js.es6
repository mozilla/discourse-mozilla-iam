import { acceptance } from "helpers/qunit-helpers"
import user_fixtures from "fixtures/user_fixtures"

acceptance("Mozilla IAM - User Preferences Account Emails", {
  loggedIn: true
})

const responseWithUserData = data => {
  var json = Object(user_fixtures["/u/eviltrout.json"])
  Object.assign(json.user, { can_edit: true, email: "eviltrout@example.com" }, data)
  return [
    200,
    { "Content-Type": "application/json" },
    json
  ]
}

const responseWithEmails = (primary, secondary) => {
  var user = {}
  if (!primary) {
    user.email = null
  }
  user.secondary_emails = secondary
  return responseWithUserData(user)
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
    exists(".pref-mozilla-iam-secondary-emails"),
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

QUnit.test("viewing self without duplicate_accounts", async assert => {
  server.get("/u/eviltrout.json", () => {
    return responseWithUserData({ duplicate_accounts: [] })
  })
  
  await visit("/u/eviltrout/preferences/account")

  assert.notOk(
    exists(".pref-mozilla-iam-duplicate-accounts"),
    "doesn't show duplicate accounts section"
  )
})

QUnit.test("viewing self with duplicate_accounts", async assert => {
  server.get("/u/eviltrout.json", () => {
    return responseWithUserData({ duplicate_accounts: [
      { username: "foo", email: "one", secondary_emails: ["two", "three"] },
      { username: "bar", email: "bar@example.com"}
    ] })
  })

  server.get("/groups/admins/messageable", () => {
    return [200, { "Content-Type": "application/json" }, { messageable: true }]
  })

  await visit("/u/eviltrout/preferences/account")

  assert.ok(
    exists(".pref-mozilla-iam-duplicate-accounts"),
    "shows duplicate accounts section"
  )

  assert.equal(
    find(".pref-mozilla-iam-duplicate-accounts .value li:first-of-type .username").text().trim(),
    "foo",
    "displays first duplicate account username"
  )

  assert.equal(
    find(".pref-mozilla-iam-duplicate-accounts .value li:first-of-type .details li:nth-of-type(1)").text().trim(),
    "one",
    "displays first duplicate account primary email"
  )

  assert.equal(
    find(".pref-mozilla-iam-duplicate-accounts .value li:first-of-type .details li:nth-of-type(2)").text().trim(),
    "two",
    "displays first duplicate account first secondary email"
  )

  assert.equal(
    find(".pref-mozilla-iam-duplicate-accounts .value li:first-of-type .details li:nth-of-type(3)").text().trim(),
    "three",
    "displays first duplicate account second secondary email"
  )

  assert.equal(
    find(".pref-mozilla-iam-duplicate-accounts .value li:last-of-type .username").text().trim(),
    "bar",
    "displays second duplicate account username"
  )

  assert.equal(
    find(".pref-mozilla-iam-duplicate-accounts .value li:last-of-type .details").text().trim(),
    "bar@example.com",
    "displays second duplicate account email"
  )

  assert.ok(
    exists(".pref-mozilla-iam-duplicate-accounts .btn"),
    "displays merge accounts button"
  )

  await click(".pref-mozilla-iam-duplicate-accounts .btn")

  assert.equal(
    find(".composer-fields .users-input").text().trim(),
    "admins",
    "displays prefilled admin group in composer"
  )

  assert.equal(
    find("#reply-title").val(),
    "Merge user accounts",
    "displays prefilled title in composer"
  )

  assert.equal(
    find(".d-editor-input").val(),
    `Please merge these duplicate accounts:

* @foo
* @bar

into my account. Thanks!`,
    "displays prefilled message in composer"
  )
})

QUnit.test("viewing self without ldap account", async assert => {
  server.get("/u/eviltrout.json", () => {
    return responseWithUserData({
      email: "foo",
      mozilla_iam: {
        uid: "oauth2|firefoxaccounts|lmcardle"
      }
    })
  })

  await visit("/u/eviltrout/preferences/account")

  assert.notOk(
    find(".pref-mozilla-iam-secondary-emails + .instructions").text().includes(" ldap "),
    "doesn't show ldap aliases instruction"
  )
})

QUnit.test("viewing self with ldap account", async assert => {
  server.get("/u/eviltrout.json", () => {
    return responseWithUserData({
      email: "foo",
      mozilla_iam: {
        uid: "ad|Mozilla-LDAP|lmcardle"
      }
    })
  })

  await visit("/u/eviltrout/preferences/account")

  assert.ok(
    find(".pref-mozilla-iam-secondary-emails + .instructions").text().includes(" LDAP "),
    "shows ldap aliases instruction"
  )
})
