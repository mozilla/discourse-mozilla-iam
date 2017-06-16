import Mapping from '../models/mapping'
import Group from 'discourse/models/group'

export default Ember.Controller.extend({
  status: '',

  groupFinder (term) {
    return Group.findAll({ search: term, ignore_automatic: true })
  },

  actions: {
    save () {
      this.set('status', 'Saving...')
      var feed = Mapping.create(this.get('model'))
      feed.create().then(() => {
        this.set('status', '')
        this.transitionToRoute('adminPlugins.mozilla-iam.mappings')
      })
    },

    destroy () {
      this.transitionToRoute('adminPlugins.mozilla-iam.mappings')
    }
  }
})
