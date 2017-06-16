import Group from 'discourse/models/group'

export default Ember.Controller.extend({
  status: '',

  groupFinder (term) {
    return Group.findAll({ search: term, ignore_automatic: true })
  },

  actions: {
    save () {
      this.set('status', 'Saving...')
      this.get('model').update().then(() => {
        this.set('status', '')
        this.transitionToRoute('adminPlugins.mozilla-iam.mappings')
      })
    },

    destroy () {
      this.set('status', 'Deleting...')
      this.get('model').destroy().then(() => {
        this.set('status', '')
        this.transitionToRoute('adminPlugins.mozilla-iam.mappings')
      })
    }
  }
})
