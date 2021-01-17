/* eslint-disable camelcase */
const {
  promisify
} = require('util');

const fs = require('fs');
const path = require('path');
const chalk = require('chalk');
const wrap = require('wrap-ansi');
const validator = require('validator');
const coinstring = require('coinstring');
const inquirer = require('inquirer');
const colorsys = require('colorsys');
const ejs = require( 'ejs' );
const ejsRenderFileAsync = promisify( ejs.renderFile ).bind( ejs );

const html2ansi = require('./html2ansi.js');
const name = require('./name.js');
const Archive = require('./archive.js');
const TorGen = require('./torgen.js');
const ApiKey = require('./apikey.js');
const Cert = require('./cert.js');
const htpasswd = require( './htpasswd.js');
const Config = require('./config.js');
const SplashScreen = require( './splashScreen.js' );
const ansi = require( './ansi.js' );

const features = require('../features.json');
const torifyables = require('../torifyables.json');

const _000_cyphernode = require( '../prompters/000_cyphernode.js');
const _010_gatekeeper = require( '../prompters/010_gatekeeper.js');
const _030_traefik = require( '../prompters/030_traefik.js');
const _040_tor = require( '../prompters/040_tor.js');
const _100_lightning = require( '../prompters/100_lightning.js');
const _900_bitcoin = require( '../prompters/900_bitcoin.js');
const _999_installer = require( '../prompters/999_installer.js');

const help = require('../help.json');

const prompters = [
  _000_cyphernode, _010_gatekeeper,
  _030_traefik,
  _040_tor,
  _100_lightning,
  _900_bitcoin, _999_installer
];

const uaCommentRegexp = /^[a-zA-Z0-9 \.,:_\-\?\/@]+$/; // TODO: look for spec of unsafe chars
const userRegexp = /^[a-zA-Z0-9\._\-]+$/;
const maxWidth = 82;

const keyIds = {
  '000': ['stats'],
  '001': ['stats', 'watcher'],
  '002': ['stats', 'watcher', 'spender'],
  '003': ['stats', 'watcher', 'spender', 'admin']
};

const configArchiveFileName = 'config.7z';
const keyArchiveFileName = 'client.7z';
const destinationDirName = '.cyphernodeconf';

const prefix = () => {
  return chalk.green('Cyphernode')+': ';
};

const randomColor = () => {
  const hex = colorsys.hslToHex( {
    h: (Math.random()*360)<<0, s: 50, l: 50
  } );
  return hex.substr(1);
};

