import { acceptance } from "helpers/qunit-helpers"

acceptance("Mozilla IAM - Admin User Details", {
  loggedIn: true
})

const response = (server, mozilla_iam) => {
  server.get("/admin/users/1.json", () => [
    200,
    { "Content-Type": "application/json" },
    {
      id: 1,
      username: "eviltrout",
      email: "eviltrout@example.com",
      mozilla_iam
    }
  ])
}

const assert_dinopark = (assert, value) => {
  assert.equal(
    find(".mozilla-iam.admin-user-details-outlet .dinopark-enabled .value").text().trim(),
    value,
    `dinopark enabled should show ${value}`
  )
}

QUnit.test("viewing profile with dinopark_enabled undefined", async assert => {
  response(server, {})

  await visit("/admin/users/1/eviltrout")

  assert_dinopark(assert, "False")
})

QUnit.test("viewing profile with dinopark_enabled set to anything but true", async assert => {
  response(server, {
    dinopark_enabled: "foo"
  })

  await visit("/admin/users/1/eviltrout")

  assert_dinopark(assert, "False")
})

QUnit.test("viewing profile with dinopark_enabled set to true", async assert => {
  response(server, {
    dinopark_enabled: true
  })

  await visit("/admin/users/1/eviltrout")

  assert_dinopark(assert, "True")
})

QUnit.test("viewing profile with dinopark_enabled set to 't'", async assert => {
  response(server, {
    dinopark_enabled: "t"
  })

  await visit("/admin/users/1/eviltrout")

  assert_dinopark(assert, "True")
})
