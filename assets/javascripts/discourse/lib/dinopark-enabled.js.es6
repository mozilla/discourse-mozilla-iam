export default function(model) {
  var custom_fields = model.mozilla_iam
  if (custom_fields) {
    var dinopark_enabled = custom_fields.dinopark_enabled
    if (dinopark_enabled === true || dinopark_enabled === "t") {
      model.set("mozilla_iam.dinopark_enabled", true)
    } else {
      model.set("mozilla_iam.dinopark_enabled", false)
    }
  }
}
