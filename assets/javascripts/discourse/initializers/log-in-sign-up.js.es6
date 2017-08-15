import { withPluginApi } from 'discourse/lib/plugin-api'

export default {
  name: 'log-in-sign-up',
  initialize () {
    withPluginApi('0.7', api => {

      api.reopenWidget('header-buttons', {
        html(attrs) {
          if (this.currentUser) { return }
          return this.attach('button', {
            contents: api.h('span.d-button-label', I18n.t('log_in') + " / " + I18n.t('sign_up')),
            className: 'btn-primary btn-small login-button',
            action: 'showLogin'
          })
        }
      })

    })
  }
}
