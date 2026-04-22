class ServerConfig {
  final String name;
  final String baseUrl;
  final String startPath;

  const ServerConfig({
    required this.name,
    required this.baseUrl,
    required this.startPath,
  });

  String get fullUrl => '$baseUrl$startPath';
}

const List<ServerConfig> servers = [
  ServerConfig(
    name: 'Server 12',
    baseUrl: 'http://172.16.50.12',
    startPath: '/DHAKA-FLIX-12/',
  ),
  ServerConfig(
    name: 'Server 7',
    baseUrl: 'http://172.16.50.7',
    startPath: '/DHAKA-FLIX-7/',
  ),
  ServerConfig(
    name: 'Server 9',
    baseUrl: 'http://172.16.50.9',
    startPath: '/DHAKA-FLIX-9/',
  ),
  ServerConfig(
    name: 'Server 14',
    baseUrl: 'http://172.16.50.14',
    startPath: '/DHAKA-FLIX-14/',
  ),
  ServerConfig(
    name: 'Data Server',
    baseUrl: 'http://10.1.1.1',
    startPath: '/data/',
  ),
];

const String omdbApiKey = '7a0ed03d';
const String omdbBaseUrl = 'http://www.omdbapi.com/';

const List<String> videoExtensions = [
  '.mp4',
  '.mkv',
  '.avi',
  '.mov',
  '.wmv',
  '.flv',
  '.webm',
  '.m4v',
  '.mpg',
  '.mpeg',
  '.3gp',
  '.ts',
];

const List<String> imageExtensions = [
  '.jpg',
  '.jpeg',
  '.png',
  '.gif',
  '.bmp',
  '.webp',
];
