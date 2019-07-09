export default {
  setupComponent(args, component) {
    if ($.cookie("show_dinopark_banner")) {
      component.set("visible", true)
    }
  },

  actions: {
    dismiss() {
      this.set("visible", false)
      $.removeCookie("show_dinopark_banner")
    },

    click(e) {
      if ($(e.target).is('a')) {
        $.removeCookie("show_dinopark_banner")
      }
    }
  },

  shouldRender(args, component) {
    if (component.currentUser) {
      return $.cookie("show_dinopark_banner")
    } else {
      $.removeCookie("show_dinopark_banner")
      return false
    }
  }
}
