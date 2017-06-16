export default Discourse.Route.extend({
  model () {
    return {}
  },
  renderTemplate () {
    this.render('admin-plugins-mozilla-iam-mappings-edit', {
      controller: 'admin-plugins-mozilla-iam-mappings-new'
    })
  },
  setupController (controller, model) {
    this.controllerFor('admin-plugins-mozilla-iam-mappings-new').set('model', model)
  }
})
