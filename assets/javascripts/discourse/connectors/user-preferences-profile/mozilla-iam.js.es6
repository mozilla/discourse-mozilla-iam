import dinoparkEnabled from "discourse/plugins/mozilla-iam/discourse/lib/dinopark-enabled"

export default {
  setupComponent(args, component) {
    dinoparkEnabled(args.model)
  }
}
