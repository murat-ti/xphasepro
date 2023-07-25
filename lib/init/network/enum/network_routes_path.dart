enum NetworkRoutes {
  getList,
  getParameters,
  getThumb,
  getFile,
  delFile,
  getInformation,
  exitTimelapse,
  shutdown,
  formatUDisk,
  config,
  doCapture,
}

extension NetworkRoutesPath on NetworkRoutes {
  String get path {
    switch (this) {
      case NetworkRoutes.getList:
        return 'get_list';
      case NetworkRoutes.getParameters:
        return 'get_parameters';
      case NetworkRoutes.getThumb:
        return 'get_thumb';
      case NetworkRoutes.getFile:
        return 'get_file';
      case NetworkRoutes.delFile:
        return 'del_file';
      case NetworkRoutes.getInformation:
        return 'get_information';
      case NetworkRoutes.exitTimelapse:
        return 'exit_timelapse';
      case NetworkRoutes.shutdown:
        return 'shutdown';
      case NetworkRoutes.formatUDisk:
        return 'format_udisk';
      case NetworkRoutes.config:
        return 'config';
      case NetworkRoutes.doCapture:
        return 'do_capture';
      default:
        throw Exception('Route not found');
    }
  }
}
