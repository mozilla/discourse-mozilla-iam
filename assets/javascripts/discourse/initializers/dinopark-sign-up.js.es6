import { withPluginApi } from 'discourse/lib/plugin-api'
import showModal from "discourse/lib/show-modal"

export default {
  name: 'dinopark-sign-up',
  initialize () {
    withPluginApi('0.8.30', api => {

      api.modifyClass("controller:login", {
        dinoparkLinkModalController: Ember.inject.controller("dinopark-link-modal"),

        authenticationComplete(options) {
          if (options.dinopark_profile) {
            const dinoparkLinkModalController = this.get("dinoparkLinkModalController")
            dinoparkLinkModalController.setProperties({
              options: options
            })
            showModal("dinopark-link-modal")
          } else {
            this._super(options)
          }
        }
      })

    })
  }
}
