import { ajax } from 'discourse/lib/ajax'

const Mapping = Ember.Object.extend({
  asJSON () {
    return {
      group_name: this.get('group_name'),
      iam_group_name: this.get('iam_group_name'),
      authoritative: this.get('authoritative')
    }
  },

  create () {
    return ajax('/mozilla_iam/admin/mappings', { type: 'POST', data: this.asJSON() })
  },

  update () {
    var id = this.get('id')
    return ajax(`/mozilla_iam/admin/mappings/${id}`, { type: 'PATCH', data: this.asJSON() })
  },

  destroy () {
    var id = this.get('id')
    return ajax(`/mozilla_iam/admin/mappings/${id}`, { type: 'DELETE' })
  }
})

Mapping.reopenClass({
  find (id) {
    return ajax(`/mozilla_iam/admin/mappings/${id}`).then(result => {
      return Mapping.create(result.group_mapping)
    })
  },

  findAll () {
    return ajax('/mozilla_iam/admin/mappings').then(result => {
      return result.map(mapping => Mapping.create(mapping))
    })
  }
})

export default Mapping
