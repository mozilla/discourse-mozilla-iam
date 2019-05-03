import { withPluginApi } from 'discourse/lib/plugin-api'

export default {
  name: 'mozilla-iam-username-refresh',
  initialize () {
    withPluginApi('0.8.30', api => {

      const messageBus = api._lookupContainer("message-bus:main")

      messageBus.subscribe("/mozilla-iam/username-refresh", ([old_username, new_username]) => {
        const path = document.location.pathname
        const user_path = `/u/${old_username}/`
        if (path.startsWith(user_path)) {
          document.location.replace(path.replace(user_path, `/u/${new_username}/`))
        } else {
          document.location.reload()
        }
      })

    })
  }
}
