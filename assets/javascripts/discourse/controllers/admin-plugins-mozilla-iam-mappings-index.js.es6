import Mapping from '../models/mapping'

export default Ember.Controller.extend({
  status: '',

  actions: {
    new () {
      this.transitionToRoute('adminPlugins.mozilla-iam.mappings.new')
    },

    refresh () {
      this.set('status', 'Refreshing...')
      Mapping.findAll().then(result => {
        this.set('model', result)
        this.set('status', '')
      })
    }
  }
})
