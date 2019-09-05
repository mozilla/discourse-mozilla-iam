import { withPluginApi } from 'discourse/lib/plugin-api'
import showModal from "discourse/lib/show-modal"

export default {
  name: 'dinopark-log-in',
  initialize () {
    withPluginApi('0.8.30', api => {

      var data = $.cookie("authentication_data")
      $.removeCookie("authentication_data", { path: "/" })

      if (data) {
        data = JSON.parse(data)
      }

      if (data && data.dinopark_profile) {
        const dinoparkLinkModalController = api._lookupContainer("controller:dinopark-link-modal")
        dinoparkLinkModalController.setProperties({
          mode: "login",
          options: data
        })
        const router = api._lookupContainer("router:main")
        router.one("didTransition", () => {
          Ember.run.next(() =>
            showModal("dinopark-link-modal")
          )
        })
      }

    })
  }
}
