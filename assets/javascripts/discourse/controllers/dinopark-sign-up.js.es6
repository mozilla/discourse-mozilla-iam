import ModalFunctionality from "discourse/mixins/modal-functionality"
import showModal from "discourse/lib/show-modal"
import { on } from "ember-addons/ember-computed-decorators"
import { ajax } from "discourse/lib/ajax"
import { userPath } from "discourse/lib/url"

export default Ember.Controller.extend(ModalFunctionality, {
  createAccount: Ember.inject.controller("create-account"),

  showingConfirm: false,
  values: {},
  tosChecked: false,
  submitted: false,

  @on("init")
  fetchConfirmationValue() {
    return ajax(userPath("hp.json")).then(json => {
      this.setProperties({
        accountPasswordConfirm: json.value,
        accountChallenge: json.challenge
          .split("")
          .reverse()
          .join("")
      });
    });
  },

  redirect(url) {
    window.location = url
  },

  actions: {
    normalSignup() {
      const options = this.get("options")
      const createAccountController = this.get("createAccount")
      createAccountController.setProperties({
        accountEmail: options.email,
        accountUsername: options.username,
        accountName: options.name,
        authOptions: Ember.Object.create(options)
      })
      showModal("createAccount")
    },

    findProfile() {
      this.set("showingConfirm", true)
      this.set("values", this.get("options.dinopark_profile"))
    },

    confirm() {
      this.set("submitted", true)
      return ajax(userPath(), {
        data: {
          username: this.get("options").dinopark_profile.username,
          email: this.get("options").email,
          password_confirmation: this.get("accountPasswordConfirm"),
          challenge: this.get("accountChallenge"),
          dinopark_enabled: true
        },
        type: "POST"
      }).then(result => {
        if (result.success) {
          var destination_url = this.get("options.destination_url")
          this.redirect(destination_url ? destination_url : "/")
        } else {
          this.set("submitted", false)
          this.flash(result.message || I18n.t("create_account.failed"), "error")
        }
      }, () => {
        this.set("submitted", false)
        this.flash(I18n.t("create_account.failed"), "error")
      })
    }
  }
});
