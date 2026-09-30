// Release configuration for commit-and-tag-version.
// The application version lives in lib/trexbar.rb so a release does not
// need a hand-edited version constant.

const versionFile = {
  filename: 'lib/trexbar.rb',
  updater: {
    readVersion(contents) {
      const match = contents.match(/VERSION = "([^"]+)"/);
      return match ? match[1] : null;
    },
    writeVersion(contents, version) {
      return contents.replace(/(VERSION = ")[^"]+(")/, `$1${version}$2`);
    },
  },
};

module.exports = {
  packageFiles: [versionFile],
  bumpFiles: [versionFile],
  tagPrefix: 'v',
  releaseCommitMessageFormat: 'chore(release): {{currentTag}}',
  commitUrlFormat: 'https://github.com/blackopsrepl/trexbar-sway/commit/{{hash}}',
  compareUrlFormat: 'https://github.com/blackopsrepl/trexbar-sway/compare/{{previousTag}}...{{currentTag}}',
};
