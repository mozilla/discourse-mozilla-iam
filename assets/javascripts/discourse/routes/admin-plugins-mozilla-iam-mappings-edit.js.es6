import Mapping from '../models/mapping'

export default Discourse.Route.extend({
  model (params) {
    return Mapping.find(params.mapping_id).then(result => {
      return result
    })
  }
})
