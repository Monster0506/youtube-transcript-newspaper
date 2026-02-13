import Route from '@ember/routing/route';

export default class ApplicationRoute extends Route {
  queryParams = {
    v: { refreshModel: false },
  };

  setupController(controller, model) {
    super.setupController(controller, model);
    if (controller.v) {
      controller.videoUrl = controller.v;
      controller.autoLoad();
    }
  }
}
