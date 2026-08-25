{
  config,
  pkgs,
  ...
}:
{
  services.gitea = {
    enable = true;
    package = pkgs.gitea;

    # Configurable directories.
    stateDir = "/var/lib/gitea";
    repositoryRoot = "/var/lib/gitea/repositories";
    customDir = "/vat/lib/gitea/custom";
    user = "gitea";
    group = "gitea";
    appName = "gitea";

    # Extra BS
    captcha.enable = false;
    dump.enable = false;
    lfs.enable = false;
    camoHmacKeyFile = null;
    mailerPasswordFile = null;
    metricsTokenFile = null;
    minioAccessKeyId = null;
    minioSecretAccessKey = null;

    # Extra Config appened to config file.
    extraConfig = null;

    settings = {
      session.COOKIE_SECURE = false;
      service.DISABLE_REGISTRATION = false;
      server = {
        DOMAIN = "localhost";
        PROTOCOL = "http";
        HTTP_ADDR = "0.0.0.0";
        HTTP_PORT = 3000;
        ROOT_URL = "localhost:3000";
        STATIC_ROOT_PATH = config.services.gitea.package.data;
        SSH_PORT = 22;
        DISABLE_SSH = false;
      };
      log = {
        LEVEL = "Info";
        ROOT_PATH = "/var/lib/gitea/log";
      };
    };
    database = {
      type = "sqlite3";
      host = "127.0.0.1";
      port = 3306;
      name = "gitea";
      user = "gitea";
      password = null;
      socket = "/run/mysqld/mysqld.sock";
      path = "/var/lib/gitea/data/gitea.db";
      createDatabase = true;
    };
  };
}
