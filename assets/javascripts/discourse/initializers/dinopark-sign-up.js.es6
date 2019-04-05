import { withPluginApi } from 'discourse/lib/plugin-api'
import showModal from "discourse/lib/show-modal"

export default {
  name: 'dinopark-sign-up',
  initialize () {
    withPluginApi('0.8.30', api => {

      api.modifyClass("controller:login", {
        dinoparkSignUpController: Ember.inject.controller("dinopark-sign-up"),

        authenticationComplete(options) {
          if (options.dinopark_profile) {
            const dinoParkSignUpController = this.get("dinoparkSignUpController")
            dinoParkSignUpController.setProperties({
              options: options
            })
            showModal("dinopark-sign-up")
          } else {
            this._super(options)
          }
        }
      })

    })
  }
}
