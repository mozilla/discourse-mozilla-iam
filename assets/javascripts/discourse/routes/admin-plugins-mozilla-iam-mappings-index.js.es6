import Mapping from '../models/mapping'

export default Discourse.Route.extend({
  model () {
    return Mapping.findAll().then(result => {
      return result
    })
  }
})
