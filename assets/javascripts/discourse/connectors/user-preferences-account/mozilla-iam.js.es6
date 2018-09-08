export default {
  setupComponent(args, component) {
    if (args.model.duplicate_accounts) {
      var body = "Please merge these duplicate accounts:\n\n"
      args.model.duplicate_accounts.forEach(u => { body += `* @${u.username}\n` })
      body += "\ninto my account. Thanks!"
      component.set("message_admins_body", body)
    }
  },

  actions: {
    checkEmail(user) {
      user.checkEmail()
    }
  }
}
