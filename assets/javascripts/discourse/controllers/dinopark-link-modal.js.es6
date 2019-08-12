import ModalFunctionality from "discourse/mixins/modal-functionality"
import showModal from "discourse/lib/show-modal"
import computed, { on } from "ember-addons/ember-computed-decorators"
import { ajax } from "discourse/lib/ajax"
import { userPath } from "discourse/lib/url"

export default Ember.Controller.extend(ModalFunctionality, {
  createAccount: Ember.inject.controller("create-account"),

  showingConfirm: false,
  values: {},
  tosChecked: false,
  submitted: false,
  mode: "sign_up",

  @computed("mode")
  isLogin(mode) {
    return mode == "login"
  },

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

  success() {
    var destination_url = this.get("options.destination_url")
    this.redirect(destination_url ? destination_url : "/")
  },

  fail(error) {
    this.set("submitted", false)
    this.flash(error, "error")
  },

  actions: {
    dismiss() {
      if (this.get("mode") == "login") {
        this.modal.send("closeModal")
      } else {
        this.normalSignup()
      }
    },

    dontShowAgain() {
      this.modal.send("closeModal")
      return ajax("/mozilla_iam/dinopark_link/dont_show.json", {
        type: "POST"
      })
    },

    findProfile() {
      this.set("showingConfirm", true)
      this.set("values", this.get("options.dinopark_profile"))
    },

    confirm() {
      this.set("submitted", true)
      if (this.get("mode") == "login") {
        return ajax("/mozilla_iam/dinopark_link.json", {
          type: "POST"
        }).then(result => {
          if (result.success) {
            $.removeCookie("authentication_data")
            this.success()
          } else {
            this.fail(result.message || I18n.t("dinopark.link_failed"))
          }
        }, () => {
          this.fail(I18n.t("dinopark.link_failed"))
        })
      } else {
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
            this.success()
          } else {
            this.fail(result.message || I18n.t("create_account.failed"))
          }
        }, () => {
          this.fail(I18n.t("create_account.failed"))
        })
      }
    }
  }
});
