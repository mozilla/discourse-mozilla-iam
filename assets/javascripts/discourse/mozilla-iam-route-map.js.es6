export default {
  resource: 'admin.adminPlugins',
  path: '/plugins',
  map () {
    this.route('mozilla-iam', function () {
      this.route('mappings', function () {
        this.route('new')
        this.route('edit', { path: '/:mapping_id' })
      })
    })
  }
}