module.exports = class App {

  constructor() {

    this.sessionData = {
      defaultDataDirBase: process.env.DEFAULT_DATADIR_BASE ||  process.env.HOME,
      setupDir: process.env.SETUP_DIR || path.join( process.env.HOME, 'cyphernode' ),
      workDir: process.env.WORK_DIR || '/data',
      default_username: process.env.DEFAULT_USER || '',
      gatekeeper_version: process.env.GATEKEEPER_VERSION,
      tor_version: process.env.TOR_VERSION,
      gatekeeper_cns: process.env.DEFAULT_CERT_HOSTNAME,
      proxy_version: process.env.PROXY_VERSION,
      proxycron_version: process.env.PROXYCRON_VERSION,
      pycoin_version: process.env.PYCOIN_VERSION,
      traefik_version: process.env.TRAEFIK_VERSION,
      mosquitto_version: process.env.MOSQUITTO_VERSION,
      otsclient_version: process.env.OTSCLIENT_VERSION,
      bitcoin_version: process.env.BITCOIN_VERSION,
      lightning_version: process.env.LIGHTNING_VERSION,
      notifier_version: process.env.NOTIFIER_VERSION,
      conf_version: process.env.CONF_VERSION,
      admin_version: process.env.ADMIN_VERSION,
      setup_version: process.env.SETUP_VERSION,
      lightning_nodename: name.generate(),
      lightning_nodecolor: randomColor(),
      installer_cleanup: false,
      devmode: process.env.DEVMODE || false
    };

    this.features = features;
    this.torifyables = torifyables;

    if ( fs.existsSync(path.join(this.workDir(), destinationDirName, 'exitStatus.sh')) ) {
      fs.unlinkSync(path.join(this.workDir(), destinationDirName, 'exitStatus.sh'));
    }

    this.splash = new SplashScreen( {
      frameDir: path.join(__dirname, '..', 'splash' ),
      enableFortune: false,
      fortuneChalk: chalk.default.bold,
      width: maxWidth,
      fortuneSpacing: 3
    } );
  }

  async start( options ) {

    options = options || {
    };

    this.sessionData.noWizard = !!options.noWizard;
    this.sessionData.noSplashScreen = !!options.noSplashScreen;

    await this.setupConfigArchive();

    if ( !this.sessionData.noSplashScreen ) {
      await this.splash.show();
    }

    let missingProperties = [];

    if ( this.config.validateErrors && this.config.validateErrors.length ) {
      for ( let error of this.config.validateErrors ) {
        if ( error.keyword === 'required' && error.params && error.params.missingProperty ) {
          missingProperties.push( error.params.missingProperty );
        }
      }
    }

    if ( this.sessionData.noWizard && missingProperties.length && this.config.isLoaded ) {
      console.log(chalk.bold.red('Unable to migrate client.7z non-interactively. Rerun without the -r option') );
      process.exit(1);
    }

    if ( !this.sessionData.noWizard  ) {
      // save gatekeeper key password to check if it changed
      this.sessionData.gatekeeper_clientkeyspassword = this.config.data.gatekeeper_clientkeyspassword;
      if (  missingProperties.length && this.config.isLoaded ) {
        this.sessionData.markProperties = missingProperties;
      }
      await this.startWizard();
    }

    await this.processProps();
    await this.writeFiles();
  }

  async setupConfigArchive() {

    this.config = new Config( {
      setup_version: this.sessionData.setup_version,
      docker_versions: {
        'cyphernode/bitcoin': this.sessionData.bitcoin_version,
        'cyphernode/tor': this.sessionData.tor_version,
        'cyphernode/proxy': this.sessionData.proxy_version,
        'cyphernode/proxycron': this.sessionData.proxycron_version,
        'cyphernode/pycoin': this.sessionData.pycoin_version,
        'cyphernode/otsclient': this.sessionData.otsclient_version,
        'traefik': this.sessionData.traefik_version,
        'cyphernode/clightning': this.sessionData.lightning_version,
        'cyphernode/notifier': this.sessionData.notifier_version,
        'eclipse-mosquitto': this.sessionData.mosquitto_version
      }
    } );

    if ( !fs.existsSync(this.destinationPath(configArchiveFileName)) ) {
      if ( this.sessionData.noWizard ) {
        console.log(chalk.bold.red('Unable to run in no wizard mode without a config.7z')+'\n');
        process.exit();
        return;
      }
      let r = {
      };
      process.stdout.write(ansi.clear+ansi.reset);
      while ( !r.password0 || !r.password1 || r.password0 !== r.password1 ) {

        if ( r.password0 && r.password1 && r.password0 !== r.password1 ) {
          console.log(chalk.bold.red('Passwords do not match')+'\n');
        }

        r = await this.prompt([{
          type: 'password',
          name: 'password0',
          message: prefix()+chalk.bold.blue('Choose your configuration password'),
          filter: this.trimFilter
        },
        {
          type: 'password',
          name: 'password1',
          message: prefix()+chalk.bold.blue('Confirm your configuration password'),
          filter: this.trimFilter
        }]);
      }
      this.sessionData.configurationPassword = r.password0;
    } else {
      try {
        let r = {
        };
        if ( process.env.CFG_PASSWORD ) {
          this.sessionData.configurationPassword = process.env.CFG_PASSWORD;
        } else {
          process.stdout.write(ansi.reset);
          while ( !r.password ) {
            r = await this.prompt([{
              type: 'password',
              name: 'password',
              message: prefix()+chalk.bold.blue('Enter your configuration password?'),
              filter: this.trimFilter
            }]);
          }
          this.sessionData.configurationPassword = r.password;
        }
        try {
          await this.config.deserialize(
            this.destinationPath(configArchiveFileName),
            this.sessionData.configurationPassword,
          );

          // store clientkeyspassword in sessionData so it can be retrieved by getDefault
          // and a simple return will not result in a password mismatch
          if ( this.config.data.hasOwnProperty('gatekeeper_clientkeyspassword') ) {
            this.sessionData.gatekeeper_clientkeyspassword_c =
              this.config.data.gatekeeper_clientkeyspassword;
          }

        } catch (e) {
          console.log(chalk.bold.red(e));
          process.exit();
        }
      } catch ( err ) {
        console.log(chalk.bold.red('config archive is corrupt.'));
        process.exit(1);
      }
    }

    this.config.data.adminhash = await htpasswd(this.sessionData.configurationPassword);

    for ( let feature of this.features ) {
      feature.checked = this.isChecked( 'features', feature.value );
    }

    for ( let torifyable of this.torifyables ) {
      torifyable.checked = this.isChecked('features', 'tor') && this.isChecked( 'torifyables', torifyable.value );
    }
  }

  async startWizard() {
    let r = await this.prompt([{
      type: 'confirm',
      name: 'enablehelp',
      message: prefix()+'Enable help?',
      default: this.getDefault( 'enablehelp' ),
    }]);

    this.config.data.enablehelp = r.enablehelp;

    if ( this.config.data.enablehelp ) {
      this.help = help;
    }

    let prompts = [];

    for ( let m of prompters ) {
      let newPrompts = m.prompts(this);

      if ( this.sessionData.markProperties &&
        this.sessionData.markProperties.length &&
        this.config.isLoaded ) {

        for ( let prompt of newPrompts ) {
          if (  this.sessionData.markProperties.indexOf(prompt.name) !== -1  ) {
            prompt.message = prompt.message+' '+chalk.bgGreen('new option');
          }
        }
      }

      prompts = prompts.concat(newPrompts);
    }

    const props = await this.prompt(prompts);

    this.config.data = Object.assign(this.config.data, props);
  }

  async processProps() {

    // Tor...
    if ( this.isChecked( 'features', 'tor' ) ) {
      const torgen = new TorGen();

      if (this.isChecked('torifyables', 'tor_traefik')) {
        this.sessionData.tor_traefik_hostname = await torgen.generateTorFiles(this.destinationPath( path.join( destinationDirName, 'tor/traefik/hidden_service' ) ));
      }
      if (this.isChecked('torifyables', 'tor_lightning')) {
        this.sessionData.tor_lightning_hostname = await torgen.generateTorFiles(this.destinationPath( path.join( destinationDirName, 'tor/lightning/hidden_service' ) ));
      }
      if (this.isChecked('torifyables', 'tor_bitcoin')) {
        this.sessionData.tor_bitcoin_hostname = await torgen.generateTorFiles(this.destinationPath( path.join( destinationDirName, 'tor/bitcoin/hidden_service' ) ));
      }
    }

    // creates keys if they don't exist or we say so.
    if ( this.config.data.gatekeeper_recreatekeys ||
      this.config.data.gatekeeper_keys.configEntries.length===0 ) {

      delete this.config.data.gatekeeper_recreatekeys;

      let configEntries = [];
      let clientInformation = [];

      for ( let keyId in keyIds ) {
        const apikey = await this.createRandomKey( keyId, keyIds[keyId] );
        configEntries.push(apikey.getConfigEntry());
        clientInformation.push(apikey.getClientInformation());
      }

      this.config.data.gatekeeper_keys = {
        configEntries: configEntries,
        clientInformation: clientInformation
      };

    }

    const cert = new Cert();
    this.sessionData.cns = cert.cns(this.config.data.gatekeeper_cns);

    // create certs if they don't exist or we say so.
    if ( this.config.data.gatekeeper_recreatecert ||
      !this.config.data.gatekeeper_sslcert ||
      !this.config.data.gatekeeper_sslkey ) {
      delete this.config.data.gatekeeper_recreatecert;
      const cert = new Cert();
      console.log(chalk.bold.green( '☕ Generating gatekeeper cert. This may take a while ☕' ));
      try {
        const result = await cert.create(this.sessionData.cns);
        if ( result.code === 0 ) {
          this.config.data.gatekeeper_sslkey = result.key.toString();
          this.config.data.gatekeeper_sslcert = result.cert.toString();
        } else {
          console.log(chalk.bold.red( 'error! Gatekeeper cert was not created' ));
        }
      } catch ( err ) {
        console.log(chalk.bold.red( 'error! Gatekeeper cert was not created' ));
      }
    }
  }

  async createRandomKey( id, groups ) {
    if ( !id || !groups || !groups.length ) {
      return;
    }
    const apikey = new ApiKey();
    apikey.setId(id);
    apikey.setGroups(groups);
    await apikey.randomiseKey();
    return apikey;
  }

  async writeFiles() {

    console.log( chalk.green( '   create' )+' '+configArchiveFileName );
    if ( !this.config.serialize(
      this.destinationPath(configArchiveFileName),
      this.sessionData.configurationPassword
    ) ) {
      console.log(chalk.bold.red( 'error! Config archive was not written' ));
    }

    const pathProps = [
      'admin_datapath',
      'gatekeeper_datapath',
      'logs_datapath',
      'traefik_datapath',
      'tor_datapath',
      'proxy_datapath',
      'bitcoin_datapath',
      'lightning_datapath',
      'otsclient_datapath'
    ];

    for ( let pathProp of pathProps ) {
      if ( this.config.data[pathProp] === '_custom' ) {
        this.config.data[pathProp] = this.config.data[pathProp+'_custom'] || '';
      }
    }

    this.sessionData.installationInfo = this.installationInfo();

    for ( let m of prompters ) {
      const name = m.name();
      for ( let t of m.templates(this.config.data) ) {
        const p = path.join(name, t);
        const destFile = this.destinationPath( path.join( destinationDirName, p ) );
        const targetDir = path.dirname( destFile );

        if ( !fs.existsSync(targetDir) ) {
          fs.mkdirSync(targetDir, {
            recursive: true
          });
        }
        const result = await ejsRenderFileAsync( this.templatePath(p), Object.assign({
        }, this.sessionData, this.config.data), {
        } );

        console.log( chalk.green( '   create' )+' '+p );
        fs.writeFileSync( destFile, result );

      }
    }

    console.log( chalk.green( '   create' )+' '+keyArchiveFileName );

    if ( this.config.data.gatekeeper_keys && this.config.data.gatekeeper_keys.clientInformation ) {

      if ( this.sessionData.gatekeeper_clientkeyspassword !== this.config.data.gatekeeper_clientkeyspassword &&
        fs.existsSync(this.destinationPath(keyArchiveFileName)) ) {
        fs.unlinkSync( this.destinationPath(keyArchiveFileName) );
      }

      const archive = new Archive( this.destinationPath(keyArchiveFileName), this.config.data.gatekeeper_clientkeyspassword );
      if ( !await archive.writeEntry( 'keys.txt', this.config.data.gatekeeper_keys.clientInformation.join('\n') ) ) {
        console.log(chalk.bold.red( 'error! Client gatekeeper key archive was not written' ));
      }
      if ( !await archive.writeEntry( 'cacert.pem', this.config.data.gatekeeper_sslcert ) ) {
        console.log(chalk.bold.red( 'error! Client gatekeeper key archive was not written' ));
      }
    }

    fs.writeFileSync(path.join(this.workDir(), destinationDirName, 'exitStatus.sh'), 'EXIT_STATUS=0');

  }

  installationInfo() {

    for ( let feature of this.features ) {
      feature.checked = this.isChecked( 'features', feature.value );
    }

    for ( let torifyable of this.torifyables ) {
      torifyable.checked = this.isChecked('features', 'tor') && this.isChecked( 'torifyables', torifyable.value );
    }

    const cert = new Cert();
    const gatekeeper_cns = cert.cns( this.config.data.gatekeeper_cns );

    const features = [
      {
        active: true,
        name: 'Bitcoin core node',
        label: 'bitcoin',
        host: 'bitcoin',
        networks: ['cyphernodenet'],
        docker: 'cyphernode/bitcoin:'+this.config.docker_versions['cyphernode/bitcoin'],
        extra: {
          prune: this.config.data.bitcoin_prune,
          prune_size: this.config.data.bitcoin_prune_size,
          expose: this.config.data.bitcoin_expose,
          uacomment: this.config.data.bitcoin_uacomment,
          torified: this.torifyables.find(data => data.value === 'tor_bitcoin').checked,
          clearnet: !this.isChecked('features', 'tor') || this.isChecked('clearnet', 'clearnet_bitcoin'),
          tor_hostname: this.sessionData.tor_bitcoin_hostname
        }
      },
      {
        active: true,
        name: 'Gatekeeper',
        label: 'gatekeeper',
        host: 'gatekeeper',
        networks: ['cyphernodenet', 'cyphernodeappsnet'],
        docker: 'traefik:'+this.config.docker_versions['traefik'],
        extra: {
          port: this.config.data.gatekeeper_port,
          cns: gatekeeper_cns
        }
      },
      {
        active: true,
        name: 'Proxy',
        label: 'proxy',
        host: 'proxy',
        networks: ['cyphernodenet'],
        docker: 'cyphernode/proxy:'+this.config.docker_versions['cyphernode/proxy'],
        extra: {
          torified_addr_watch_webhooks: this.torifyables.find(data => data.value === 'tor_addrwatcheswebhooks').checked,
          torified_txid_watch_webhooks: this.torifyables.find(data => data.value === 'tor_txidwatcheswebhooks').checked,
          torified_ots_watch_webhooks: this.torifyables.find(data => data.value === 'tor_otswebhooks').checked
        }
      },
      {
        active: true,
        name: 'Proxy cron',
        label: 'proxycron',
        host: 'proxycron',
        networks: ['cyphernodenet'],
        docker: 'cyphernode/proxycron:'+this.config.docker_versions['cyphernode/proxycron']
      },
      {
        active: true,
        name: 'Pycoin',
        label: 'pycoin',
        host: 'pycoin',
        networks: ['cyphernodenet'],
        docker: 'cyphernode/pycoin:'+this.config.docker_versions['cyphernode/pycoin']
      },
      {
        active: true,
        name: 'Notifier',
        label: 'notifier',
        host: 'notifier',
        networks: ['cyphernodenet', 'cyphernodeappsnet'],
        docker: 'cyphernode/notifier:'+this.config.docker_versions['cyphernode/notifier']
      },
      {
        active: true,
        name: 'MQ broker',
        label: 'broker',
        host: 'broker',
        networks: ['cyphernodenet', 'cyphernodeappsnet'],
        docker: 'eclipse-mosquitto:'+this.config.docker_versions['eclipse-mosquitto']
      },
      {
        active: true,
        name: 'Traefik',
        label: 'traefik',
        host: 'traefik',
        networks: ['cyphernodeappsnet'],
        docker: 'traefik:'+this.config.docker_versions['traefik'],
        extra: {
          tor_hostname: this.sessionData.tor_traefik_hostname,
        }
      }

    ];

    const optional_features = [];

    const optional_features_data = {
      tor: {
        networks: ['cyphernodenet', 'cyphernodeappsnet'],
        docker: 'cyphernode/tor:' + this.config.docker_versions['cyphernode/tor'],
        extra: {
          traefik_hostname: this.sessionData.tor_traefik_hostname,
          lightning_hostname: this.sessionData.tor_lightning_hostname,
          bitcoin_hostname: this.sessionData.tor_bitcoin_hostname,
        }
      },
      otsclient: {
        networks: ['cyphernodenet'],
        docker: 'cyphernode/otsclient:' + this.config.docker_versions['cyphernode/otsclient'],
        extra: {
          torified: this.torifyables.find(data => data.value === 'tor_otsoperations').checked,
          torified_webhooks: this.torifyables.find(data => data.value === 'tor_otswebhooks').checked
        }
      },
      batcher: {
        networks: ['cyphernodeappsnet'],
        docker: "cyphernode/batcher"
      },
      specter: {
        networks: ['cyphernodeappsnet'],
        docker: "cyphernode/specter"
      },
      lightning: {
        networks: ['cyphernodenet'],
        docker: 'cyphernode/clightning:'+this.config.docker_versions['cyphernode/clightning'],
        extra: {
          nodename: this.config.data.lightning_nodename,
          nodecolor: this.config.data.lightning_nodecolor,
          expose: this.config.data.lightning_expose,
          external_ip: this.config.data.lightning_external_ip,
          implementation: this.config.data.lightning_implementation,
          torified: this.torifyables.find(data => data.value === 'tor_lightning').checked,
          clearnet: !this.isChecked('features', 'tor') || this.isChecked('clearnet', 'clearnet_lightning'),
          tor_hostname: this.sessionData.tor_lightning_hostname
        }
      }
    };

    for ( let feature of this.features ) {
      const f = {
        active: feature.checked,
        name: feature.name,
        label: feature.value,
        host: feature.value,
        networks: optional_features_data[feature.value].networks,
        docker: optional_features_data[feature.value].docker
      };

      if ( feature.checked ) {
        f.extra = optional_features_data[feature.value].extra;
      }

      optional_features.push( f );
    }

    let bitcoin_version = this.config.docker_versions['cyphernode/bitcoin'];

    if ( bitcoin_version[0] === 'v' ) {
      bitcoin_version = bitcoin_version.substr(1);
    }

    const ii = {
      api_versions: ['v0'],
      setup_version: this.config.setup_version,
      bitcoin_version: bitcoin_version,
      features: features,
      optional_features: optional_features,
      docker_mode: this.config.data.docker_mode,
      devmode: this.sessionData.devmode,

    };

    return ii;
  }

  async prompt( questions ) {
    if ( !questions ) {
      return {
      };
    }

    const r = await inquirer.prompt( questions );
    return r;
  }

  /* some utils */

  destinationPath( relPath ) {
    return path.join( this.workDir(), relPath );
  }

  templatePath( relPath ) {
    return path.join(__dirname, '..', 'templates', relPath );
  }

  isChecked(name, value ) {
    return this.config.data && this.config.data[name] && this.config.data[name].indexOf(value) !== -1 ;
  }

  getDefault(name) {

    if ( this.config && this.config.data && this.config.data.hasOwnProperty(name) ) {
      return this.config.data[name];
    }

    if ( this.sessionData && this.sessionData.hasOwnProperty(name) ) {
      return this.sessionData[name];
    }

  }

  optional(input, validator) {
    if ( input === undefined ||
      input === null ||
      input === '' ) {
      return true;
    }
    return validator(input);
  }

  ipOrFQDNValidator(host ) {
    host = (host+'').trim();
    if ( !(validator.isIP(host) ||
      validator.isFQDN(host)) ) {
      throw new Error( 'No IP address or fully qualified domain name' );
    }
    return true;
  }

  xkeyValidator(xpub ) {
    // TOOD: check for version
    if ( !coinstring.isValid( xpub ) ) {
      throw new Error('Not an extended key.');
    }
    return true;
  }

  pathValidator() {
    return true;
  }

  derivationPathValidator() {
    return true;
  }

  colorValidator(color) {
    if ( !validator.isHexadecimal(color) ) {
      throw new Error('Not a hex color.');
    }
    return true;
  }

  lightningNodeNameValidator(name) {
    if ( !name || name.length > 32 ) {
      throw new Error('Please enter anything shorter than 32 characters');
    }
    return true;
  }

  notEmptyValidator(path ) {
    if ( !path ) {
      throw new Error('Please enter something');
    }
    return true;
  }

  usernameValidator(user ) {
    if ( !userRegexp.test( user ) ) {
      throw new Error('Choose a valid username');
    }
    return true;
  }

  UACommentValidator(comment ) {
    if ( !uaCommentRegexp.test( comment ) ) {
      throw new Error('Unsafe characters in UA comment. Please use only a-z, A-Z, 0-9, SPACE and .,:_?@');
    }
    return true;
  }

  trimFilter(input ) {
    return (input+'').trim();
  }

  featureChoices() {
    return this.features;
  }

  torifyableChoices() {
    return this.torifyables;
  }

  setupDir() {
    return this.sessionData.setupDir;
  }

  workDir() {
    return this.sessionData.workDir;
  }

  defaultDataDirBase() {
    return this.sessionData.defaultDataDirBase;
  }

  getHelp(topic ) {
    if ( !this.config.data.enablehelp || !this.help ) {
      return '';
    }

    const helpText = this.help[topic] || this.help['__default__'];

    if ( !helpText ||helpText === '' ) {
      return '';
    }

    return '\n\n'+wrap( html2ansi(helpText), maxWidth )+'\n\n';
  }

};
