import showModal from "discourse/lib/show-modal"
import { ajax } from "discourse/lib/ajax"

export default {
  setupComponent(args, component) {
  },

  reload() {
    window.location.reload()
  },

  actions: {
    unlink() {
      const container = Discourse.__container__;
      const controller = container.lookup("controller:dinopark-unlink-modal")
      controller.setProperties({
        user: this.get("model")
      })
      showModal("dinopark-unlink-modal")
    },
  },

  shouldRender(args, component) {
    return args.model.get("mozilla_iam.dinopark_enabled")
  }
}
