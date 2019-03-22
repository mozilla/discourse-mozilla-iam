export default {
  setupComponent(args, component) {
    var custom_fields = args.model.mozilla_iam
    if (custom_fields) {
      var dinopark_enabled = custom_fields.dinopark_enabled
      if (dinopark_enabled === true || dinopark_enabled === "t") {
        args.model.mozilla_iam.dinopark_enabled = true
      } else {
        args.model.mozilla_iam.dinopark_enabled = false
      }
    }
  }
}
