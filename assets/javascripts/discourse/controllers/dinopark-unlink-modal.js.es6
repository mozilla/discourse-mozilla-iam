import ModalFunctionality from "discourse/mixins/modal-functionality"
import { ajax } from "discourse/lib/ajax"

export default Ember.Controller.extend(ModalFunctionality, {

  reload(url) {
    window.location.reload()
  },

  actions: {
    continue() {
      this.set("submitted", true)
      return ajax("/mozilla_iam/dinopark_unlink.json", {
        type: "POST"
      }).then(result => {
        if (result.success) {
          this.reload()
        } else {
          this.fail(result.message || I18n.t("dinopark.unlink.failed"))
        }
      }, () => {
        this.fail(I18n.t("dinopark.unlink.failed"))
      })
    },

    cancel() {
      this.modal.send("closeModal")
    }
  }
});
