import 'package:equatable/equatable.dart';

/// A TV running VLC for Android with Remote access enabled, paired with a
/// session cookie obtained through VLC's one-time code login.
class VlcTv extends Equatable {
  /// VLC only accepts the login on its HTTPS port.
  static const defaultPort = 8443;

  /// VLC's plain HTTP port, used for playback.
  static const defaultHttpPort = 8080;

  final String host;
  final int port;
  final int httpPort;

  /// `user_session=<value>` cookie returned by VLC after pairing.
  final String cookie;

  const VlcTv({
    required this.host,
    required this.port,
    required this.cookie,
    this.httpPort = defaultHttpPort,
  });

  factory VlcTv.fromJson(Map<String, dynamic> json) => VlcTv(
    host: json['host'] as String,
    port: json['port'] as int,
    cookie: json['cookie'] as String,
    httpPort: json['httpPort'] as int? ?? defaultHttpPort,
  );

  Map<String, dynamic> toJson() => {
    'host': host,
    'port': port,
    'httpPort': httpPort,
    'cookie': cookie,
  };

  @override
  List<Object?> get props => [host, port, httpPort, cookie];
}
