{lib, config, pkgs, ...}:
let
  cfg = config.firefox;

  bookmarkDir2Bookmarks = root: 
    (lib.lists.flatten
      (map
        (p: import p)
        (lib.filesystem.listFilesRecursive root)
      )
    );
in
{
  options = {
    firefox.enable = lib.mkEnableOption "Enable Firefox";
    firefox.bookmarksRoot = lib.mkOption { type = lib.types.path; };
  };

  config = {
    programs.firefox = lib.mkIf cfg.enable {
      enable = true;
      package = pkgs.firefox-esr;
      policies = {
        AllowFileSelectionDialogs = true;
        AppAutoUpdate = false;
        AutofillAddressEnabled = false;
        AutofillCreditCardEnabled = false;
        BackgroundAppUpdate = false;
        BlockAboutAddons = false;
        BlockAboutConfig = false;
        BlockAboutProfiles = false;
        BlockAboutSupport = false;
        Bookmarks = (bookmarkDir2Bookmarks cfg.bookmarksRoot );
        CaptivePortal = false;
        ContentAnalysis = { Enabled = false; };
        Cookies = {
          Behavior = "reject-tracker";
          Locked = false;
        };
        DisableAccounts = true;
        DisableAppUpdate = true;
        DisableFeedbackCommands = true;
        DisableFirefoxAccounts = true;
        DisableFirefoxScreenshots = true;
        DisableFirefoxStudies = true;
        DisableFormHistory = true;
        DisablePocket = true;
        DisableSystemAddonUpdate = true;
        DisableTelemetry = true;
        DisplayBookmarksToolbar = "newtab";
        DontCheckDefaultBrowser = true;
        DNSOverHTTPS = {
          Enabled = true;
          ProviderURL = "https://1.1.1.1";
        };
        EnableTrackingProtection = {
          Value = true;
          Locked = false;
          Cryptomining = true;
          Fingerprinting = true;
        };
        ExtensionSettings = {
          "uBlock0@raymondhill.net" = {
              install_url = "https://addons.mozilla.org/firefox/downloads/latest/ublock-origin/latest.xpi";
              installation_mode = "force_installed";
            };
        };
        ExtensionUpdate = false;
        SearchBar = "unified";
        FirefoxHome = {
          Search = true ;
          TopSites = false;
          SponsoredTopSites = false;
          Highlights = false;
          Pocket =  false;
          SponsoredPocket = false;
          Snippets = false;
          Locked =  false;
        };
        FirefoxSuggest = {
          webSuggestions = false;
          sponsoredSuggestions = false;
          ImproveSuggest = false;
          Locked = false;
        };
        HardwareAcceleration = true;
        HttpsOnlyMode = "enabled";
        NetworkPrediction = true;
        NoDefaultBookmarks = false;
        OfferToSaveLogins = false;
        OfferToSaveLoginsDefault = false;
        PasswordManagerEnabled = false;
        PictureInPicture = {
          Enabled = false;
        };
        PopupBlocking = {
          Default = true;
          Locked = false;
        };
        SanitizeOnShutdown = {
          Cache = true;
          Cookies = true;
          Downloads = true;
          FormData = true;
          History = true;
          Sessions = true;
          SiteSettings = true;
          OfflineApps = true;
          Locked = false;
        };
        SearchSuggestEnabled = false;
        ShowHomeButton = false;
        SearchEngines = {
          Default = "Google"; 
        };
      };
      preferences = {
        "privacy.donottrackheader.enabled" = true;
        "privacy.globalprivacycontrol.enabled" = true;
      };
    };
  };
}
