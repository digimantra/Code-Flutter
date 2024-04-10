class LocalServer {
  final int port = 52982;
  static String fullServerUrl = '';
  static String clientIP = '';

  Future<void> init() async {
    final ip = await _getIp();

    if (ip != null) {
      final miniServer = MiniServer(host: ip, port: port);
      _setupAPICalls(miniServer);
      fullServerUrl = 'http://$ip:$port';
      clientIP = ip;
      debugPrint("Running Server on - $fullServerUrl");
    }
  }

  Future<String?> _getIp() async {
    for (var interface in await NetworkInterface.list()) {
      for (var addr in interface.addresses) {
        if (addr.type.name.toLowerCase().contains(ipv4Constant)) {
          return addr.address;
        }
      }
    }

    return null;
  }

  void _setupAPICalls(MiniServer server) {
    server.post(updateClient, (HttpRequest httpRequest) async {
      MiniResponse res = await MiniResponse.instance.init(httpRequest);

      if (res.body != null) {
        await getIt<SharedPreferences>()
            .setString(prefKeyData, json.encode(res.body));

        if (navigatorKey.currentContext != null) {
          Provider.of<ProtectionProvider>(navigatorKey.currentContext!,
                  listen: false)
              .dataUpdatedFromServer();
        }
      }
      return httpRequest.response.write(res.body);
    });
  }
}
